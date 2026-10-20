import Foundation

public enum ResetCreditOutcome: String, Codable, Sendable {
    case reset, alreadyRedeemed, nothingToReset, noCredit
}

/// Revocation is synchronized with writing the irreversible RPC, not with its response.
public final class ResetCreditAuthorization: @unchecked Sendable {
    private let lock = NSLock()
    private var allowed = true
    public init() {}
    public func revoke() { lock.lock(); allowed = false; lock.unlock() }
    public func whileAllowed<T>(_ body: () throws -> T) throws -> T {
        lock.lock(); defer { lock.unlock() }
        guard allowed else { throw CancellationError() }
        return try body()
    }
}

public protocol ResetCreditServicing: Sendable {
    func read(account: String, token: CodexOAuthToken?) async throws -> CodexAppServerAccountSnapshot
    func consume(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit, idempotencyKey: String, authorization: ResetCreditAuthorization) async throws -> ResetCreditOutcome
}

public struct ResetCreditAutomationStatus: Sendable {
    public enum Status: String, Codable, Sendable {
        case off, waiting, pending, reset, alreadyRedeemed, nothingToReset, noCredit, expired, unavailable, verificationRequired, storageFailed
    }
    public let enabled: Bool
    public let status: Status
    public let updatedAt: Date?
    public init(enabled: Bool, status: Status, updatedAt: Date?) {
        self.enabled = enabled
        self.status = status
        self.updatedAt = updatedAt
    }
}

public struct ResetCreditSuccessNotice: Equatable, Sendable {
    public let id: String
    public let expiresAt: Date
    public init(id: String, expiresAt: Date) { self.id = id; self.expiresAt = expiresAt }
}

/// Separate opt-in state; never changes low-quota or recovery-reminder preferences.
public actor ResetCreditAutomation {
    private struct Attempt: Codable {
        var accountKey: String
        var creditID: String
        var expiresAt: Date
        var key: String
        var status: ResetCreditAutomationStatus.Status
        var updatedAt: Date
        var successNotificationPending: Bool? = nil
    }
    private struct State: Codable {
        var enabledAccountKey: String?
        var attempts: [Attempt] = []
    }
    private let fileURL: URL
    private var running = false
    private var revision = 0
    private var activeAuthorization: ResetCreditAuthorization?
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func status(account: String?) -> ResetCreditAutomationStatus {
        guard let key = QuotaHistorySample.key(for: account), let state = try? load() else {
            return ResetCreditAutomationStatus(enabled: false, status: .off, updatedAt: nil)
        }
        let enabled = state.enabledAccountKey == key
        let attempt = state.attempts.last { $0.accountKey == key }
        return ResetCreditAutomationStatus(enabled: enabled, status: enabled ? (attempt?.status ?? .waiting) : .off, updatedAt: attempt?.updatedAt)
    }

    public func pendingSuccessNotices(account: String) -> [ResetCreditSuccessNotice] {
        guard let owner = QuotaHistorySample.key(for: account), let state = try? load() else { return [] }
        return state.attempts.filter {
            $0.accountKey == owner && $0.successNotificationPending == true
                && ($0.status == .reset || $0.status == .alreadyRedeemed)
        }.map { ResetCreditSuccessNotice(id: $0.key, expiresAt: $0.expiresAt) }
    }

    @discardableResult
    public func acknowledgeSuccessNotice(_ id: String, account: String) -> Bool {
        guard let owner = QuotaHistorySample.key(for: account), var state = try? load(),
              let index = state.attempts.firstIndex(where: { $0.accountKey == owner && $0.key == id }) else { return false }
        state.attempts[index].successNotificationPending = false
        return (try? save(state)) != nil
    }

    @discardableResult
    public func setEnabled(_ enabled: Bool, account: String?) -> Bool {
        guard let key = QuotaHistorySample.key(for: account), var state = try? load() else { return false }
        activeAuthorization?.revoke()
        revision += 1
        state.enabledAccountKey = enabled ? key : nil
        return (try? save(state)) != nil
    }

    public func tick(account: String, token: CodexOAuthToken?, client: any ResetCreditServicing, now: Date) async -> ResetCreditAutomationStatus {
        guard !running, let owner = QuotaHistorySample.key(for: account),
              var state = try? load(), state.enabledAccountKey == owner else { return status(account: account) }
        running = true
        let authorization = ResetCreditAuthorization()
        activeAuthorization = authorization
        defer { running = false; activeAuthorization = nil }
        let activeRevision = revision
        func result(_ value: ResetCreditAutomationStatus.Status, _ date: Date? = nil) -> ResetCreditAutomationStatus {
            ResetCreditAutomationStatus(enabled: true, status: value, updatedAt: date)
        }
        let snapshot: CodexAppServerAccountSnapshot
        do { snapshot = try await client.read(account: account, token: token) }
        catch { return result(.unavailable) }
        guard activeRevision == revision, let latest = try? load(), latest.enabledAccountKey == owner else { return status(account: account) }
        state = latest
        guard snapshot.accountID == account, snapshot.resetCreditDetailsAvailable else { return result(.unavailable) }
        if state.attempts.contains(where: { $0.accountKey == owner && $0.status == .verificationRequired && $0.expiresAt > now }) {
            return result(.verificationRequired)
        }
        let pending = state.attempts.lastIndex { $0.accountKey == owner && ($0.status == .pending || $0.status == .nothingToReset) }
        let index: Int
        if let pending {
            index = pending
            if state.attempts[index].expiresAt <= now || !snapshot.resetCredits.contains(where: {
                $0.id == state.attempts[index].creditID && $0.status == "available" && $0.expiresAt == state.attempts[index].expiresAt
            }) {
                let terminal: ResetCreditAutomationStatus.Status = state.attempts[index].status == .nothingToReset
                    ? (state.attempts[index].expiresAt <= now ? .expired : .noCredit) : .verificationRequired
                state.attempts[index].status = terminal
                state.attempts[index].updatedAt = now
                guard (try? save(state)) != nil else { return result(.storageFailed) }
                return result(terminal, now)
            }
        } else {
            let cards = snapshot.resetCredits.filter {
                guard let id = $0.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      $0.status == "available", $0.resetType == "codexRateLimits", let expiry = $0.expiresAt, expiry.timeIntervalSince1970.isFinite,
                      expiry > now, expiry.timeIntervalSince(now) <= 3600 else { return false }
                return snapshot.resetCredits.filter { $0.id == id }.count == 1
                    && !state.attempts.contains { $0.accountKey == owner && $0.creditID == id }
            }.sorted { $0.expiresAt! < $1.expiresAt! }
            guard let card = cards.first else { return status(account: account) }
            state.attempts.append(Attempt(accountKey: owner, creditID: card.id!, expiresAt: card.expiresAt!, key: UUID().uuidString, status: .pending, updatedAt: now))
            index = state.attempts.count - 1
            // Persist the exact card and retry identity before any irreversible request.
            guard (try? save(state)) != nil else { return result(.storageFailed) }
        }
        let attempt = state.attempts[index]
        guard let card = snapshot.resetCredits.first(where: { $0.id == attempt.creditID }) else { return result(.verificationRequired) }
        let outcome: ResetCreditOutcome
        do { outcome = try await client.consume(account: account, token: token, credit: card, idempotencyKey: attempt.key, authorization: authorization) }
        catch { return result(.pending, attempt.updatedAt) }
        // Preserve a toggle change made while the already-sent request was in flight.
        guard var completed = try? load(), let position = completed.attempts.firstIndex(where: { $0.key == attempt.key }) else { return result(.storageFailed) }
        completed.attempts[position].status = ResetCreditAutomationStatus.Status(rawValue: outcome.rawValue)!
        completed.attempts[position].updatedAt = now
        completed.attempts[position].successNotificationPending = outcome == .reset || outcome == .alreadyRedeemed
        guard (try? save(completed)) != nil else { return result(.storageFailed) }
        return status(account: account)
    }

    private func load() throws -> State {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return State() }
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular else { throw CocoaError(.fileReadUnknown) }
        return try JSONDecoder().decode(State.self, from: Data(contentsOf: fileURL))
    }
    private func save(_ state: State) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(state).write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}

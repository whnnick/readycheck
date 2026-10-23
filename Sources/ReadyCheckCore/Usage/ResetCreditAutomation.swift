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
        case off, waiting, pending, reset, alreadyRedeemed, nothingToReset, noCredit, expired, unavailable, verificationRequired, storageFailed, observing, disappeared, missed, redeemedElsewhere, unrecorded
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
        var startedAt: Date? = nil
        var requestCount: Int? = nil
    }
    private struct ObservedCard: Codable {
        var accountKey: String
        var creditID: String
        var expiresAt: Date
        var updatedAt: Date
        var status: ResetCreditAutomationStatus.Status
    }
    private struct State: Codable {
        var enabledAccountKey: String?
        var attempts: [Attempt] = []
        var observedCards: [ObservedCard]? = nil
    }
    private let fileURL: URL
    private let ledger: ResetCreditLedgerFile
    private let checkLedger: ResetCreditLedgerFile
    private var running = false
    private var revision = 0
    private var activeAuthorization: ResetCreditAuthorization?
    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.ledger = ResetCreditLedgerFile(url: fileURL)
        self.checkLedger = ResetCreditLedgerFile(url: fileURL.appendingPathExtension("checks.json"), protection: nil)
    }

    public func status(account: String?) -> ResetCreditAutomationStatus {
        guard let key = QuotaHistorySample.key(for: account) else {
            return ResetCreditAutomationStatus(enabled: false, status: .off, updatedAt: nil)
        }
        guard let state = try? load() else {
            return ResetCreditAutomationStatus(enabled: false, status: .storageFailed, updatedAt: nil)
        }
        let enabled = state.enabledAccountKey == key
        let attempt = state.attempts.last { $0.accountKey == key }
        return ResetCreditAutomationStatus(enabled: enabled, status: enabled ? (attempt?.status ?? .waiting) : .off, updatedAt: attempt?.updatedAt)
    }

    public func records(account: String?) throws -> [ResetCreditExecutionRecord] {
        guard let owner = QuotaHistorySample.key(for: account) else { return [] }
        let state = try load()
        let attempts = state.attempts.filter { $0.accountKey == owner }
        let results = attempts.map {
            ResetCreditExecutionRecord(id: $0.key, expiresAt: $0.expiresAt, status: $0.status,
                updatedAt: $0.updatedAt, successNotificationPending: $0.successNotificationPending,
                startedAt: $0.startedAt, requestCount: $0.requestCount)
        }
        let observations = (state.observedCards ?? []).filter { card in
            card.accountKey == owner && !attempts.contains { $0.creditID == card.creditID }
        }.map { ResetCreditExecutionRecord(id: "observed:" + $0.creditID, expiresAt: $0.expiresAt,
            status: $0.status, updatedAt: $0.updatedAt, successNotificationPending: nil, observedOnly: true) }
        return (results + observations).sorted { $0.updatedAt > $1.updatedAt }
    }

    public func pendingSuccessNotices(account: String) -> [ResetCreditSuccessNotice] {
        guard let owner = QuotaHistorySample.key(for: account), let state = try? load() else { return [] }
        return state.attempts.filter {
            $0.accountKey == owner && $0.successNotificationPending == true
                && ($0.status == .reset || $0.status == .alreadyRedeemed)
        }.map { ResetCreditSuccessNotice(id: $0.key, expiresAt: $0.expiresAt) }
    }

    public func checks(account: String?) throws -> [ResetCreditCheckRecord] {
        guard let owner = QuotaHistorySample.key(for: account) else { return [] }
        return try loadChecks().filter { $0.accountKey == owner }.sorted { $0.lastAt > $1.lastAt }
    }

    @discardableResult
    public func recordCheck(_ reason: ResetCreditCheckRecord.Reason, account: String, now: Date = Date()) -> Bool {
        guard let owner = QuotaHistorySample.key(for: account), var rows = try? loadChecks() else { return false }
        if let index = rows.lastIndex(where: { $0.accountKey == owner }), rows[index].reason == reason {
            rows[index].lastAt = now; rows[index].count += 1
        } else {
            rows.append(ResetCreditCheckRecord(id: UUID().uuidString, accountKey: owner, reason: reason,
                firstAt: now, lastAt: now, count: 1, warningSubmitted: false))
        }
        return saveChecks(Array(rows.sorted { $0.lastAt < $1.lastAt }.suffix(100)))
    }

    public func acknowledgeCheckWarning(_ id: String, account: String) -> Bool {
        guard let owner = QuotaHistorySample.key(for: account), var rows = try? loadChecks(),
              let index = rows.firstIndex(where: { $0.id == id && $0.accountKey == owner }) else { return false }
        rows[index].warningSubmitted = true
        return saveChecks(rows)
    }

    private func loadChecks() throws -> [ResetCreditCheckRecord] {
        guard let data = try checkLedger.read() else { return [] }
        return try JSONDecoder().decode([ResetCreditCheckRecord].self, from: data)
    }
    private func saveChecks(_ rows: [ResetCreditCheckRecord]) -> Bool {
        do { try checkLedger.write(JSONEncoder().encode(rows)); return true }
        catch { return false }
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
        guard !running, let owner = QuotaHistorySample.key(for: account) else { return status(account: account) }
        guard var state = try? load() else {
            recordCheck(.ledgerUnavailable, account: account, now: now)
            return status(account: account)
        }
        guard state.enabledAccountKey == owner else { return status(account: account) }
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
        catch { recordCheck(.serviceUnavailable, account: account, now: now); return result(.unavailable) }
        guard activeRevision == revision, let latest = try? load(), latest.enabledAccountKey == owner else { return status(account: account) }
        state = latest
        guard snapshot.accountID == account, snapshot.resetCreditDetailsAvailable else {
            recordCheck(.serviceUnavailable, account: account, now: now); return result(.unavailable)
        }
        var observed = state.observedCards ?? []
        for index in observed.indices where observed[index].accountKey == owner {
            let card = observed[index]
            guard !state.attempts.contains(where: { $0.accountKey == owner && $0.creditID == card.creditID }) else { continue }
            let matches = snapshot.resetCredits.filter { $0.id == card.creditID && $0.expiresAt == card.expiresAt }
            if matches.isEmpty && (card.status == .redeemedElsewhere || card.status == .expired) { continue }
            let newStatus: ResetCreditAutomationStatus.Status
            if matches.count == 1, matches[0].status == "consumed" {
                newStatus = .redeemedElsewhere
            } else if matches.count == 1, matches[0].status == "expired" {
                newStatus = .expired
            } else if matches.count == 1, matches[0].status == "available" {
                newStatus = card.expiresAt <= now ? .missed : .observing
            } else {
                // Missing is not a server receipt for either redemption or expiration.
                newStatus = .disappeared
            }
            if observed[index].status != newStatus { observed[index].status = newStatus; observed[index].updatedAt = now }
        }
        for card in snapshot.resetCredits where card.status == "available" && card.resetType == "codexRateLimits" {
            guard let id = card.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let expiry = card.expiresAt, expiry.timeIntervalSince1970.isFinite,
                  snapshot.resetCredits.filter({ $0.id == id }).count == 1,
                  !observed.contains(where: { $0.accountKey == owner && $0.creditID == id }) else { continue }
            observed.append(ObservedCard(accountKey: owner, creditID: id, expiresAt: expiry, updatedAt: now,
                status: expiry > now ? .observing : .missed))
        }
        state.observedCards = observed
        guard (try? save(state)) != nil else { recordCheck(.writeFailed, account: account, now: now); return result(.storageFailed) }
        let observationProblem: ResetCreditCheckRecord.Reason? = observed.contains { $0.accountKey == owner && $0.status == .disappeared } ? .cardChanged
            : observed.contains { $0.accountKey == owner && $0.status == .missed } ? .windowMissed : nil
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
                guard (try? save(state)) != nil else { recordCheck(.writeFailed, account: account, now: now); return result(.storageFailed) }
                return result(terminal, now)
            }
        } else {
            let cards = snapshot.resetCredits.filter {
                guard let id = $0.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      $0.status == "available", $0.resetType == "codexRateLimits", let expiry = $0.expiresAt, expiry.timeIntervalSince1970.isFinite,
                      expiry > now, expiry.timeIntervalSince(now) <= 3600 else { return false }
                return snapshot.resetCredits.filter { $0.id == id }.count == 1
                    && !state.attempts.contains { $0.accountKey == owner && $0.creditID == id }
                    && !observed.contains { $0.accountKey == owner && $0.creditID == id
                        && ($0.status == .redeemedElsewhere || $0.status == .expired || $0.expiresAt != expiry) }
            }.sorted { $0.expiresAt! < $1.expiresAt! }
            guard let card = cards.first else { recordCheck(observationProblem ?? .checked, account: account, now: now); return status(account: account) }
            state.attempts.append(Attempt(accountKey: owner, creditID: card.id!, expiresAt: card.expiresAt!, key: UUID().uuidString, status: .pending, updatedAt: now, startedAt: now, requestCount: 0))
            index = state.attempts.count - 1
            // Persist the exact card and retry identity before any irreversible request.
            guard (try? save(state)) != nil else { recordCheck(.writeFailed, account: account, now: now); return result(.storageFailed) }
        }
        state.attempts[index].requestCount = (state.attempts[index].requestCount ?? 0) + 1
        state.attempts[index].updatedAt = now
        guard (try? save(state)) != nil else { recordCheck(.writeFailed, account: account, now: now); return result(.storageFailed) }
        let attempt = state.attempts[index]
        guard let card = snapshot.resetCredits.first(where: { $0.id == attempt.creditID }) else { return result(.verificationRequired) }
        let outcome: ResetCreditOutcome
        do { outcome = try await client.consume(account: account, token: token, credit: card, idempotencyKey: attempt.key, authorization: authorization) }
        catch { recordCheck(.resultUnconfirmed, account: account, now: now); return result(.pending, attempt.updatedAt) }
        // Preserve a toggle change made while the already-sent request was in flight.
        guard var completed = try? load(), let position = completed.attempts.firstIndex(where: { $0.key == attempt.key }) else {
            recordCheck(.writeFailed, account: account, now: now); return result(.storageFailed)
        }
        completed.attempts[position].status = ResetCreditAutomationStatus.Status(rawValue: outcome.rawValue)!
        completed.attempts[position].updatedAt = now
        completed.attempts[position].successNotificationPending = outcome == .reset || outcome == .alreadyRedeemed
        guard (try? save(completed)) != nil else { recordCheck(.writeFailed, account: account, now: now); return result(.storageFailed) }
        recordCheck(observationProblem ?? .checked, account: account, now: now)
        return status(account: account)
    }

    private func load() throws -> State {
        guard let data = try ledger.read() else { return State() }
        return try JSONDecoder().decode(State.self, from: data)
    }
    private func save(_ state: State) throws {
        try ledger.write(JSONEncoder().encode(state))
    }
}

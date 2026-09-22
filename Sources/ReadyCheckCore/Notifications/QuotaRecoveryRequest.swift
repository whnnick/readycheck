import Foundation

public struct QuotaRecoveryRequest: Codable, Equatable, Sendable {
    public let id: String
    public let account: String
    public let windowIDs: [String]
    public let observedAt: Date
    public var remainingByWindow: [String: Double]?

    public init(id: String = UUID().uuidString, account: String, snapshot: ProviderQuotaSnapshot) {
        self.id = id
        self.account = account
        windowIDs = snapshot.windows.map(\.id)
        observedAt = snapshot.refreshedAt
        remainingByWindow = Dictionary(uniqueKeysWithValues: snapshot.windows.compactMap { window in
            window.remainingRatio.map { (window.id, $0) }
        })
    }

    init(id: String, copying request: QuotaRecoveryRequest) {
        self.id = id
        account = request.account
        windowIDs = request.windowIDs
        observedAt = request.observedAt
        remainingByWindow = request.remainingByWindow
    }

    public static func canArm(_ snapshot: ProviderQuotaSnapshot, now: Date) -> Bool {
        isVerified(snapshot, now: now) && snapshot.windows.contains { ($0.remainingRatio ?? 1) < 1 }
    }

    public func isRecovered(_ snapshot: ProviderQuotaSnapshot, account: String?, now: Date) -> Bool {
        guard account == self.account, !self.account.isEmpty,
              Self.isVerified(snapshot, now: now), snapshot.refreshedAt > observedAt,
              !windowIDs.isEmpty, Set(windowIDs).isSubset(of: Set(snapshot.windows.map(\.id)))
        else { return false }
        return snapshot.windows.contains {
            guard let previous = remainingByWindow?[$0.id] else {
                return remainingByWindow == nil && ($0.remainingRatio ?? 0) > 0
            }
            return ($0.remainingRatio ?? 0) > previous + 0.000001
        }
    }

    public func hasConsumption(_ snapshot: ProviderQuotaSnapshot, account: String?, now: Date) -> Bool {
        guard account == self.account, Self.isVerified(snapshot, now: now),
              snapshot.refreshedAt > observedAt, let remainingByWindow
        else { return false }
        return snapshot.windows.contains { window in
            guard let previous = remainingByWindow[window.id], let current = window.remainingRatio else {
                return false
            }
            return current < previous - 0.000001
        }
    }

    private static func isVerified(_ snapshot: ProviderQuotaSnapshot, now: Date) -> Bool {
        snapshot.providerId == "codex-oauth"
            && (snapshot.source == .appServer || snapshot.source == .oauthAPI)
            && snapshot.status == .available && !snapshot.isStale(now: now)
            && snapshot.errors.isEmpty && !snapshot.windows.isEmpty
            && snapshot.windows.allSatisfy { $0.confidence == .verified && $0.remainingRatio != nil }
    }
}

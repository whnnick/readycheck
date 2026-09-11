import Foundation

public struct QuotaRecoveryRequest: Codable, Equatable, Sendable {
    public let id: String
    public let account: String
    public let windowIDs: [String]
    public let observedAt: Date

    public init(account: String, snapshot: ProviderQuotaSnapshot) {
        id = UUID().uuidString
        self.account = account
        windowIDs = snapshot.windows.map(\.id)
        observedAt = snapshot.refreshedAt
    }

    public static func canArm(_ snapshot: ProviderQuotaSnapshot, now: Date) -> Bool {
        isVerified(snapshot, now: now) && snapshot.windows.contains { $0.remainingRatio == 0 }
    }

    public func isRecovered(_ snapshot: ProviderQuotaSnapshot, account: String?, now: Date) -> Bool {
        guard account == self.account, !self.account.isEmpty,
              Self.isVerified(snapshot, now: now), snapshot.refreshedAt > observedAt,
              !windowIDs.isEmpty, Set(windowIDs).isSubset(of: Set(snapshot.windows.map(\.id)))
        else { return false }
        return snapshot.windows.allSatisfy {
            ($0.remainingRatio ?? 0) > 0 && ($0.limitStateCode?.isEmpty != false)
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

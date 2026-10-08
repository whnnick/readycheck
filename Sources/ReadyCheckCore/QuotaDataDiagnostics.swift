import Foundation

public enum QuotaDataDiagnostics {
    public static func issueKeys(snapshot: ProviderQuotaSnapshot?, now: Date) -> [String] {
        guard let snapshot else { return ["dataStatus.noSnapshot"] }
        var keys: [String] = []
        if snapshot.status != .available {
            return ["dataStatus.unavailable"]
        } else if snapshot.isStale(now: now) {
            keys.append("dataStatus.stale")
        } else if !snapshot.windows.contains(where: { $0.confidence == .verified && $0.remainingRatio != nil }) {
            keys.append("dataStatus.noQuota")
        }
        if snapshot.ordinaryUsageAllowed == nil { keys.append("dataStatus.permissionMissing") }
        if snapshot.ordinaryUsageAllowed == false { keys.append("dataStatus.permissionBlocked") }
        if snapshot.details?.subscriptionRenewalAt == nil { keys.append("dataStatus.subscriptionMissing") }
        if let renewal = snapshot.details?.subscriptionRenewalAt, renewal <= now {
            keys.append("dataStatus.subscriptionHistorical")
        }
        return keys
    }
}

import Foundation

public struct LowQuotaAlert: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let windowID: String
    public let labelKey: String
    public let displayLabel: String?
    public let remainingPercent: Int
    public let threshold: Int
}

public struct LowQuotaWindowObservation: Codable, Equatable, Sendable {
    public let id: String
    public let resetAt: Date?
    public var ratio: Double
    public var observedAt: Date
    public var notified: Bool
    public var pending: Bool
}

public struct LowQuotaReminderState: Codable, Equatable, Sendable {
    public let account: String
    public var windows: [String: LowQuotaWindowObservation]
}

public enum LowQuotaReminderEvaluator {
    public static func evaluate(
        snapshot: ProviderQuotaSnapshot,
        now: Date,
        account: String?,
        threshold: Int,
        state previous: LowQuotaReminderState?
    ) -> (state: LowQuotaReminderState?, alerts: [LowQuotaAlert]) {
        guard [10, 20].contains(threshold) else { return (nil, []) }
        guard let account, !account.isEmpty,
              snapshot.providerId == "codex-oauth",
              snapshot.source == .appServer || snapshot.source == .oauthAPI,
              snapshot.status == .available, !snapshot.isStale(now: now) else {
            return (previous, [])
        }
        var state: LowQuotaReminderState
        if let previous, previous.account == account { state = previous }
        else { state = LowQuotaReminderState(account: account, windows: [:]) }
        var alerts: [LowQuotaAlert] = []
        let boundary = Double(threshold) / 100
        for window in snapshot.windows where window.confidence == .verified {
            guard let ratio = window.remainingRatio,
                  window.resetAt.map({ $0 > now }) ?? true else { continue }
            let old = state.windows[window.id]
            if let old, snapshot.refreshedAt <= old.observedAt { continue }
            let resetChanged: Bool
            if let oldReset = old?.resetAt, let newReset = window.resetAt {
                resetChanged = abs(oldReset.timeIntervalSince(newReset)) > 5
            } else {
                resetChanged = old?.resetAt != window.resetAt
            }
            let restoredWithoutResetDate = old.map {
                $0.resetAt == nil && window.resetAt == nil && $0.ratio <= boundary && ratio > boundary
            } ?? false
            guard var observation = old, !resetChanged, !restoredWithoutResetDate else {
                state.windows[window.id] = LowQuotaWindowObservation(
                    id: UUID().uuidString, resetAt: window.resetAt, ratio: ratio,
                    observedAt: snapshot.refreshedAt, notified: false, pending: false
                )
                continue
            }
            if !observation.notified && ratio <= boundary && (observation.ratio > boundary || observation.pending) {
                alerts.append(LowQuotaAlert(
                    id: observation.id, windowID: window.id, labelKey: window.labelKey,
                    displayLabel: window.displayLabel, remainingPercent: Int((ratio * 100).rounded()), threshold: threshold
                ))
                observation.notified = true
                observation.pending = false
            }
            if ratio > boundary { observation.pending = false }
            observation.ratio = ratio
            observation.observedAt = snapshot.refreshedAt
            state.windows[window.id] = observation
        }
        return (state, alerts)
    }
}

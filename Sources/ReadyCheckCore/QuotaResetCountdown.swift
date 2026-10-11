import Foundation

public enum QuotaResetCountdown: Equatable, Sendable {
    case unknown
    case waitingForRefresh
    case lessThanOneMinute
    case remaining(minutes: Int)

    public init(window: QuotaWindow, snapshot: ProviderQuotaSnapshot?, now: Date) {
        guard let snapshot, snapshot.status == .available,
              snapshot.source == .oauthAPI || snapshot.source == .appServer,
              !snapshot.isStale(now: now), window.confidence == .verified,
              let resetAt = window.resetAt else {
            self = .unknown
            return
        }
        let seconds = resetAt.timeIntervalSince(now)
        guard seconds.isFinite, seconds < Double(Int.max) else {
            self = .unknown
            return
        }
        if seconds <= 0 { self = .waitingForRefresh }
        else if seconds < 60 { self = .lessThanOneMinute }
        else { self = .remaining(minutes: Int(ceil(seconds / 60))) }
    }

    public func text(localization: LocalizationService) -> String {
        switch self {
        case .unknown: return localization.text("quota.resetUnknown")
        case .waitingForRefresh: return localization.text("quota.resetAwaitingRefresh")
        case .lessThanOneMinute: return localization.text("quota.resetWithinMinute")
        case .remaining(let minutes):
            let days = minutes / 1_440
            let hours = minutes % 1_440 / 60
            let remainder = minutes % 60
            var parts: [String] = []
            if days > 0 { parts.append("\(days)" + localization.text("quota.countdownDays")) }
            if hours > 0 { parts.append("\(hours)" + localization.text("quota.countdownHours")) }
            if remainder > 0 { parts.append("\(remainder)" + localization.text("quota.countdownMinutes")) }
            return localization.text("quota.resetsIn") + parts.joined(separator: " ")
        }
    }
}

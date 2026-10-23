import Foundation

/// Conditional extrapolation of a recent, contiguous, account-owned five-hour history.
/// This value never changes reminder state or controls work in another application.
public struct QuotaPace: Equatable, Sendable {
    public enum State: String, Sendable {
        case risk, safe, insufficientHistory, stale, unstable, idle, atThreshold, unavailable, usageBlocked
    }
    public enum Interruption: String, Sendable {
        case gap, cycleChanged, invalidRecord, quotaIncreased
    }
    public private(set) var observationCount: Int = 0
    public private(set) var interruption: Interruption?
    public private(set) var state: State = .unavailable
    public let thresholdPercent: Int
    public let reminderEnabled: Bool
    public private(set) var observedDuration: TimeInterval = 0
    public private(set) var ratePointsPerHour: Double?
    public private(set) var secondsToThreshold: TimeInterval?
    public private(set) var remainingAtReset: Double?
    public private(set) var resetAt: Date?

    public static func evaluate(snapshot: ProviderQuotaSnapshot?, samples: [QuotaHistorySample],
                                thresholdPercent: Int, now: Date) -> QuotaPace {
        var result = QuotaPace(thresholdPercent: thresholdPercent == 0 ? 10 : thresholdPercent,
                               reminderEnabled: thresholdPercent != 0)
        guard [0, 5, 10, 20].contains(thresholdPercent), let snapshot,
              snapshot.providerId == "codex-oauth", snapshot.status == .available,
              snapshot.source == .appServer || snapshot.source == .oauthAPI,
              let owner = QuotaHistorySample.key(for: snapshot.accountID) else { return result }
        guard !snapshot.isStale(now: now), snapshot.refreshedAt <= now,
              now.timeIntervalSince(snapshot.refreshedAt) <= 120 else {
            result.state = .stale
            return result
        }
        if snapshot.ordinaryUsageAllowed == false { result.state = .usageBlocked; return result }
        guard snapshot.ordinaryUsageAllowed == true else { return result }
        let windows = snapshot.windows.filter { $0.durationMinutes == 300 }
        guard windows.count == 1, let window = windows.first,
              window.unit == .percent, window.confidence == .verified, window.limitStateCode == nil,
              let remaining = window.remainingRatio,
              let reset = window.resetAt, reset > now,
              reset.timeIntervalSince(now) <= 18_005 else { return result }
        result.resetAt = reset
        if remaining <= Double(result.thresholdPercent) / 100 {
            result.state = .atThreshold
            return result
        }
        let start = max(now.addingTimeInterval(-3600), reset.addingTimeInterval(-18_000))
        var recent = samples.filter {
            $0.providerID == snapshot.providerId && $0.accountKey == owner && $0.recordedAt >= start
        }.sorted { $0.recordedAt < $1.recordedAt }
        guard !recent.contains(where: { $0.recordedAt > snapshot.refreshedAt }) else { return result }
        if let last = recent.last, last.recordedAt == snapshot.refreshedAt {
            guard let value = last.values.first(where: { $0.windowID == window.id }),
                  value.remainingRatio.isFinite, abs(value.remainingRatio - remaining) < 0.000_001 else { return result }
            guard let date = value.resetAt, abs(date.timeIntervalSince(reset)) <= 5 else {
                result.state = .insufficientHistory
                result.interruption = .cycleChanged
                return result
            }
        } else if let sample = QuotaHistorySample(snapshot: snapshot) {
            recent.append(sample)
        }
        result.state = .insufficientHistory
        struct Point { let date: Date; let ratio: Double }
        var contiguous: [Point] = []
        for sample in recent.reversed() {
            guard let value = sample.values.first(where: { $0.windowID == window.id }),
                  value.remainingRatio.isFinite, (0...1).contains(value.remainingRatio) else {
                result.interruption = .invalidRecord
                break
            }
            guard let date = value.resetAt, abs(date.timeIntervalSince(reset)) <= 5 else {
                result.interruption = .cycleChanged
                break
            }
            if let newer = contiguous.last {
                let gap = newer.date.timeIntervalSince(sample.recordedAt)
                guard gap > 0 else { result.interruption = .invalidRecord; break }
                guard gap <= 600 else { result.interruption = .gap; break }
                guard value.remainingRatio >= newer.ratio else { result.interruption = .quotaIncreased; break }
            }
            contiguous.append(Point(date: sample.recordedAt, ratio: value.remainingRatio))
        }
        result.observationCount = contiguous.count
        if let latest = contiguous.first, let earliest = contiguous.last {
            result.observedDuration = latest.date.timeIntervalSince(earliest.date)
        }
        guard contiguous.count >= 7, let latest = contiguous.first, let earliest = contiguous.last else { return result }
        let duration = result.observedDuration
        guard duration >= 1800 else { return result }
        let rate = (earliest.ratio - latest.ratio) * 100 / duration * 3600
        guard rate > 0.000_001 else { result.state = .idle; return result }
        let ordered = Array(contiguous.reversed())
        let midpoint = ordered.count / 2
        func rateBetween(_ first: Point, _ last: Point) -> Double {
            (first.ratio - last.ratio) * 100 / last.date.timeIntervalSince(first.date) * 3600
        }
        let firstRate = rateBetween(ordered[0], ordered[midpoint])
        let lastRate = rateBetween(ordered[midpoint], ordered[ordered.count - 1])
        guard max(firstRate, lastRate) <= max(min(firstRate, lastRate) * 3, 1) else {
            result.state = .unstable
            return result
        }
        let seconds = (remaining * 100 - Double(result.thresholdPercent)) / rate * 3600
        guard seconds.isFinite, seconds > 0 else { return result }
        result.ratePointsPerHour = rate
        result.secondsToThreshold = seconds
        result.remainingAtReset = max(0, remaining - rate / 100 * reset.timeIntervalSince(now) / 3600)
        result.state = seconds <= reset.timeIntervalSince(now) ? .risk : .safe
        return result
    }
}

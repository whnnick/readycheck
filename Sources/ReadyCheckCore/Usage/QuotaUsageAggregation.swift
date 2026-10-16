import Foundation

public struct QuotaUsageBucket: Identifiable, Equatable, Sendable {
    public let start: Date
    public let end: Date
    public let consumedRatio: Double

    public var id: TimeInterval { start.timeIntervalSince1970 }

    public init(start: Date, end: Date, consumedRatio: Double) {
        self.start = start
        self.end = end
        self.consumedRatio = consumedRatio
    }
}

public enum QuotaUsageAggregation {
    public static func observedDecreases(
        samples: [QuotaHistorySample], providerID: String, windowID: String,
        rangeStart: Date, rangeEnd: Date, maximumAttributableGap: TimeInterval = 600
    ) -> [(date: Date, consumedRatio: Double)] {
        let recent = samples.filter {
            $0.providerID == providerID && $0.recordedAt >= rangeStart && $0.recordedAt <= rangeEnd
        }.sorted { $0.recordedAt < $1.recordedAt }
        var previous: (date: Date, value: QuotaHistoryValue)?
        var decreases: [(date: Date, consumedRatio: Double)] = []
        for sample in recent {
            guard let value = sample.values.first(where: { $0.windowID == windowID }),
                  value.remainingRatio.isFinite, (0...1).contains(value.remainingRatio) else {
                previous = nil
                continue
            }
            defer { previous = (sample.recordedAt, value) }
            guard let previous else { continue }
            let gap = sample.recordedAt.timeIntervalSince(previous.date)
            guard gap > 0, gap <= maximumAttributableGap, value.resetAt == previous.value.resetAt else { continue }
            decreases.append((sample.recordedAt, max(0, previous.value.remainingRatio - value.remainingRatio)))
        }
        return decreases
    }

    public static func alignedRangeEnd(containing date: Date, bucketInterval: TimeInterval) -> Date {
        guard bucketInterval > 0 else { return date }
        let bucket = floor(date.timeIntervalSince1970 / bucketInterval) + 1
        return Date(timeIntervalSince1970: bucket * bucketInterval)
    }

    public static func chartMaximumPercent(for values: [Double]) -> Double {
        let highest = max(0, values.max() ?? 0)
        let headroom = max(1, highest * 0.15)
        return max(5, ceil((highest + headroom) / 5) * 5)
    }

    public static func observedBuckets(
        _ buckets: [QuotaUsageBucket],
        firstObservedAt: Date?
    ) -> [QuotaUsageBucket] {
        guard let firstObservedAt else { return [] }
        return buckets.filter { $0.end > firstObservedAt }
    }

    public static func buckets(
        samples: [QuotaHistorySample],
        providerID: String,
        windowID: String,
        rangeStart: Date,
        rangeEnd: Date,
        bucketInterval: TimeInterval,
        maximumAttributableGap: TimeInterval = 10 * 60
    ) -> [QuotaUsageBucket] {
        guard rangeEnd > rangeStart, bucketInterval > 0 else { return [] }

        let count = Int(ceil(rangeEnd.timeIntervalSince(rangeStart) / bucketInterval))
        guard count > 0 else { return [] }

        var values = Array(repeating: 0.0, count: count)
        for decrease in observedDecreases(samples: samples, providerID: providerID, windowID: windowID,
            rangeStart: rangeStart, rangeEnd: rangeEnd, maximumAttributableGap: maximumAttributableGap) {
            let index = min(count - 1, max(0, Int(decrease.date.timeIntervalSince(rangeStart) / bucketInterval)))
            values[index] += decrease.consumedRatio
        }

        return values.enumerated().map { index, consumedRatio in
            let start = rangeStart.addingTimeInterval(TimeInterval(index) * bucketInterval)
            return QuotaUsageBucket(
                start: start,
                end: min(start.addingTimeInterval(bucketInterval), rangeEnd),
                consumedRatio: consumedRatio
            )
        }
    }
}

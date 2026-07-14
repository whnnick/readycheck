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
        let points = samples
            .filter { $0.providerID == providerID }
            .compactMap { sample -> (date: Date, ratio: Double)? in
                guard let value = sample.values.first(where: { $0.windowID == windowID }) else { return nil }
                return (sample.recordedAt, value.remainingRatio)
            }
            .sorted { $0.date < $1.date }

        for (previous, current) in zip(points, points.dropFirst()) {
            let interval = current.date.timeIntervalSince(previous.date)
            guard interval > 0, interval <= maximumAttributableGap, current.date >= rangeStart, current.date <= rangeEnd else {
                continue
            }

            let consumed = max(0, previous.ratio - current.ratio)
            let index = min(count - 1, max(0, Int(current.date.timeIntervalSince(rangeStart) / bucketInterval)))
            values[index] += consumed
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

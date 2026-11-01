import Foundation

public struct DeepSeekConsumptionBucket: Identifiable, Equatable, Sendable {
    public let start: Date
    public let end: Date
    public let decrease: Decimal?
    public var id: Date { start }
}

public enum DeepSeekBalanceConsumption {
    /// Observed balance decreases, not billed cost. Nil means no attributable reading.
    public static func buckets(observations: [DeepSeekBalanceObservation], connectionID: UUID,
                               currency: String, range: ClosedRange<Date>,
                               interval: TimeInterval) -> [DeepSeekConsumptionBucket] {
        guard interval > 0, range.upperBound > range.lowerBound else { return [] }
        let count = Int(ceil(range.upperBound.timeIntervalSince(range.lowerBound) / interval))
        var values = [Decimal?](repeating: nil, count: count)
        let readings = observations.filter {
            $0.connectionID == connectionID && $0.currency == currency && $0.observedAt <= range.upperBound
        }.sorted { $0.observedAt < $1.observedAt }
        for (previous, current) in zip(readings, readings.dropFirst()) {
            let gap = current.observedAt.timeIntervalSince(previous.observedAt)
            guard range.contains(current.observedAt), gap > 0, gap <= 600,
                  current.total <= previous.total,
                  current.granted <= previous.granted,
                  current.toppedUp <= previous.toppedUp else { continue }
            let index = min(count - 1, Int(current.observedAt.timeIntervalSince(range.lowerBound) / interval))
            values[index] = (values[index] ?? 0) + previous.total - current.total
        }
        return values.enumerated().map { index, value in
            let start = range.lowerBound.addingTimeInterval(Double(index) * interval)
            return .init(start: start, end: min(start.addingTimeInterval(interval), range.upperBound), decrease: value)
        }
    }
}

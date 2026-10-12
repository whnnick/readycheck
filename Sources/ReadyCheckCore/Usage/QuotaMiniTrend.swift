import Foundation

public enum QuotaMiniTrend {
    /// Five-minute bins of observed decreases, not Token counts. Nil means unobserved.
    public static func values(samples: [QuotaHistorySample], providerID: String,
                              windowID: String, now: Date) -> [Double?] {
        let start = now.addingTimeInterval(-3600)
        var bins = [Double?](repeating: nil, count: 12)
        let recent = samples.filter {
            $0.providerID == providerID && $0.recordedAt >= start && $0.recordedAt <= now
        }.sorted { $0.recordedAt < $1.recordedAt }
        var previous: (date: Date, value: QuotaHistoryValue)?
        for sample in recent {
            guard let value = sample.values.first(where: { $0.windowID == windowID }),
                  value.remainingRatio.isFinite, (0...1).contains(value.remainingRatio) else {
                previous = nil
                continue
            }
            defer { previous = (sample.recordedAt, value) }
            guard let previous else { continue }
            let gap = sample.recordedAt.timeIntervalSince(previous.date)
            guard gap > 0, gap <= 600, value.resetAt == previous.value.resetAt else { continue }
            let index = min(11, Int(sample.recordedAt.timeIntervalSince(start) / 300))
            bins[index] = (bins[index] ?? 0) + max(0, previous.value.remainingRatio - value.remainingRatio)
        }
        return bins
    }
}

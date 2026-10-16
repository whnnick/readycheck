import Foundation

public enum QuotaMiniTrend {
    /// Five-minute bins of observed decreases, not Token counts. Nil means unobserved.
    public static func values(samples: [QuotaHistorySample], providerID: String,
                              windowID: String, now: Date) -> [Double?] {
        let start = now.addingTimeInterval(-3600)
        var bins = [Double?](repeating: nil, count: 12)
        for decrease in QuotaUsageAggregation.observedDecreases(samples: samples, providerID: providerID,
            windowID: windowID, rangeStart: start, rangeEnd: now) {
            let index = min(11, Int(decrease.date.timeIntervalSince(start) / 300))
            bins[index] = (bins[index] ?? 0) + decrease.consumedRatio
        }
        return bins
    }
}

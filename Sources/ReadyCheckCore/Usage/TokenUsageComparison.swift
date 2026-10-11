import Foundation

public struct TokenUsageComparison: Equatable, Sendable {
    public struct Period: Equatable, Sendable {
        public let total: Int64?
        public let observedDays: Int
        public let expectedDays: Int
        public let isOngoing: Bool
    }

    public let current: Period
    public let previous: Period

    public var changeRatio: Double? {
        guard let current = current.total, let previous = previous.total, previous > 0 else { return nil }
        return (Double(current) - Double(previous)) / Double(previous)
    }

    public static func today(buckets: [AccountTokenUsageDailyBucket], now: Date) -> Self {
        let values = validatedValues(buckets)
        return Self(
            current: period(keys: [todayKey(now: now)], values: values, ongoing: true),
            previous: period(keys: dayKeys(endingBefore: now, count: 1), values: values, ongoing: false)
        )
    }

    public static func week(buckets: [AccountTokenUsageDailyBucket], now: Date) -> Self {
        let keys = dayKeys(endingBefore: now, count: 14)
        let values = validatedValues(buckets)
        return Self(
            current: period(keys: Array(keys.prefix(7)), values: values, ongoing: false),
            previous: period(keys: Array(keys.suffix(7)), values: values, ongoing: false)
        )
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func todayKey(now: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        return String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }

    static func dayKeys(endingBefore now: Date, count: Int) -> [String] {
        (1...count).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: now).map { todayKey(now: $0) }
        }
    }

    private static func validatedValues(_ buckets: [AccountTokenUsageDailyBucket]) -> [String: Int64] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return Dictionary(grouping: buckets, by: \.startDate).reduce(into: [:]) { values, entry in
            guard entry.value.count == 1, let bucket = entry.value.first, bucket.tokens >= 0,
                  let date = formatter.date(from: entry.key), todayKey(now: date) == entry.key else { return }
            values[entry.key] = bucket.tokens
        }
    }

    private static func period(keys: [String], values: [String: Int64], ongoing: Bool) -> Period {
        let observed = keys.compactMap { values[$0] }
        var total: Int64? = observed.count == keys.count ? 0 : nil
        for value in observed {
            guard let amount = total else { break }
            let result = amount.addingReportingOverflow(value)
            total = result.overflow ? nil : result.partialValue
        }
        return Period(total: total, observedDays: observed.count, expectedDays: keys.count, isOngoing: ongoing)
    }
}

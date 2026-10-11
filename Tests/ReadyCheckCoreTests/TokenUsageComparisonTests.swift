import XCTest
@testable import ReadyCheckCore

final class TokenUsageComparisonTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_792_152_000)

    func testMissingDayIsNotZeroAndExplicitZeroHasNoPercentageBaseline() {
        let missing = TokenUsageComparison.today(buckets: [], now: now)
        XCTAssertNil(missing.current.total)
        XCTAssertNil(missing.changeRatio)
        let dates = TokenUsageComparison.dayKeys(endingBefore: now, count: 1)
        let today = TokenUsageComparison.todayKey(now: now)
        let value = TokenUsageComparison.today(buckets: [
            .init(startDate: today, tokens: 20), .init(startDate: dates[0], tokens: 0)
        ], now: now)
        XCTAssertEqual(value.current.total, 20)
        XCTAssertEqual(value.previous.total, 0)
        XCTAssertNil(value.changeRatio)
        XCTAssertTrue(value.current.isOngoing)
    }

    func testSevenDaysExcludeTodayAndRequireEveryDateInBothPeriods() {
        let keys = TokenUsageComparison.dayKeys(endingBefore: now, count: 14)
        let buckets = keys.enumerated().map { index, key in
            AccountTokenUsageDailyBucket(startDate: key, tokens: index < 7 ? 10 : 20)
        }
        let value = TokenUsageComparison.week(buckets: buckets + [.init(startDate: TokenUsageComparison.todayKey(now: now), tokens: 999)], now: now)
        XCTAssertEqual(value.current.total, 70)
        XCTAssertEqual(value.previous.total, 140)
        XCTAssertEqual(value.changeRatio, -0.5)
        XCTAssertFalse(value.current.isOngoing)
        let missing = TokenUsageComparison.week(buckets: Array(buckets.dropFirst()), now: now)
        XCTAssertEqual(missing.current.observedDays, 6)
        XCTAssertNil(missing.current.total)
        XCTAssertNil(missing.changeRatio)
    }

    func testMalformedNegativeDuplicateAndOverflowDataRemainUnknown() {
        let keys = TokenUsageComparison.dayKeys(endingBefore: now, count: 14)
        var buckets = keys.map { AccountTokenUsageDailyBucket(startDate: $0, tokens: 1) }
        buckets.append(.init(startDate: keys[0], tokens: 1))
        XCTAssertNil(TokenUsageComparison.week(buckets: buckets, now: now).current.total)
        buckets = keys.map { .init(startDate: $0, tokens: Int64.max) }
        XCTAssertNil(TokenUsageComparison.week(buckets: buckets, now: now).current.total)
        let today = TokenUsageComparison.todayKey(now: now)
        XCTAssertNil(TokenUsageComparison.today(buckets: [.init(startDate: today, tokens: -1), .init(startDate: "2026-02-30", tokens: 10)], now: now).current.total)
    }

    func testDateBoundariesUseOfficialUTCDateRegardlessOfLocalTimezone() {
        let instant = ISO8601DateFormatter().date(from: "2026-10-10T23:59:59Z")!
        XCTAssertEqual(TokenUsageComparison.todayKey(now: instant), "2026-10-10")
        XCTAssertEqual(TokenUsageComparison.todayKey(now: instant.addingTimeInterval(1)), "2026-10-11")
        XCTAssertEqual(TokenUsageComparison.dayKeys(endingBefore: instant, count: 2), ["2026-10-09", "2026-10-08"])
    }
}

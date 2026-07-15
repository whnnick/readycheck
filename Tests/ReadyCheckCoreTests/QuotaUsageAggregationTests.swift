import XCTest
@testable import ReadyCheckCore

final class QuotaUsageAggregationTests: XCTestCase {
    func testAlignedRangeEndKeepsBucketIDsStableUntilNextBoundary() {
        let interval: TimeInterval = 3_600
        let first = Date(timeIntervalSince1970: 10_100)
        let laterInSameBucket = Date(timeIntervalSince1970: 10_700)

        XCTAssertEqual(
            QuotaUsageAggregation.alignedRangeEnd(containing: first, bucketInterval: interval),
            QuotaUsageAggregation.alignedRangeEnd(containing: laterInSameBucket, bucketInterval: interval)
        )
        XCTAssertEqual(
            QuotaUsageAggregation.alignedRangeEnd(
                containing: Date(timeIntervalSince1970: 10_800),
                bucketInterval: interval
            ).timeIntervalSince1970,
            14_400
        )
    }

    func testChartMaximumAddsReadableHeadroom() {
        XCTAssertEqual(QuotaUsageAggregation.chartMaximumPercent(for: []), 5)
        XCTAssertEqual(QuotaUsageAggregation.chartMaximumPercent(for: [20]), 25)
        XCTAssertEqual(QuotaUsageAggregation.chartMaximumPercent(for: [25]), 30)
    }

    func testAttributesOnlyVerifiedDecreasesInsideMaximumGap() {
        let start = Date(timeIntervalSince1970: 10_000)
        let samples = [
            sample(at: start, remaining: 0.9),
            sample(at: start.addingTimeInterval(60), remaining: 0.7),
            sample(at: start.addingTimeInterval(120), remaining: 0.8),
            sample(at: start.addingTimeInterval(20 * 60), remaining: 0.5)
        ]

        let buckets = QuotaUsageAggregation.buckets(
            samples: samples,
            providerID: "codex-oauth",
            windowID: "codex-primary",
            rangeStart: start,
            rangeEnd: start.addingTimeInterval(30 * 60),
            bucketInterval: 10 * 60
        )

        XCTAssertEqual(buckets.count, 3)
        XCTAssertEqual(buckets[0].consumedRatio, 0.2, accuracy: 0.0001)
        XCTAssertEqual(buckets[1].consumedRatio, 0, accuracy: 0.0001)
        XCTAssertEqual(buckets[2].consumedRatio, 0, accuracy: 0.0001)
    }

    func testObservedBucketsStartAtFirstRecordedPeriod() {
        let start = Date(timeIntervalSince1970: 10_000)
        let buckets = (0..<3).map { index in
            QuotaUsageBucket(
                start: start.addingTimeInterval(TimeInterval(index) * 60),
                end: start.addingTimeInterval(TimeInterval(index + 1) * 60),
                consumedRatio: 0
            )
        }

        let visible = QuotaUsageAggregation.observedBuckets(
            buckets,
            firstObservedAt: start.addingTimeInterval(90)
        )

        XCTAssertEqual(visible.map(\.start), [buckets[1].start, buckets[2].start])
        XCTAssertTrue(QuotaUsageAggregation.observedBuckets(buckets, firstObservedAt: nil).isEmpty)
    }

    private func sample(at date: Date, remaining: Double) -> QuotaHistorySample {
        QuotaHistorySample(
            providerID: "codex-oauth",
            recordedAt: date,
            values: [
                QuotaHistoryValue(
                    windowID: "codex-primary",
                    labelKey: "quota.window.codex.5h",
                    remainingRatio: remaining,
                    resetAt: nil
                )
            ]
        )
    }
}

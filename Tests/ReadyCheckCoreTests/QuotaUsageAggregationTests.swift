import XCTest
@testable import ReadyCheckCore

final class QuotaUsageAggregationTests: XCTestCase {
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

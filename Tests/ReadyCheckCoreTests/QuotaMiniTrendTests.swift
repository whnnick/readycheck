import XCTest
@testable import ReadyCheckCore

final class QuotaMiniTrendTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 100_000)

    func testObservedDecreaseAndZeroAreDistinctFromMissingBins() {
        let values = QuotaMiniTrend.values(samples: [sample(-3000, 0.8), sample(-2940, 0.7),
            sample(-2400, 0.7)], providerID: "codex-oauth", windowID: "primary", now: now)
        XCTAssertEqual(values[2]!, 0.1, accuracy: 0.00001)
        XCTAssertEqual(values[4], 0)
        XCTAssertNil(values[0])
        XCTAssertNil(values[11])
    }

    func testResetRecoveryLongGapsAndMissingWindowCannotInventConsumption() {
        let reset = now.addingTimeInterval(3600)
        let changedReset = reset.addingTimeInterval(300)
        let points = [sample(-3000, 0.8, reset: reset), sample(-2940, 0.5, reset: changedReset),
            sample(-2880, 0.9, reset: changedReset), sample(-1200, 0.3, reset: changedReset),
            QuotaHistorySample(providerID: "codex-oauth", recordedAt: now.addingTimeInterval(-1140), values: []),
            sample(-1080, 0.1, reset: changedReset)]
        let values = QuotaMiniTrend.values(samples: points, providerID: "codex-oauth", windowID: "primary", now: now)
        XCTAssertEqual(values[2], 0)
        XCTAssertEqual(values.compactMap { $0 }.count, 1)
    }

    func testInvalidFutureOutOfRangeAndOtherProviderSamplesAreIgnored() {
        var points = [sample(-4000, 0.9), sample(-3600, 0.8), sample(-3540, .nan), sample(-3480, 0.6),
            sample(-3420, -0.1), sample(-3360, 0.4), sample(10, 0.2)]
        points.append(QuotaHistorySample(providerID: "other", recordedAt: now.addingTimeInterval(-3300),
            values: [QuotaHistoryValue(windowID: "primary", labelKey: "quota.window.codex.5h", remainingRatio: 0.1, resetAt: nil)]))
        XCTAssertTrue(QuotaMiniTrend.values(samples: points, providerID: "codex-oauth", windowID: "primary", now: now)
            .allSatisfy { $0 == nil })
    }

    private func sample(_ offset: TimeInterval, _ ratio: Double, reset: Date? = nil) -> QuotaHistorySample {
        QuotaHistorySample(providerID: "codex-oauth", recordedAt: now.addingTimeInterval(offset),
            values: [QuotaHistoryValue(windowID: "primary", labelKey: "quota.window.codex.5h", remainingRatio: ratio, resetAt: reset)])
    }
}

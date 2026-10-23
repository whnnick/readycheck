import XCTest
@testable import ReadyCheckCore

final class QuotaPaceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_900_000_000)
    private var reset: Date { now.addingTimeInterval(7200) }

    func testDiagnosticCoverageCountsOnlyTheContinuousSuffix() {
        let short = evaluate(points: Array(history().suffix(4)))
        XCTAssertEqual(short.state, .insufficientHistory)
        XCTAssertEqual(short.observationCount, 4)
        XCTAssertEqual(short.observedDuration, 900)
        XCTAssertNil(short.interruption)
        let gap = history().filter { $0.recordedAt < now.addingTimeInterval(-1600) || $0.recordedAt > now.addingTimeInterval(-500) }
        let interrupted = evaluate(points: gap)
        XCTAssertEqual(interrupted.interruption, .gap)
        XCTAssertEqual(interrupted.observationCount, 2)
        XCTAssertEqual(interrupted.observedDuration, 300)
        XCTAssertNil(interrupted.secondsToThreshold)
        let otherAccount = evaluate(points: history(account: "B"))
        XCTAssertEqual(otherAccount.observationCount, 1)
        XCTAssertEqual(otherAccount.observedDuration, 0)
        XCTAssertNil(otherAccount.interruption)
        XCTAssertEqual(evaluate(snapshot: snapshot(cached: true)).observationCount, 0)
    }

    func testDiagnosticCycleAndInvalidSamplesDoNotInventObservationCoverage() {
        let cycle = evaluate(snapshot: snapshot(reset: now.addingTimeInterval(17_999)))
        XCTAssertEqual(cycle.interruption, .cycleChanged)
        XCTAssertEqual(cycle.observationCount, 0)
        var invalid = history()
        invalid[invalid.count - 2] = sample(at: now.addingTimeInterval(-300), ratio: .nan)
        let broken = evaluate(points: invalid)
        XCTAssertEqual(broken.interruption, .invalidRecord)
        XCTAssertEqual(broken.observationCount, 1)
        XCTAssertEqual(broken.observedDuration, 0)
        invalid[invalid.count - 2] = sample(at: now.addingTimeInterval(-300), ratio: 0.2)
        XCTAssertEqual(evaluate(points: invalid).interruption, .quotaIncreased)
    }

    func testRiskAndSafeCompareThresholdWithReset() throws {
        let risk = evaluate()
        XCTAssertEqual(risk.state, .risk)
        XCTAssertEqual(try XCTUnwrap(risk.secondsToThreshold), 3600, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(risk.ratePointsPerHour), 24, accuracy: 0.001)
        let safe = evaluate(remaining: 0.54, rate: 0.12)
        XCTAssertEqual(safe.state, .safe)
        XCTAssertEqual(try XCTUnwrap(safe.remainingAtReset), 0.30, accuracy: 0.001)
    }

    func testThresholdOptionsAndOffDoNotEnableNotifications() throws {
        for threshold in [5, 10, 20] {
            let result = evaluate(threshold: threshold)
            XCTAssertEqual(result.thresholdPercent, threshold)
            XCTAssertTrue(result.reminderEnabled)
            XCTAssertEqual(try XCTUnwrap(result.secondsToThreshold), (34 - Double(threshold)) / 24 * 3600, accuracy: 0.001)
        }
        let off = evaluate(threshold: 0)
        XCTAssertFalse(off.reminderEnabled)
        XCTAssertEqual(off.thresholdPercent, 10)
        XCTAssertEqual(off.secondsToThreshold, evaluate(threshold: 10).secondsToThreshold)
    }

    func testCurrentLowReadingAndIdleDoNotInventTime() {
        XCTAssertEqual(evaluate(remaining: 0.08).state, .atThreshold)
        let idle = evaluate(remaining: 0.8, rate: 0)
        XCTAssertEqual(idle.state, .idle)
        XCTAssertNil(idle.secondsToThreshold)
    }

    func testInsufficientNewCycleAndLongGapSuppressEstimates() {
        XCTAssertEqual(evaluate(points: Array(history().suffix(6))).state, .insufficientHistory)
        let newReset = now.addingTimeInterval(17_999)
        XCTAssertEqual(evaluate(snapshot: snapshot(reset: newReset)).state, .insufficientHistory)
        let gap = history().filter { $0.recordedAt < now.addingTimeInterval(-1600) || $0.recordedAt > now.addingTimeInterval(-500) }
        XCTAssertEqual(evaluate(points: gap).state, .insufficientHistory)
    }

    func testOtherAccountsUnknownOwnersAndProviderDataCannotSupplyCoverage() {
        for points in [history(account: "B"), history(owner: nil), history(provider: "other")] {
            XCTAssertEqual(evaluate(points: points).state, .insufficientHistory)
        }
    }

    func testFreshnessAndCacheAndOrdinaryUsageAreRequired() {
        for date in [now.addingTimeInterval(-121), now.addingTimeInterval(1)] {
            XCTAssertEqual(evaluate(snapshot: snapshot(date: date)).state, .stale)
        }
        XCTAssertEqual(evaluate(snapshot: snapshot(cached: true)).state, .stale)
        XCTAssertEqual(evaluate(snapshot: snapshot(status: .unavailable)).state, .unavailable)
        XCTAssertEqual(evaluate(snapshot: snapshot(allowed: false)).state, .usageBlocked)
        XCTAssertEqual(evaluate(snapshot: snapshot(allowed: nil)).state, .unavailable)
        XCTAssertEqual(evaluate(snapshot: snapshot(source: .mock)).state, .unavailable)
        XCTAssertEqual(evaluate(snapshot: snapshot(account: nil)).state, .unavailable)
    }

    func testExplicitFiveHourIdentityResetAndVerifiedWindowAreRequired() {
        for window in [window(duration: 10080), window(unit: .tokens), window(reset: now), window(reset: nil), window(confidence: .estimated)] {
            XCTAssertEqual(evaluate(snapshot: snapshot(windows: [window])).state, .unavailable)
        }
        XCTAssertEqual(evaluate(snapshot: snapshot(windows: [window(), window(id: "ambiguous")])).state, .unavailable)
        XCTAssertEqual(evaluate(threshold: 7).state, .unavailable)
    }

    func testInvalidMissingIncreasedAndDuplicateRecentReadingsBreakContinuity() {
        for replacement in [Double.nan, .infinity, -0.1, 1.1, 0.2] {
            var points = history()
            let index = points.count - 2
            points[index] = sample(at: points[index].recordedAt, ratio: replacement)
            XCTAssertEqual(evaluate(points: points).state, .insufficientHistory)
        }
        var missing = history()
        missing[missing.count - 2] = QuotaHistorySample(providerID: "codex-oauth", recordedAt: now.addingTimeInterval(-300), values: [], accountKey: QuotaHistorySample.key(for: "A"))
        XCTAssertEqual(evaluate(points: missing).state, .insufficientHistory)
        var duplicate = history()
        duplicate.append(duplicate[duplicate.count - 2])
        XCTAssertEqual(evaluate(points: duplicate).state, .insufficientHistory)
    }

    func testUnevenConsumptionSuppressesPointEstimate() {
        let points: [QuotaHistorySample] = (0...12).map { index in
            let offset = Double(index - 12) * 300.0
            let drop = index < 6 ? Double(6 - index) * 0.005 + 0.18 : Double(12 - index) * 0.03
            return sample(at: now.addingTimeInterval(offset), ratio: 0.34 + drop)
        }
        XCTAssertEqual(evaluate(points: points).state, .unstable)
        XCTAssertNil(evaluate(points: points).secondsToThreshold)
    }

    func testShuffledHistoryIsSortedButNewerHistoryRejectsOlderSnapshot() {
        XCTAssertEqual(evaluate(points: history().reversed()).state, .risk)
        let newer = history() + [sample(at: now.addingTimeInterval(1), ratio: 0.33)]
        XCTAssertEqual(evaluate(points: newer).state, .unavailable)
    }

    private func evaluate(remaining: Double = 0.34, rate: Double = 0.24, threshold: Int = 10,
                          points: [QuotaHistorySample]? = nil, snapshot input: ProviderQuotaSnapshot? = nil) -> QuotaPace {
        QuotaPace.evaluate(snapshot: input ?? snapshot(remaining: remaining), samples: points ?? history(remaining: remaining, rate: rate), thresholdPercent: threshold, now: now)
    }
    private func history(remaining: Double = 0.34, rate: Double = 0.24, account: String = "A", owner: String? = "default", provider: String = "codex-oauth") -> [QuotaHistorySample] {
        (0...12).map { index in
            QuotaHistorySample(providerID: provider, recordedAt: now.addingTimeInterval(Double(index - 12) * 300), values: [QuotaHistoryValue(windowID: "short", labelKey: "quota.window.codex.5h", remainingRatio: remaining + rate * Double(12 - index) / 12, resetAt: reset)], accountKey: owner == nil ? nil : QuotaHistorySample.key(for: account))
        }
    }
    private func sample(at date: Date, ratio: Double) -> QuotaHistorySample {
        QuotaHistorySample(providerID: "codex-oauth", recordedAt: date, values: [QuotaHistoryValue(windowID: "short", labelKey: "quota.window.codex.5h", remainingRatio: ratio, resetAt: reset)], accountKey: QuotaHistorySample.key(for: "A"))
    }
    private func window(id: String = "short", duration: Int = 300, unit: QuotaUnit = .percent, reset date: Date? = Date(timeIntervalSince1970: 1_900_007_200), confidence: QuotaConfidence = .verified) -> QuotaWindow {
        QuotaWindow(id: id, labelKey: "quota.window.codex.5h", kind: .rolling, used: 66, limit: 100, remaining: 34, unit: unit, resetAt: date, confidence: confidence, durationMinutes: duration)
    }
    private func snapshot(remaining: Double = 0.34, date: Date? = nil, reset resetDate: Date? = nil, cached: Bool = false, status: ProviderStatus = .available, allowed: Bool? = true, source: ProviderSource = .appServer, account: String? = "A", windows: [QuotaWindow]? = nil) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: status, source: source,
            refreshedAt: date ?? now, staleAfter: (date ?? now).addingTimeInterval(300),
            windows: windows ?? [QuotaWindow(id: "short", labelKey: "quota.window.codex.5h", kind: .rolling, used: (1 - remaining) * 100, limit: 100, remaining: remaining * 100, unit: .percent, resetAt: resetDate ?? reset, confidence: .verified, durationMinutes: 300)],
            errors: [], ordinaryUsageAllowed: allowed, accountID: account, isCached: cached)
    }
}

import XCTest
@testable import ReadyCheckCore

final class QuotaModelsTests: XCTestCase {
    func testRemainingRatioUsesRemainingOverLimit() throws {
        let window = QuotaWindow(
            id: "codex-5h",
            labelKey: "quota.window.codex.5h",
            kind: .rolling,
            used: 28,
            limit: 100,
            remaining: 72,
            unit: .percent,
            resetAt: Date(timeIntervalSince1970: 1_800),
            confidence: .estimated
        )

        let remainingRatio = try XCTUnwrap(window.remainingRatio)
        XCTAssertEqual(remainingRatio, 0.72, accuracy: 0.0001)
    }

    func testInvalidWindowSuppressesRatioWhenLimitIsZero() {
        let window = QuotaWindow(
            id: "invalid",
            labelKey: "quota.window.invalid",
            kind: .rolling,
            used: 0,
            limit: 0,
            remaining: 0,
            unit: .unknown,
            resetAt: nil,
            confidence: .unknown
        )

        XCTAssertNil(window.remainingRatio)
    }

    func testInvalidWindowSuppressesRatioWhenRemainingExceedsLimit() {
        let window = makeWindow(limit: 100, remaining: 120)

        XCTAssertNil(window.remainingRatio)
        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testInvalidWindowSuppressesRatioWhenRemainingIsNegative() {
        let window = makeWindow(limit: 100, remaining: -1)

        XCTAssertNil(window.remainingRatio)
        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testInvalidWindowSuppressesRatioForNonFiniteValues() {
        let infiniteLimit = makeWindow(limit: .infinity, remaining: 50)
        let infiniteRemaining = makeWindow(limit: 100, remaining: .infinity)
        let nanLimit = makeWindow(limit: .nan, remaining: 50)
        let nanRemaining = makeWindow(limit: 100, remaining: .nan)

        XCTAssertNil(infiniteLimit.remainingRatio)
        XCTAssertNil(infiniteRemaining.remainingRatio)
        XCTAssertNil(nanLimit.remainingRatio)
        XCTAssertNil(nanRemaining.remainingRatio)
    }

    func testWindowSuppressesPercentageWhenConfidenceIsUnknown() {
        let window = makeWindow(limit: 100, remaining: 72, confidence: .unknown)

        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testWindowSuppressesPercentageWhenUsedIsNonFinite() {
        let window = makeWindow(limit: 100, remaining: 72, used: .infinity)

        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testWindowSuppressesPercentageWhenUsedIsNegative() {
        let window = makeWindow(limit: 100, remaining: 72, used: -1)

        XCTAssertNil(window.remainingRatio)
        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testWindowSuppressesPercentageWhenUsedExceedsLimit() {
        let window = makeWindow(limit: 100, remaining: 72, used: 101)

        XCTAssertNil(window.remainingRatio)
        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testWindowSuppressesPercentageWhenUsedAndRemainingDoNotMatchLimit() {
        let window = makeWindow(limit: 100, remaining: 72, used: 10)

        XCTAssertNil(window.remainingRatio)
        XCTAssertFalse(window.hasDisplayableRatioIgnoringSnapshotState)
    }

    func testQuotaModelRawValuesMatchStableWireNames() {
        XCTAssertEqual(ProviderStatus.available.rawValue, "available")
        XCTAssertEqual(ProviderStatus.estimated.rawValue, "estimated")
        XCTAssertEqual(ProviderStatus.unavailable.rawValue, "unavailable")
        XCTAssertEqual(ProviderStatus.error.rawValue, "error")

        XCTAssertEqual(ProviderSource.mock.rawValue, "mock")
        XCTAssertEqual(ProviderSource.local.rawValue, "local")
        XCTAssertEqual(ProviderSource.usageAPI.rawValue, "usage_api")
        XCTAssertEqual(ProviderSource.costAPI.rawValue, "cost_api")
        XCTAssertEqual(ProviderSource.oauthAPI.rawValue, "oauth_api")
        XCTAssertEqual(ProviderSource.manual.rawValue, "manual")

        XCTAssertEqual(QuotaWindowKind.rolling.rawValue, "rolling")
        XCTAssertEqual(QuotaWindowKind.calendar.rawValue, "calendar")
        XCTAssertEqual(QuotaWindowKind.billing.rawValue, "billing")
        XCTAssertEqual(QuotaWindowKind.rateLimit.rawValue, "rate_limit")
        XCTAssertEqual(QuotaWindowKind.manual.rawValue, "manual")

        XCTAssertEqual(QuotaUnit.tokens.rawValue, "tokens")
        XCTAssertEqual(QuotaUnit.requests.rawValue, "requests")
        XCTAssertEqual(QuotaUnit.messages.rawValue, "messages")
        XCTAssertEqual(QuotaUnit.usd.rawValue, "usd")
        XCTAssertEqual(QuotaUnit.percent.rawValue, "percent")
        XCTAssertEqual(QuotaUnit.unknown.rawValue, "unknown")

        XCTAssertEqual(QuotaConfidence.verified.rawValue, "verified")
        XCTAssertEqual(QuotaConfidence.estimated.rawValue, "estimated")
        XCTAssertEqual(QuotaConfidence.manual.rawValue, "manual")
        XCTAssertEqual(QuotaConfidence.unknown.rawValue, "unknown")
    }

    func testSnapshotReportsUnavailableWhenNoWindowsExist() {
        let now = Date(timeIntervalSince1970: 120)
        let snapshot = ProviderQuotaSnapshot(
            providerId: "local-codex",
            displayName: "Codex",
            status: .unavailable,
            source: .local,
            refreshedAt: Date(timeIntervalSince1970: 100),
            staleAfter: Date(timeIntervalSince1970: 160),
            windows: [],
            errors: ["Needs calibration"]
        )

        XCTAssertFalse(snapshot.canShowPercentages(now: now))
    }

    func testSnapshotSuppressesPercentagesWhenUnavailableWithDisplayableWindow() {
        let now = Date(timeIntervalSince1970: 120)
        let snapshot = makeSnapshot(status: .unavailable, windows: [
            makeWindow(limit: 100, remaining: 72, confidence: .verified)
        ])

        XCTAssertFalse(snapshot.canShowPercentages(now: now))
    }

    func testSnapshotSuppressesPercentagesWhenStatusIsError() {
        let now = Date(timeIntervalSince1970: 120)
        let snapshot = makeSnapshot(status: .error, windows: [
            makeWindow(limit: 100, remaining: 72, confidence: .verified)
        ])

        XCTAssertFalse(snapshot.canShowPercentages(now: now))
    }

    func testSnapshotAllowsPercentagesWhenStatusIsEstimated() {
        let now = Date(timeIntervalSince1970: 120)
        let snapshot = makeSnapshot(status: .estimated, windows: [
            makeWindow(limit: 100, remaining: 72, confidence: .estimated)
        ])

        XCTAssertTrue(snapshot.canShowPercentages(now: now))
    }

    func testSnapshotIsStaleAtStaleAfterBoundary() {
        let staleAfter = Date(timeIntervalSince1970: 160)
        let snapshot = makeSnapshot(
            status: .available,
            staleAfter: staleAfter,
            windows: [makeWindow(limit: 100, remaining: 72)]
        )

        XCTAssertTrue(snapshot.isStale(now: staleAfter))
    }

    func testSnapshotSuppressesPercentagesWhenStale() {
        let staleAfter = Date(timeIntervalSince1970: 160)
        let snapshot = makeSnapshot(
            status: .available,
            staleAfter: staleAfter,
            windows: [makeWindow(limit: 100, remaining: 72)]
        )

        XCTAssertTrue(snapshot.canShowPercentages(now: Date(timeIntervalSince1970: 159)))
        XCTAssertFalse(snapshot.canShowPercentages(now: staleAfter))
    }

    func testProviderQuotaSnapshotCodableRoundTrips() throws {
        let snapshot = makeSnapshot(
            status: .estimated,
            windows: [makeWindow(limit: 100, remaining: 72, confidence: .verified)]
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ProviderQuotaSnapshot.self, from: data)

        XCTAssertEqual(decoded, snapshot)
    }

    private func makeWindow(
        limit: Double,
        remaining: Double,
        used: Double? = nil,
        confidence: QuotaConfidence = .estimated
    ) -> QuotaWindow {
        QuotaWindow(
            id: "codex-5h",
            labelKey: "quota.window.codex.5h",
            kind: .rolling,
            used: used ?? limit - remaining,
            limit: limit,
            remaining: remaining,
            unit: .percent,
            resetAt: Date(timeIntervalSince1970: 1_800),
            confidence: confidence
        )
    }

    private func makeSnapshot(
        status: ProviderStatus,
        staleAfter: Date = Date(timeIntervalSince1970: 160),
        windows: [QuotaWindow]
    ) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(
            providerId: "local-codex",
            displayName: "Codex",
            status: status,
            source: .local,
            refreshedAt: Date(timeIntervalSince1970: 100),
            staleAfter: staleAfter,
            windows: windows,
            errors: []
        )
    }
}

import XCTest
@testable import ReadyCheckCore

final class QuotaResetCountdownTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testFormatsMinuteHourAndDayIntervalsInBothLanguages() {
        let zh = LocalizationService(language: .zhCN)
        let en = LocalizationService(language: .enUS)
        XCTAssertEqual(countdown(after: 59).text(localization: zh), "距重置不到 1 分钟")
        XCTAssertEqual(countdown(after: 60).text(localization: en), "Resets in 1m")
        XCTAssertEqual(countdown(after: 3_600 + 61).text(localization: zh), "距重置 1 小时 2 分")
        XCTAssertEqual(countdown(after: 86_400 + 3_600).text(localization: en), "Resets in 1d 1h")
    }

    func testZeroAndPastDeadlineWaitForDataRatherThanClaimRecovery() {
        XCTAssertEqual(countdown(after: 0), .waitingForRefresh)
        XCTAssertEqual(countdown(after: -60), .waitingForRefresh)
        XCTAssertEqual(countdown(after: 0).text(localization: .init(language: .zhCN)), "等待刷新确认")
    }

    func testMissingStaleEstimatedAndMockDataCannotProvideCountdown() {
        XCTAssertEqual(countdown(after: nil), .unknown)
        XCTAssertEqual(countdown(after: 3_600, stale: true), .unknown)
        XCTAssertEqual(countdown(after: 3_600, status: .error), .unknown)
        XCTAssertEqual(countdown(after: 3_600, status: .estimated), .unknown)
        XCTAssertEqual(countdown(after: 3_600, source: .mock), .unknown)
        XCTAssertEqual(countdown(after: 3_600, confidence: .estimated), .unknown)
        XCTAssertEqual(countdown(after: .infinity), .unknown)
        XCTAssertEqual(countdown(after: 3_600, source: .appServer), .remaining(minutes: 60))
    }

    func testClockAdvanceAndNewResetTimeUseLatestSnapshot() {
        let window = window(after: 120)
        let snapshot = snapshot(window)
        XCTAssertEqual(QuotaResetCountdown(window: window, snapshot: snapshot, now: now), .remaining(minutes: 2))
        XCTAssertEqual(QuotaResetCountdown(window: window, snapshot: snapshot, now: now.addingTimeInterval(120)), .waitingForRefresh)
        XCTAssertEqual(countdown(after: 18_000), .remaining(minutes: 300))
        XCTAssertEqual(QuotaResetCountdown(window: window, snapshot: nil, now: now), .unknown)
    }

    private func countdown(after: TimeInterval?, stale: Bool = false, status: ProviderStatus = .available,
                           source: ProviderSource = .oauthAPI, confidence: QuotaConfidence = .verified) -> QuotaResetCountdown {
        let window = window(after: after, confidence: confidence)
        return QuotaResetCountdown(window: window, snapshot: snapshot(window, stale: stale, status: status, source: source), now: now)
    }

    private func window(after: TimeInterval?, confidence: QuotaConfidence = .verified) -> QuotaWindow {
        QuotaWindow(id: "five-hour", labelKey: "quota.window.codex.primary", kind: .rolling,
            used: 27, limit: 100, remaining: 73, unit: .percent,
            resetAt: after.map { now.addingTimeInterval($0) }, confidence: confidence, durationMinutes: 300)
    }

    private func snapshot(_ window: QuotaWindow, stale: Bool = false,
                          status: ProviderStatus = .available, source: ProviderSource = .oauthAPI) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: status, source: source,
            refreshedAt: now, staleAfter: now.addingTimeInterval(stale ? 0 : 600), windows: [window], errors: [])
    }
}

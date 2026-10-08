import XCTest
@testable import ReadyCheckCore

final class LowQuotaReminderTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_900_000_000)

    func testFirstLowReadingDoesNotReplayAnAlert() {
        XCTAssertTrue(evaluate([0.15], tick: 0).alerts.isEmpty)
        XCTAssertTrue(evaluate([0.35], tick: 0, threshold: 0).alerts.isEmpty)
    }

    func testCrossingNotifiesOnceIncludingAfterARefreshOrSameCycleRebound() {
        var state = evaluate([0.35], tick: 0).state
        let crossing = evaluate([0.20], tick: 1, state: state)
        XCTAssertEqual(crossing.alerts.map(\.remainingPercent), [20])
        state = crossing.state
        XCTAssertTrue(evaluate([0.19], tick: 2, state: state).alerts.isEmpty)
        state = evaluate([0.25], tick: 3, state: state).state
        XCTAssertTrue(evaluate([0.10], tick: 4, state: state).alerts.isEmpty)
    }

    func testSameDurationWindowsAreIndependent() {
        let baseline = evaluate([0.30, 0.40], tick: 0).state
        let result = evaluate([0.19, 0.09], tick: 1, state: baseline)
        XCTAssertEqual(Set(result.alerts.map(\.windowID)), ["window-0", "window-1"])
        XCTAssertEqual(Set(result.alerts.map(\.id)).count, 2)
    }

    func testAccountChangeAndNewResetEstablishNewBaselines() {
        let baseline = evaluate([0.40], tick: 0).state
        XCTAssertTrue(evaluate([0.10], tick: 1, state: baseline, account: "another-account").alerts.isEmpty)
        let notified = evaluate([0.10], tick: 1, state: baseline).state
        let newCycle = evaluate([0.40], tick: 2, state: notified, resetOffset: 7200).state
        XCTAssertEqual(evaluate([0.10], tick: 3, state: newCycle, resetOffset: 7200).alerts.count, 1)
    }

    func testInvalidStaleEstimatedAndOutOfOrderReadingsDoNotNotify() {
        let baseline = evaluate([0.40], tick: 10).state
        XCTAssertTrue(evaluate([0.10], tick: 9, state: baseline).alerts.isEmpty)
        XCTAssertTrue(evaluate([0.10], tick: 11, state: baseline, status: .error).alerts.isEmpty)
        XCTAssertTrue(evaluate([0.10], tick: 11, state: baseline, source: .mock).alerts.isEmpty)
        XCTAssertTrue(evaluate([0.10], tick: 11, state: baseline, confidence: .estimated).alerts.isEmpty)
        XCTAssertTrue(evaluate([1.20], tick: 11, state: baseline).alerts.isEmpty)
        XCTAssertTrue(evaluate([0.10], tick: 11, state: baseline, account: nil).alerts.isEmpty)
        let stale = snapshot([0.10], tick: 11)
        XCTAssertTrue(LowQuotaReminderEvaluator.evaluate(snapshot: stale, now: start.addingTimeInterval(500), account: "account", threshold: 20, state: baseline).alerts.isEmpty)
    }

    func testTemporarilyMissingWindowDoesNotLoseDeduplication() {
        var state = evaluate([0.40], tick: 0).state
        state = evaluate([0.10], tick: 1, state: state).state
        state = evaluate([], tick: 2, state: state).state
        XCTAssertTrue(evaluate([0.09], tick: 3, state: state).alerts.isEmpty)
    }

    func testTenPercentAndResetWithoutTimestamp() {
        var state = evaluate([0.15], tick: 0, threshold: 10, resetOffset: nil).state
        XCTAssertTrue(evaluate([0.11], tick: 1, threshold: 10, state: state, resetOffset: nil).alerts.isEmpty)
        state = evaluate([0.10], tick: 2, threshold: 10, state: state, resetOffset: nil).state
        state = evaluate([0.50], tick: 3, threshold: 10, state: state, resetOffset: nil).state
        XCTAssertEqual(evaluate([0.09], tick: 4, threshold: 10, state: state, resetOffset: nil).alerts.count, 1)
    }

    func testFailedDeliveryRetriesWithSameIdentifierAndPersistsAcrossRestart() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("reminders.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = QuotaReminderStore(fileURL: url)
        let saved = await store.setLowQuotaThreshold(20)
        XCTAssertTrue(saved)
        let baseline = await store.prepare(snapshot([0.40], tick: 0), now: start, account: "account")
        await store.commit(baseline, deliveredEvents: [], now: start)
        let failed = await store.prepare(snapshot([0.10], tick: 1), now: start.addingTimeInterval(1), account: "account")
        await store.commit(failed, deliveredEvents: [], now: start.addingTimeInterval(1))
        let restarted = QuotaReminderStore(fileURL: url)
        let retry = await restarted.prepare(snapshot([0.09], tick: 2), now: start.addingTimeInterval(2), account: "account")
        let firstID = lowAlerts(failed.events).first?.id
        XCTAssertNotNil(firstID)
        XCTAssertEqual(lowAlerts(retry.events).first?.id, firstID)
        await restarted.commit(retry, deliveredEvents: retry.events, now: start.addingTimeInterval(2))
        let after = await restarted.prepare(snapshot([0.08], tick: 3), now: start.addingTimeInterval(3), account: "account")
        XCTAssertTrue(lowAlerts(after.events).isEmpty)
        let history = await restarted.history()
        XCTAssertEqual(history.first(where: { $0.kind == .quotaLow })?.status, .delivered)
        XCTAssertEqual(history.first(where: { $0.kind == .quotaLow })?.attemptCount, 2)
    }

    func testDisablingDuringDeliveryCannotRestoreOldPreference() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("reminders.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = QuotaReminderStore(fileURL: url)
        _ = await store.setLowQuotaThreshold(20)
        let baseline = await store.prepare(snapshot([0.40], tick: 0), now: start, account: "account")
        await store.commit(baseline, deliveredEvents: [], now: start)
        let pending = await store.prepare(snapshot([0.10], tick: 1), now: start.addingTimeInterval(1), account: "account")
        _ = await store.setLowQuotaThreshold(0)
        await store.commit(pending, deliveredEvents: [], now: start.addingTimeInterval(1))
        let threshold = await store.lowQuotaThreshold()
        XCTAssertEqual(threshold, 0)
        let next = await store.prepare(snapshot([0.09], tick: 2), now: start.addingTimeInterval(2), account: "account")
        XCTAssertTrue(lowAlerts(next.events).isEmpty)
    }

    func testOldReminderStateStillDecodesWithAlertsOff() throws {
        let data = try JSONEncoder().encode(QuotaReminderState())
        let decoded = try JSONDecoder().decode(QuotaReminderState.self, from: data)
        XCTAssertNil(decoded.lowQuotaThreshold)
        XCTAssertNil(decoded.lowQuotaState)
    }

    private func lowAlerts(_ events: [QuotaReminderEvent]) -> [LowQuotaAlert] {
        events.compactMap { if case let .quotaLow(alert) = $0 { alert } else { nil } }
    }

    private func evaluate(_ ratios: [Double], tick: Int, threshold: Int = 20, state: LowQuotaReminderState? = nil, account: String? = "account", resetOffset: TimeInterval? = 3600, status: ProviderStatus = .available, source: ProviderSource = .oauthAPI, confidence: QuotaConfidence = .verified) -> (state: LowQuotaReminderState?, alerts: [LowQuotaAlert]) {
        LowQuotaReminderEvaluator.evaluate(snapshot: snapshot(ratios, tick: tick, resetOffset: resetOffset, status: status, source: source, confidence: confidence), now: start.addingTimeInterval(Double(tick)), account: account, threshold: threshold, state: state)
    }

    private func snapshot(_ ratios: [Double], tick: Int, resetOffset: TimeInterval? = 3600, status: ProviderStatus = .available, source: ProviderSource = .oauthAPI, confidence: QuotaConfidence = .verified) -> ProviderQuotaSnapshot {
        let date = start.addingTimeInterval(Double(tick))
        return ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: status, source: source, refreshedAt: date, staleAfter: date.addingTimeInterval(60), windows: ratios.enumerated().map { index, ratio in
            QuotaWindow(id: "window-\(index)", labelKey: "quota.fiveHour", displayLabel: "Window \(index)", kind: .rateLimit, used: (1-ratio)*100, limit: 100, remaining: ratio*100, unit: .percent, resetAt: resetOffset.map { start.addingTimeInterval($0) }, confidence: confidence, durationMinutes: 300)
        }, errors: [])
    }
}

import XCTest
@testable import ReadyCheckCore

final class QuotaRecoveryReminderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func snapshot(_ remaining: [Double], status: ProviderStatus = .available,
                          confidence: QuotaConfidence = .verified, stale: Bool = false,
                          blocked: Bool = false, refreshedOffset: TimeInterval = 0) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: status,
            source: .appServer, refreshedAt: now.addingTimeInterval(refreshedOffset), staleAfter: now.addingTimeInterval(stale ? -1 : 300),
            windows: remaining.enumerated().map { index, value in
                QuotaWindow(id: "window-\(index)", labelKey: "quota.window", limitStateCode: blocked ? "limit_reached" : nil,
                    kind: .rolling, used: 1 - value, limit: 1, remaining: value, unit: .percent,
                    resetAt: now.addingTimeInterval(-60), confidence: confidence)
            }, errors: [])
    }

    func testTracksPartiallyConsumedQuota() {
        XCTAssertTrue(QuotaRecoveryRequest.canArm(snapshot([0, 0.5]), now: now))
        XCTAssertTrue(QuotaRecoveryRequest.canArm(snapshot([0.1]), now: now))
        XCTAssertFalse(QuotaRecoveryRequest.canArm(snapshot([0], stale: true), now: now))
        XCTAssertFalse(QuotaRecoveryRequest.canArm(snapshot([0], confidence: .estimated), now: now))
    }

    func testWaitsForAllWindowsAndActualFreshRecovery() {
        let request = QuotaRecoveryRequest(account: "test-account", snapshot: snapshot([0, 0], refreshedOffset: -1))
        for candidate in [snapshot([0, 0]), snapshot([1]),
                          snapshot([1, 1], stale: true), snapshot([1, 1], status: .error),
                          snapshot([1, 1], confidence: .estimated),
                          snapshot([1, 1], refreshedOffset: -1)] {
            XCTAssertFalse(request.isRecovered(candidate, account: "test-account", now: now.addingTimeInterval(1)))
        }
        XCTAssertFalse(request.isRecovered(snapshot([1, 1]), account: "other", now: now))
        XCTAssertTrue(request.isRecovered(snapshot([1, 1]), account: "test-account", now: now))
    }

    func testPersistenceFailureRetryOneShotAndCancellation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("reminders.json")
        let store = QuotaReminderStore(fileURL: url)
        let request = QuotaRecoveryRequest(account: "test-account", snapshot: snapshot([0, 0], refreshedOffset: -1))
        let saved = await store.setRecoveryRequest(request)
        XCTAssertTrue(saved)
        let reopened = QuotaReminderStore(fileURL: url)
        let persisted = await reopened.recoveryRequest()
        XCTAssertEqual(persisted, request)
        let batch = await reopened.prepare(snapshot([1, 1]), now: now, account: "test-account")
        XCTAssertEqual(batch.events, [.quotaRecovered(requestID: request.id)])
        await reopened.commit(batch, deliveredEvents: [], now: now)
        let retry = await reopened.prepare(snapshot([1, 1]), now: now, account: "test-account")
        XCTAssertEqual(retry.events, batch.events)
        await reopened.commit(retry, deliveredEvents: retry.events, now: now)
        let completed = await reopened.prepare(snapshot([1, 1]), now: now, account: "test-account")
        XCTAssertTrue(completed.events.isEmpty)
        let history = await reopened.history()
        XCTAssertEqual(history.first?.attemptCount, 2)
        XCTAssertEqual(history.first?.status, .delivered)

        _ = await reopened.setRecoveryRequest(request)
        let inFlight = await reopened.prepare(snapshot([1, 1]), now: now, account: "test-account")
        _ = await reopened.setRecoveryRequest(nil)
        await reopened.commit(inFlight, deliveredEvents: [], now: now)
        let cancelled = await reopened.recoveryRequest()
        XCTAssertNil(cancelled, "A failed in-flight delivery must not rearm a cancelled request")
    }

    func testFailedPersistenceDoesNotClaimArmed() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("blocked".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = QuotaReminderStore(fileURL: file.appendingPathComponent("reminders.json"))
        let saved = await store.setRecoveryRequest(QuotaRecoveryRequest(account: "test-account", snapshot: snapshot([0])))
        XCTAssertFalse(saved)
    }

    func testOldDeliveryCannotOverwriteNewRequest() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json"))
        let old = QuotaRecoveryRequest(account: "test-account", snapshot: snapshot([0], refreshedOffset: -1))
        _ = await store.setRecoveryRequest(old)
        let batch = await store.prepare(snapshot([1]), now: now, account: "test-account")
        let new = QuotaRecoveryRequest(account: "test-account", snapshot: snapshot([0]))
        _ = await store.setRecoveryRequest(new)
        await store.commit(batch, deliveredEvents: batch.events, now: now)
        let current = await store.recoveryRequest()
        XCTAssertEqual(current, new)
    }

    func testOlderStateDecodesWithoutRecoveryRequest() throws {
        let data = try JSONEncoder().encode(QuotaReminderState())
        let state = try JSONDecoder().decode(QuotaReminderState.self, from: data)
        XCTAssertNil(state.recoveryRequest)
        XCTAssertTrue(state.isAutomaticRecoveryEnabled)
    }

    func testAutomaticRecoveryRepeatsForEachExhaustionWithoutManualAction() {
        var state = QuotaReminderState()
        let healthy = QuotaReminderEvaluator.evaluate(snapshot: snapshot([1, 1]), now: now, state: state, account: "test-account")
        XCTAssertTrue(healthy.events.isEmpty, "Do not notify for recovery that was never observed")
        XCTAssertNil(healthy.state.recoveryRequest)
        for offset in [0.0, 10.0] {
            let exhausted = QuotaReminderEvaluator.evaluate(snapshot: snapshot([0, 0.5], refreshedOffset: offset), now: now.addingTimeInterval(offset), state: state, account: "test-account")
            XCTAssertNotNil(exhausted.state.recoveryRequest)
            XCTAssertTrue(exhausted.events.isEmpty)
            let recovered = QuotaReminderEvaluator.evaluate(snapshot: snapshot([1, 0.5], refreshedOffset: offset + 1), now: now.addingTimeInterval(offset + 1), state: exhausted.state, account: "test-account")
            XCTAssertEqual(recovered.events.count, 1)
            XCTAssertNotNil(recovered.state.recoveryRequest)
            state = recovered.state
            XCTAssertTrue(QuotaReminderEvaluator.evaluate(snapshot: snapshot([1, 0.5], refreshedOffset: offset + 2), now: now.addingTimeInterval(offset + 2), state: state, account: "test-account").events.isEmpty)
        }
    }

    func testPartialRecoveryConsumptionAndIndependentWindows() {
        var state = QuotaReminderState()
        let samples: [([Double], Int)] = [([0.8, 0], 0), ([0.5, 0], 0), ([1, 0], 1), ([1, 0], 0), ([1, 0.7], 1), ([1, 0.7], 0)]
        for (index, sample) in samples.enumerated() {
            let result = QuotaReminderEvaluator.evaluate(snapshot: snapshot(sample.0, refreshedOffset: Double(index)), now: now.addingTimeInterval(Double(index)), state: state, account: "test-account")
            XCTAssertEqual(result.events.count, sample.1)
            state = result.state
        }
    }

    func testDisabledMonitoringSurvivesRestartAndDiscardsInFlightArming() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("reminders.json")
        let store = QuotaReminderStore(fileURL: url)
        let batch = await store.prepare(snapshot([0]), now: now, account: "test-account")
        XCTAssertNotNil(batch.proposedState.recoveryRequest)
        let saved = await store.setAutomaticRecoveryEnabled(false)
        XCTAssertTrue(saved)
        await store.commit(batch, deliveredEvents: [], now: now)
        let reopened = QuotaReminderStore(fileURL: url)
        let enabled = await reopened.automaticRecoveryEnabled()
        XCTAssertFalse(enabled)
        let disabledBatch = await reopened.prepare(snapshot([0]), now: now, account: "test-account")
        XCTAssertNil(disabledBatch.proposedState.recoveryRequest)
        _ = await reopened.setAutomaticRecoveryEnabled(true)
        let rearmed = await reopened.prepare(snapshot([0]), now: now, account: "test-account")
        await reopened.commit(rearmed, deliveredEvents: [], now: now)
        let persisted = await QuotaReminderStore(fileURL: url).recoveryRequest()
        XCTAssertNotNil(persisted)
    }

    func testInvalidDataAndOtherAccountDoNotTriggerAutomaticRecovery() {
        for candidate in [snapshot([0], stale: true), snapshot([0], status: .error), snapshot([0], confidence: .estimated)] {
            XCTAssertNil(QuotaReminderEvaluator.evaluate(snapshot: candidate, now: now, state: QuotaReminderState(), account: "test-account").state.recoveryRequest)
        }
        let exhausted = QuotaReminderEvaluator.evaluate(snapshot: snapshot([0]), now: now, state: QuotaReminderState(), account: "first")
        let other = QuotaReminderEvaluator.evaluate(snapshot: snapshot([1], refreshedOffset: 1), now: now.addingTimeInterval(1), state: exhausted.state, account: "second")
        XCTAssertTrue(other.events.isEmpty)
        XCTAssertNil(other.state.recoveryRequest)
    }

    func testDisablingCancelsPendingDeliveryAndSurvivesOldCommit() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json"))
        let arm = await store.prepare(snapshot([0]), now: now, account: "test-account")
        await store.commit(arm, deliveredEvents: [], now: now)
        let requestID = arm.proposedState.recoveryRequest!.id
        let active = await store.isRecoveryRequestActive(requestID)
        XCTAssertTrue(active)
        let delivery = await store.prepare(snapshot([1], refreshedOffset: 1), now: now.addingTimeInterval(1), account: "test-account")
        _ = await store.setAutomaticRecoveryEnabled(false)
        let cancelled = await store.isRecoveryRequestActive(requestID)
        XCTAssertFalse(cancelled)
        await store.commit(delivery, deliveredEvents: [], now: now)
        let current = await store.recoveryRequest()
        XCTAssertNil(current)
        let enabled = await store.automaticRecoveryEnabled()
        XCTAssertFalse(enabled)
    }

    func testOffOnDuringArmingDoesNotRestoreDiscardedRequest() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json"))
        let batch = await store.prepare(snapshot([0]), now: now, account: "test-account")
        _ = await store.setAutomaticRecoveryEnabled(false)
        _ = await store.setAutomaticRecoveryEnabled(true)
        await store.commit(batch, deliveredEvents: [], now: now)
        let current = await store.recoveryRequest()
        XCTAssertNil(current)
        let next = await store.prepare(snapshot([0]), now: now, account: "test-account")
        XCTAssertNotNil(next.proposedState.recoveryRequest)
    }
}

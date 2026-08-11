import XCTest
@testable import ReadyCheckCore

final class QuotaReminderTests: XCTestCase {
    func testCreditsReminderTriggersOncePerExhaustedQuotaCycle() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var state = QuotaReminderState()

        state = evaluate(snapshot(remaining: 0.2, credits: "10"), now: now, state: state).state
        state = evaluate(snapshot(remaining: 0, credits: "10"), now: now, state: state).state

        var result = evaluate(snapshot(remaining: 0, credits: "9.5"), now: now, state: state)
        XCTAssertEqual(result.events, [.creditsStarted])

        result = evaluate(snapshot(remaining: 0, credits: "9"), now: now, state: result.state)
        XCTAssertEqual(result.events, [])

        state = evaluate(snapshot(remaining: 0.8, credits: "9"), now: now, state: result.state).state
        state = evaluate(snapshot(remaining: 0, credits: "9"), now: now, state: state).state
        result = evaluate(snapshot(remaining: 0, credits: "8.5"), now: now, state: state)
        XCTAssertEqual(result.events, [.creditsStarted])
    }

    func testCreditsDecreaseDoesNotNotifyWhileQuotaRemains() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var state = evaluate(
            snapshot(remaining: 0.5, credits: "10"),
            now: now,
            state: QuotaReminderState()
        ).state

        let result = evaluate(snapshot(remaining: 0.4, credits: "9"), now: now, state: state)

        XCTAssertEqual(result.events, [])
        state = result.state
        XCTAssertFalse(state.creditsReminderSentForCurrentExhaustion)
    }

    func testNewResetCycleRearmsReminderWhenRestoreWasNotObserved() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var state = evaluate(
            snapshot(remaining: 0.2, credits: "10", resetAt: now.addingTimeInterval(3_600)),
            now: now,
            state: QuotaReminderState()
        ).state
        state = evaluate(
            snapshot(remaining: 0, credits: "10", resetAt: now.addingTimeInterval(3_600)),
            now: now,
            state: state
        ).state
        state = evaluate(
            snapshot(remaining: 0, credits: "9", resetAt: now.addingTimeInterval(3_600)),
            now: now,
            state: state
        ).state

        let nextCycle = evaluate(
            snapshot(remaining: 0, credits: "8.5", resetAt: now.addingTimeInterval(7_200)),
            now: now,
            state: state
        )

        XCTAssertEqual(nextCycle.events, [.creditsStarted])
    }

    func testManualResetExpirationNotifiesAtEachThreshold() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(73 * 60 * 60)
        let quota = snapshot(remaining: 0.5, credits: "10", expirations: [expiration])

        var result = evaluate(quota, now: now, state: QuotaReminderState())
        XCTAssertEqual(result.events, [])

        result = evaluate(quota, now: now.addingTimeInterval(2 * 60 * 60), state: result.state)
        XCTAssertEqual(result.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 72)
        ])

        result = evaluate(quota, now: now.addingTimeInterval(26 * 60 * 60), state: result.state)
        XCTAssertEqual(result.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 48)
        ])

        result = evaluate(quota, now: now.addingTimeInterval(50 * 60 * 60), state: result.state)
        XCTAssertEqual(result.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 24)
        ])

        result = evaluate(quota, now: now.addingTimeInterval(62 * 60 * 60), state: result.state)
        XCTAssertEqual(result.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 12)
        ])

        result = evaluate(quota, now: now.addingTimeInterval(63 * 60 * 60), state: result.state)
        XCTAssertEqual(result.events, [])
    }

    func testManualResetReminderDoesNotBurstAfterMissingSeveralThresholds() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(10 * 60 * 60)
        let quota = snapshot(remaining: 0.5, credits: "10", expirations: [expiration])

        let first = evaluate(quota, now: now, state: QuotaReminderState())
        XCTAssertEqual(first.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 12)
        ])

        let second = evaluate(quota, now: now.addingTimeInterval(60), state: first.state)
        XCTAssertEqual(second.events, [])
    }

    func testUsedManualResetStopsLaterThresholds() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(71 * 60 * 60)
        let first = evaluate(
            snapshot(remaining: 0.5, credits: "10", expirations: [expiration]),
            now: now,
            state: QuotaReminderState()
        )
        XCTAssertEqual(first.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 72)
        ])

        let afterUse = evaluate(
            snapshot(remaining: 0.5, credits: "10", expirations: [], manualResetCount: 0),
            now: now.addingTimeInterval(24 * 60 * 60),
            state: first.state
        )
        XCTAssertEqual(afterUse.events, [])
    }

    func testLegacyThreeDayReminderStateDoesNotRepeatAfterUpgrade() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(71 * 60 * 60)
        let timestamp = Int64(expiration.timeIntervalSince1970.rounded())
        let legacyState = QuotaReminderState(notifiedManualResetExpirations: [timestamp])
        let quota = snapshot(remaining: 0.5, credits: "10", expirations: [expiration])

        let result = evaluate(quota, now: now, state: legacyState)

        XCTAssertEqual(result.events, [])
        XCTAssertEqual(result.state.notifiedManualResetExpirations, [])
        XCTAssertTrue(result.state.notifiedManualResetThresholds?.contains("\(timestamp):72") == true)
    }

    func testKnownFutureExpirationSurvivesTemporarilyMissingResetPayload() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(40 * 60 * 60)
        let timestamp = Int64(expiration.timeIntervalSince1970.rounded())
        let knownState = QuotaReminderState(knownManualResetExpirations: [timestamp])

        let result = evaluate(
            snapshot(remaining: 0.5, credits: "10", manualResetCount: nil),
            now: now,
            state: knownState
        )

        XCTAssertEqual(result.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 48)
        ])
        XCTAssertEqual(result.state.knownManualResetExpirations, [timestamp])
    }

    func testSmallExpirationTimestampDriftDoesNotRepeatThreshold() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let storedExpiration = now.addingTimeInterval(70 * 60 * 60)
        let reportedExpiration = storedExpiration.addingTimeInterval(1)
        let storedTimestamp = Int64(storedExpiration.timeIntervalSince1970.rounded())
        let state = QuotaReminderState(
            notifiedManualResetThresholds: ["\(storedTimestamp):72"]
        )

        let result = evaluate(
            snapshot(remaining: 0.5, credits: "10", expirations: [reportedExpiration]),
            now: now,
            state: state
        )

        XCTAssertEqual(result.events, [])
    }

    func testExplicitZeroResetCountClearsKnownExpiration() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(40 * 60 * 60)
        let timestamp = Int64(expiration.timeIntervalSince1970.rounded())
        let knownState = QuotaReminderState(knownManualResetExpirations: [timestamp])

        let result = evaluate(
            snapshot(remaining: 0.5, credits: "10", manualResetCount: 0),
            now: now,
            state: knownState
        )

        XCTAssertEqual(result.events, [])
        XCTAssertEqual(result.state.knownManualResetExpirations, [])
    }

    func testUnavailableSnapshotDoesNotMutateCreditCycle() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let original = QuotaReminderState(
            notifiedManualResetExpirations: [],
            previousCreditBalance: "10",
            creditsReminderSentForCurrentExhaustion: true
        )
        let unavailable = snapshot(remaining: 0, credits: "9", status: .unavailable)

        let result = evaluate(unavailable, now: now, state: original)

        XCTAssertEqual(result.events, [])
        XCTAssertEqual(result.state, original)
    }

    func testStorePersistsCreditCycleAcrossRelaunch() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("reminders.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = QuotaReminderStore(fileURL: fileURL)

        _ = await store.evaluate(snapshot(remaining: 0.2, credits: "10"), now: now)
        _ = await store.evaluate(snapshot(remaining: 0, credits: "10"), now: now)
        let firstEvents = await store.evaluate(snapshot(remaining: 0, credits: "9.5"), now: now)
        XCTAssertEqual(firstEvents, [.creditsStarted])

        let reloaded = QuotaReminderStore(fileURL: fileURL)
        let reloadedEvents = await reloaded.evaluate(snapshot(remaining: 0, credits: "9"), now: now)
        XCTAssertEqual(reloadedEvents, [])
    }

    func testStoreRetriesReminderUntilDeliveryIsConfirmed() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("reminders.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(40 * 60 * 60)
        let quota = snapshot(remaining: 0.5, credits: "10", expirations: [expiration])
        let store = QuotaReminderStore(fileURL: fileURL)

        let first = await store.prepare(quota, now: now)
        XCTAssertEqual(first.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 48)
        ])
        await store.commit(first, deliveredEvents: [])

        let retry = await store.prepare(quota, now: now.addingTimeInterval(60))
        XCTAssertEqual(retry.events, [
            .manualResetExpiring(index: 1, expiresAt: expiration, leadHours: 48)
        ])
        await store.commit(retry, deliveredEvents: retry.events)

        let afterDelivery = await store.prepare(quota, now: now.addingTimeInterval(120))
        XCTAssertEqual(afterDelivery.events, [])
    }

    func testStoreRecordsFailedAttemptThenConfirmedDelivery() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("reminders.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiration = now.addingTimeInterval(40 * 60 * 60)
        let quota = snapshot(remaining: 0.5, credits: "10", expirations: [expiration])
        let store = QuotaReminderStore(fileURL: fileURL)

        let failedBatch = await store.prepare(quota, now: now)
        await store.commit(failedBatch, deliveredEvents: [], now: now)
        var history = await store.history()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].status, .failed)
        XCTAssertEqual(history[0].attemptCount, 1)
        XCTAssertNil(history[0].deliveredAt)

        let deliveredAt = now.addingTimeInterval(60)
        let retryBatch = await store.prepare(quota, now: deliveredAt)
        await store.commit(retryBatch, deliveredEvents: retryBatch.events, now: deliveredAt)
        history = await store.history()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].status, .delivered)
        XCTAssertEqual(history[0].attemptCount, 2)
        XCTAssertEqual(history[0].deliveredAt, deliveredAt)
    }

    func testStoreMigratesLegacyThresholdsAsUnconfirmedHistory() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("reminders.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let timestamp: Int64 = 1_800_200_000
        let legacyState = QuotaReminderState(
            notifiedManualResetThresholds: ["\(timestamp):48"]
        )
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? JSONEncoder().encode(legacyState).write(to: fileURL)

        let history = await QuotaReminderStore(fileURL: fileURL).history()

        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].status, .legacyUnknown)
        XCTAssertEqual(history[0].leadHours, 48)
        XCTAssertEqual(history[0].expiresAt, Date(timeIntervalSince1970: TimeInterval(timestamp)))
        XCTAssertEqual(history[0].attemptCount, 0)
        let persistedState = try? JSONDecoder().decode(
            QuotaReminderState.self,
            from: Data(contentsOf: fileURL)
        )
        XCTAssertEqual(persistedState?.notificationHistoryMigrationCompleted, true)
        XCTAssertEqual(persistedState?.notificationHistory?.count, 1)
    }

    private func evaluate(
        _ snapshot: ProviderQuotaSnapshot,
        now: Date,
        state: QuotaReminderState
    ) -> QuotaReminderEvaluation {
        QuotaReminderEvaluator.evaluate(snapshot: snapshot, now: now, state: state)
    }

    private func snapshot(
        remaining: Double,
        credits: String?,
        expirations: [Date] = [],
        manualResetCount: Int? = nil,
        status: ProviderStatus = .available,
        resetAt: Date? = nil
    ) -> ProviderQuotaSnapshot {
        let refreshedAt = Date(timeIntervalSince1970: 1_800_000_000)
        return ProviderQuotaSnapshot(
            providerId: "codex-oauth",
            displayName: "Codex",
            status: status,
            source: .appServer,
            refreshedAt: refreshedAt,
            staleAfter: refreshedAt.addingTimeInterval(300),
            windows: [
                QuotaWindow(
                    id: "codex-primary",
                    labelKey: "quota.window.codex.7d",
                    kind: .rolling,
                    used: (1 - remaining) * 100,
                    limit: 100,
                    remaining: remaining * 100,
                    unit: .percent,
                    resetAt: resetAt ?? refreshedAt.addingTimeInterval(86_400),
                    confidence: .verified
                )
            ],
            errors: [],
            details: ProviderQuotaDetails(
                manualResetCount: manualResetCount,
                manualResetExpirations: expirations,
                creditBalance: credits,
                creditsUnlimited: false
            )
        )
    }
}

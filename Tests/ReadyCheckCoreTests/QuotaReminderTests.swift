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

    func testManualResetExpirationNotifiesOnceInsideThreeDayWindow() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let soon = now.addingTimeInterval(71 * 60 * 60)
        let later = now.addingTimeInterval(80 * 60 * 60)
        let expired = now.addingTimeInterval(-60)
        let quota = snapshot(
            remaining: 0.5,
            credits: "10",
            expirations: [expired, soon, later]
        )

        let first = evaluate(quota, now: now, state: QuotaReminderState())
        XCTAssertEqual(first.events, [.manualResetExpiring(index: 2, expiresAt: soon)])

        let second = evaluate(quota, now: now.addingTimeInterval(60), state: first.state)
        XCTAssertEqual(second.events, [])
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
                manualResetExpirations: expirations,
                creditBalance: credits,
                creditsUnlimited: false
            )
        )
    }
}

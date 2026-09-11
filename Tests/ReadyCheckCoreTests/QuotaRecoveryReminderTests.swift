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

    func testRequiresVerifiedExhaustionToArm() {
        XCTAssertTrue(QuotaRecoveryRequest.canArm(snapshot([0, 0.5]), now: now))
        XCTAssertFalse(QuotaRecoveryRequest.canArm(snapshot([0.1]), now: now))
        XCTAssertFalse(QuotaRecoveryRequest.canArm(snapshot([0], stale: true), now: now))
        XCTAssertFalse(QuotaRecoveryRequest.canArm(snapshot([0], confidence: .estimated), now: now))
    }

    func testWaitsForAllWindowsAndActualFreshRecovery() {
        let request = QuotaRecoveryRequest(account: "test-account", snapshot: snapshot([0, 0], refreshedOffset: -1))
        for candidate in [snapshot([0, 0]), snapshot([1, 0]), snapshot([1]),
                          snapshot([1, 1], stale: true), snapshot([1, 1], status: .error),
                          snapshot([1, 1], confidence: .estimated), snapshot([1, 1], blocked: true),
                          snapshot([1, 1, 0]), snapshot([1, 1], refreshedOffset: -1)] {
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
        XCTAssertNil(try JSONDecoder().decode(QuotaReminderState.self, from: data).recoveryRequest)
    }
}

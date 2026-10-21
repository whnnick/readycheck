import XCTest
@testable import ReadyCheckCore

final class ResetCreditAutomationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_900_000_000)
    func testConfirmedSuccessNoticePersistsIsAccountOwnedAndAcknowledgedOnce() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        let reloaded = ResetCreditAutomation(fileURL: directory.appendingPathComponent("state.json"))
        let notices = await reloaded.pendingSuccessNotices(account: "A")
        XCTAssertEqual(notices.count, 1)
        let legacyURL = directory.appendingPathComponent("legacy.json")
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("state.json"))) as? [String: Any])
        legacy["attempts"] = (legacy["attempts"] as? [[String: Any]])?.map { value in
            var value = value; value.removeValue(forKey: "successNotificationPending"); return value
        }
        try JSONSerialization.data(withJSONObject: legacy).write(to: legacyURL)
        let oldBuildNotices = await ResetCreditAutomation(fileURL: legacyURL).pendingSuccessNotices(account: "A")
        XCTAssertTrue(oldBuildNotices.isEmpty, "Do not retroactively notify old development-build receipts")
        let other = await reloaded.pendingSuccessNotices(account: "B")
        XCTAssertTrue(other.isEmpty)
        _ = await reloaded.setEnabled(false, account: "A")
        let stillPending = await reloaded.pendingSuccessNotices(account: "A")
        XCTAssertEqual(stillPending, notices, "Disabling future use must not hide a confirmed spend")
        let saved = await reloaded.acknowledgeSuccessNotice(notices[0].id, account: "A")
        XCTAssertTrue(saved)
        let restarted = ResetCreditAutomation(fileURL: directory.appendingPathComponent("state.json"))
        let done = await restarted.pendingSuccessNotices(account: "A")
        XCTAssertTrue(done.isEmpty)
    }

    func testOnlyConfirmedOutcomesCreateSuccessNotices() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        await client.failOnce()
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        let unknown = await store.pendingSuccessNotices(account: "A")
        XCTAssertTrue(unknown.isEmpty)
        _ = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(60))
        let confirmed = await store.pendingSuccessNotices(account: "A")
        XCTAssertEqual(confirmed.count, 1, "A confirmed already-redeemed response also notifies")
        let (unused, unusedClient, otherDirectory) = fixture()
        defer { try? FileManager.default.removeItem(at: otherDirectory) }
        _ = await unused.setEnabled(true, account: "A")
        await unusedClient.setOutcome(.nothingToReset)
        _ = await unused.tick(account: "A", token: nil, client: unusedClient, now: now)
        let noSuccess = await unused.pendingSuccessNotices(account: "A")
        XCTAssertTrue(noSuccess.isEmpty)
    }
    func testOffNeverReadsOrConsumesAndConsentIsAccountOwned() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        var calls = await client.calls
        XCTAssertEqual(calls, [])
        _ = await store.setEnabled(true, account: "B")
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        calls = await client.calls
        XCTAssertEqual(calls, [])
    }
    func testOnlyExactExpiringCardIsConsumedAndSuccessPersists() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        let result = await store.tick(account: "A", token: nil, client: client, now: now)
        XCTAssertEqual(result.status, .reset)
        let calls = await client.calls
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls.last?.components(separatedBy: ":").first, "card-soon")
        let reloaded = ResetCreditAutomation(fileURL: directory.appendingPathComponent("state.json"))
        _ = await reloaded.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(60))
        let after = await client.calls
        XCTAssertEqual(after.filter { $0.hasPrefix("card-soon:") }.count, 1)
    }
    func testUnknownOutcomeRetriesSameIdempotencyAfterRestart() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        await client.failOnce()
        _ = await store.setEnabled(true, account: "A")
        let first = await store.tick(account: "A", token: nil, client: client, now: now)
        XCTAssertEqual(first.status, .pending)
        let reloaded = ResetCreditAutomation(fileURL: directory.appendingPathComponent("state.json"))
        let second = await reloaded.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(60))
        XCTAssertEqual(second.status, .alreadyRedeemed)
        let writes = await client.calls.filter { $0.hasPrefix("card-soon:") }
        XCTAssertEqual(writes.count, 2)
        XCTAssertEqual(writes.first, writes.last)
    }
    func testMissingCreditAfterUnknownOutcomeDoesNotConsumeAnotherCard() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        await client.failOnce()
        _ = await store.setEnabled(true, account: "A")
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        await client.replaceCredits([credit("other", expires: now.addingTimeInterval(1000))])
        let second = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(60))
        XCTAssertEqual(second.status, .verificationRequired)
        let calls = await client.calls
        XCTAssertFalse(calls.contains { $0.hasPrefix("other:") })
    }
    func testAccountMismatchInvalidDatesDuplicateIDsAndExpiredCardsNeverConsume() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        await client.setAccount("B")
        let mismatch = await store.tick(account: "A", token: nil, client: client, now: now)
        XCTAssertEqual(mismatch.status, .unavailable)
        await client.setAccount("A")
        for credits in [[credit("expired", expires: now)], [credit("later", expires: now.addingTimeInterval(3601))],
                        [credit("duplicate", expires: now.addingTimeInterval(100)), credit("duplicate", expires: now.addingTimeInterval(200))],
                        [credit("unknown", expires: nil)], [CodexAppServerResetCredit(id: "wrong-type", resetType: "other", status: "available", expiresAt: now.addingTimeInterval(100))], [CodexAppServerResetCredit(id: "used", status: "used", expiresAt: now.addingTimeInterval(100))]] {
            await client.replaceCredits(credits)
            _ = await store.tick(account: "A", token: nil, client: client, now: now)
        }
        let calls = await client.calls
        XCTAssertFalse(calls.contains { $0.contains(":") })
    }
    func testUnwritableOrCorruptStateNeverConsumes() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let empty = await store.status(account: "A")
        XCTAssertEqual(empty.status, .off, "A missing ledger is a new installation, not a read error")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("corrupt".utf8).write(to: directory.appendingPathComponent("state.json"))
        let broken = ResetCreditAutomation(fileURL: directory.appendingPathComponent("state.json"))
        let status = await broken.status(account: "A")
        XCTAssertEqual(status.status, .storageFailed, "An unreadable ledger must not claim consent was turned off")
        let before = try Data(contentsOf: directory.appendingPathComponent("state.json"))
        _ = await broken.tick(account: "A", token: nil, client: client, now: now)
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("state.json")), before)
        let calls = await client.calls
        XCTAssertEqual(calls, [])
        let bad = ResetCreditAutomation(fileURL: URL(fileURLWithPath: "/dev/null/reset-state"))
        let enabled = await bad.setEnabled(true, account: "A")
        XCTAssertFalse(enabled)
    }
    func testDisableDuringReadAndOverlappingChecksCannotSendRedemption() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let started = expectation(description: "preflight read started")
        await client.blockNextRead { started.fulfill() }
        _ = await store.setEnabled(true, account: "A")
        let clock = now
        let first = Task { await store.tick(account: "A", token: nil, client: client, now: clock) }
        await fulfillment(of: [started], timeout: 2)
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        _ = await store.setEnabled(false, account: "A")
        await client.finishRead()
        let result = await first.value
        XCTAssertFalse(result.enabled)
        let calls = await client.calls
        XCTAssertEqual(calls, ["read"])
    }

    func testNoEligibleWindowKeepsOneRequestAndExpiryIsNotAnUnknownSuccess() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        await client.setOutcome(.nothingToReset)
        _ = await store.setEnabled(true, account: "A")
        let first = await store.tick(account: "A", token: nil, client: client, now: now)
        let second = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(60))
        XCTAssertEqual(first.status, .nothingToReset)
        XCTAssertEqual(second.status, .nothingToReset)
        let writes = await client.calls.filter { $0.hasPrefix("card-soon:") }
        XCTAssertEqual(writes.count, 2)
        XCTAssertEqual(writes.first, writes.last)
        let expired = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(3601))
        XCTAssertEqual(expired.status, .expired)
    }

    private func fixture() -> (ResetCreditAutomation, ResetCreditMock, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (ResetCreditAutomation(fileURL: directory.appendingPathComponent("state.json")),
                ResetCreditMock(credits: [credit("card-later", expires: now.addingTimeInterval(7200)), credit("card-soon", expires: now.addingTimeInterval(3600))]), directory)
    }
    private func credit(_ id: String, expires: Date?) -> CodexAppServerResetCredit {
        CodexAppServerResetCredit(id: id, resetType: "codexRateLimits", status: "available", expiresAt: expires)
    }
}

private actor ResetCreditMock: ResetCreditServicing {
    var calls: [String] = []
    var credits: [CodexAppServerResetCredit]
    var account = "A"
    var shouldFail = false
    var didFail = false
    var outcome: ResetCreditOutcome?
    func setOutcome(_ value: ResetCreditOutcome) { outcome = value }
    var onRead: (@Sendable () -> Void)?
    var readGate: CheckedContinuation<Void, Never>?
    func blockNextRead(_ onRead: @escaping @Sendable () -> Void) { self.onRead = onRead }
    func finishRead() { readGate?.resume(); readGate = nil }
    init(credits: [CodexAppServerResetCredit]) { self.credits = credits }
    func failOnce() { shouldFail = true }
    func setAccount(_ value: String) { account = value }
    func replaceCredits(_ value: [CodexAppServerResetCredit]) { credits = value }
    func read(account: String, token: CodexOAuthToken?) async throws -> CodexAppServerAccountSnapshot {
        calls.append("read")
        if let onRead {
            self.onRead = nil
            await withCheckedContinuation { readGate = $0; onRead() }
        }
        return CodexAppServerAccountSnapshot(accountID: self.account, email: nil, planName: nil, rateLimits: [], resetCredits: credits, resetCreditDetailsAvailable: true, tokenUsage: nil)
    }
    func consume(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit, idempotencyKey: String, authorization: ResetCreditAuthorization) async throws -> ResetCreditOutcome {
        calls.append("\(credit.id!):\(idempotencyKey)")
        if shouldFail && !didFail { didFail = true; throw URLError(.timedOut) }
        return outcome ?? (didFail ? .alreadyRedeemed : .reset)
    }
}

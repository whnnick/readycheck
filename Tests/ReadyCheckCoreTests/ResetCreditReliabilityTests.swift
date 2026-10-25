import XCTest
@testable import ReadyCheckCore

final class ResetCreditReliabilityTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_900_000_000)

    func testProtectedLedgerRetainsOpenDescriptorAndDetectsExternalReplacement() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("ledger.json")
        try Data("original".utf8).write(to: url)
        var denyReopen = false
        let file = ResetCreditLedgerFile(url: url, openExisting: { url in
            if denyReopen { throw CocoaError(.fileReadNoPermission) }
            return try FileHandle(forReadingFrom: url)
        })
        XCTAssertEqual(try file.read(), Data("original".utf8))
        denyReopen = true
        XCTAssertEqual(try file.read(), Data("original".utf8), "Already-open protected files need no reopen")
        try file.write(Data("atomic".utf8))
        XCTAssertEqual(try file.read(), Data("atomic".utf8), "Keep the newly saved protected descriptor open too")
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual(attributes[.posixPermissions] as? Int, 0o600)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .completeUnlessOpen)
        try Data("external-revocation".utf8).write(to: url, options: .atomic)
        XCTAssertThrowsError(try file.read(), "Do not reuse stale consent when another process replaces the ledger")
    }

    func testMissingObservedCardPersistsAsUnconfirmedAndNeverSuccess() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        await client.setCards([])
        _ = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(8000))
        let reloaded = ResetCreditAutomation(fileURL: directory.appendingPathComponent("ledger.json"))
        let records = try await reloaded.records(account: "A")
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.status, .disappeared, "Even after expiry, missing is not a server expiration receipt")
        XCTAssertEqual(records.first?.observedOnly, true)
        XCTAssertFalse(records.first?.confirmedUsed ?? true)
        let notices = await reloaded.pendingSuccessNotices(account: "A")
        XCTAssertTrue(notices.isEmpty)
        let checks = try await reloaded.checks(account: "A")
        XCTAssertEqual(checks.first?.reason, .cardChanged)
        let calls = await client.consumes
        XCTAssertEqual(calls, 0)
    }

    func testServerConsumedObservationIsSeparateFromLocalAutomaticSuccess() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        await client.setCards([card(status: "consumed")])
        _ = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(60))
        let records = try await store.records(account: "A")
        XCTAssertEqual(records.first?.status, .redeemedElsewhere)
        XCTAssertFalse(records.first?.confirmedUsed ?? true, "This must not claim ReadyCheck performed it")
        let notices = await store.pendingSuccessNotices(account: "A")
        XCTAssertTrue(notices.isEmpty)
        await client.setCards([])
        _ = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(120))
        let retained = try await store.records(account: "A")
        XCTAssertEqual(retained.first?.status, .redeemedElsewhere, "Do not discard an observed service receipt when it leaves the list")
    }

    func testServiceFailureIsDurableCoalescedAndAccountOwned() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = await store.setEnabled(true, account: "A")
        await client.failReads()
        for delta in [0.0, 60, 120] { _ = await store.tick(account: "A", token: nil, client: client, now: now.addingTimeInterval(delta)) }
        let reloaded = ResetCreditAutomation(fileURL: directory.appendingPathComponent("ledger.json"))
        let checks = try await reloaded.checks(account: "A")
        XCTAssertEqual(checks.count, 1)
        XCTAssertEqual(checks.first?.reason, .serviceUnavailable)
        XCTAssertEqual(checks.first?.count, 3)
        let other = try await reloaded.checks(account: "B")
        XCTAssertTrue(other.isEmpty)
    }

    func testCorruptLedgerWritesOnlyDiagnosticAndCannotAuthorize() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("ledger.json")
        try Data("unreadable".utf8).write(to: url)
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        let checks = try await store.checks(account: "A")
        XCTAssertEqual(checks.first?.reason, .ledgerUnavailable)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "unreadable")
        let consumes = await client.consumes
        XCTAssertEqual(consumes, 0)
        try Data().write(to: url)
        let empty = await store.status(account: "A")
        XCTAssertEqual(empty.status, .storageFailed, "An empty existing ledger is corrupt, not a new consent state")
    }

    func testReadFailureStreakDoesNotSpanSleepOrClockReversal() async throws {
        let (store, _, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        for delta in [0.0, 60, 600] { _ = await store.recordCheck(.serviceUnavailable, account: "A", now: now.addingTimeInterval(delta)) }
        var checks = try await store.checks(account: "A")
        XCTAssertEqual(checks.count, 2)
        XCTAssertEqual(checks.first?.count, 1)
        _ = await store.recordCheck(.serviceUnavailable, account: "A", now: now.addingTimeInterval(590))
        checks = try await store.checks(account: "A")
        XCTAssertEqual(checks.count, 3)
    }

    func testEveryPreparedRequestIsSavedBeforeConsumeAndSurvivesRestart() async throws {
        let (store, client, directory) = fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        await client.setCards([CodexAppServerResetCredit(id: "card", resetType: "codexRateLimits", status: "available", expiresAt: now.addingTimeInterval(1000))])
        await client.setLedgerURL(directory.appendingPathComponent("ledger.json"))
        _ = await store.setEnabled(true, account: "A")
        _ = await store.tick(account: "A", token: nil, client: client, now: now)
        let savedBeforeConsume = await client.savedBeforeConsume
        XCTAssertTrue(savedBeforeConsume)
        let records = try await ResetCreditAutomation(fileURL: directory.appendingPathComponent("ledger.json")).records(account: "A")
        XCTAssertEqual(records.first?.startedAt, now)
        XCTAssertEqual(records.first?.requestCount, 1)
        XCTAssertEqual(records.first?.status, .reset)
    }

    func testExpiryReminderBackfillIsAccountBoundAndDoesNotCreateRedemption() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var state = QuotaReminderState()
        var own = QuotaReminderHistoryRecord(id: "own", kind: .manualResetExpiring, status: .delivered, expiresAt: now.addingTimeInterval(-100))
        own.accountKey = QuotaHistorySample.key(for: "A")
        var other = own; other.accountKey = QuotaHistorySample.key(for: "B"); other.expiresAt = now.addingTimeInterval(-200)
        var legacy = own; legacy.accountKey = nil; legacy.expiresAt = now.addingTimeInterval(-300)
        state.notificationHistory = [own, other, legacy]
        let url = directory.appendingPathComponent("reminders.json")
        try JSONEncoder().encode(state).write(to: url)
        let dates = await QuotaReminderStore(fileURL: url).pastResetReminderExpirations(account: "A", now: now)
        XCTAssertEqual(dates, [own.expiresAt!], "Legacy unowned reminders cannot be assigned to the current account")
    }

    private func card(status: String = "available") -> CodexAppServerResetCredit {
        CodexAppServerResetCredit(id: "card", resetType: "codexRateLimits", status: status, expiresAt: now.addingTimeInterval(7200))
    }
    private func fixture() -> (ResetCreditAutomation, ReliabilityClient, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (ResetCreditAutomation(fileURL: directory.appendingPathComponent("ledger.json")), ReliabilityClient(cards: [card()]), directory)
    }
}

private actor ReliabilityClient: ResetCreditServicing {
    var cards: [CodexAppServerResetCredit]
    var consumes = 0
    var shouldFail = false
    var ledgerURL: URL?
    var savedBeforeConsume = false
    init(cards: [CodexAppServerResetCredit]) { self.cards = cards }
    func setCards(_ cards: [CodexAppServerResetCredit]) { self.cards = cards }
    func failReads() { shouldFail = true }
    func setLedgerURL(_ url: URL) { ledgerURL = url }
    func read(account: String, token: CodexOAuthToken?) async throws -> CodexAppServerAccountSnapshot {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return CodexAppServerAccountSnapshot(accountID: account, email: nil, planName: nil, rateLimits: [], resetCredits: cards, resetCreditDetailsAvailable: true, tokenUsage: nil)
    }
    func consume(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit, idempotencyKey: String, authorization: ResetCreditAuthorization) async throws -> ResetCreditOutcome {
        consumes += 1
        if let ledgerURL, let data = try? Data(contentsOf: ledgerURL),
           let state = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let row = (state["attempts"] as? [[String: Any]])?.first {
            savedBeforeConsume = row["key"] as? String == idempotencyKey && row["requestCount"] as? Int == 1
        }
        return .reset
    }
}

import XCTest
@testable import ReadyCheckCore

final class NextEventsTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_900_000_000)
    func snapshot(cardsVerified: Bool = true, cached: Bool = false, count: Int? = 2, expirations: [Date]? = nil, resetOffset: Double = 7200) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available, source: .appServer,
            refreshedAt: now, staleAfter: now.addingTimeInterval(300), windows: [QuotaWindow(id: "short", labelKey: "quota.window.codex.5h", kind: .rolling,
                used: 66, limit: 100, remaining: 34, unit: .percent, resetAt: now.addingTimeInterval(resetOffset), confidence: .verified, durationMinutes: 300)], errors: [],
            details: ProviderQuotaDetails(manualResetCount: count, manualResetExpirations: expirations ?? [now.addingTimeInterval(9600), now.addingTimeInterval(700000)], manualResetDetailsReadAt: cardsVerified ? now : nil), ordinaryUsageAllowed: true, accountID: "A", isCached: cached)
    }
    func events(_ snapshot: ProviderQuotaSnapshot?, enabled: Bool = true, records: [ResetCreditExecutionRecord] = []) -> [ReadyCheckNextEvent] {
        ReadyCheckNextEvent.evaluate(snapshot: snapshot, automation: .init(enabled: enabled, status: enabled ? .waiting : .off, updatedAt: nil), records: records, historyUnavailable: false, now: now)
    }
    func testAuthorizedWaitsConditionallyAndOffOpensRulesWithoutChangingConsent() {
        let on = events(snapshot())
        XCTAssertEqual(on.count, 2)
        XCTAssertEqual(on.first?.kind, .cardWindow)
        XCTAssertEqual(on.first?.date, now.addingTimeInterval(6000))
        XCTAssertEqual(on.first?.action, .card(now.addingTimeInterval(9600)))
        let off = events(snapshot(), enabled: false)
        XCTAssertEqual(off.first?.kind, .automationOff)
        XCTAssertEqual(off.first?.action, .rules)
    }

    func testCardCheckFailureDoesNotDirectHealthyQuotaToLogin() {
        let result = ReadyCheckNextEvent.evaluate(snapshot: snapshot(), automation: .init(enabled: true, status: .unavailable, updatedAt: nil),
            records: [], historyUnavailable: false, now: now)
        XCTAssertEqual(result.first?.action, .rules)
        XCTAssertEqual(result.first?.detailKey, "next.cardCheckUnavailable.detail")
        XCTAssertTrue(result.contains { $0.kind == .naturalReset })
        let cards = events(snapshot(cardsVerified: false))
        XCTAssertEqual(cards.first?.action, .rules)
        XCTAssertEqual(cards.first?.detailKey, "next.cardDetailsUnknown.detail")
        let credentials = ReadyCheckNextEvent.evaluate(snapshot: snapshot(), automation: .init(enabled: true, status: .unavailable, updatedAt: nil),
            records: [], historyUnavailable: false, now: now, latestCheckReason: .credentialsUnavailable)
        XCTAssertEqual(credentials.first?.action, .connection)
        let ledger = ReadyCheckNextEvent.evaluate(snapshot: snapshot(), automation: .init(enabled: true, status: .storageFailed, updatedAt: nil),
            records: [], historyUnavailable: false, now: now)
        XCTAssertEqual(ledger.first?.kind, .cardHistoryUnavailable)
        for language in [AppLanguage.zhCN, .enUS] {
            let localization = LocalizationService(language: language)
            for key in ["next.cardCheckUnavailable", "next.cardCheckUnavailable.detail", "next.cardDetailsUnknown", "next.cardDetailsUnknown.detail", "next.cardHistoryUnavailable", "next.cardHistoryUnavailable.detail", "resetCheck.recovered", "resetCheck.serviceWarning"] {
                XCTAssertNotEqual(localization.text(key), key)
            }
        }
    }
    func testUnknownCacheMissingAndPreservedDetailsNeverPromiseAWindow() {
        for value in [snapshot(cached: true), snapshot(cardsVerified: false), snapshot(count: nil, expirations: []), nil] {
            let result = events(value)
            XCTAssertEqual(result.first?.kind, value == nil || value?.isCached == true ? .conditionsUnknown : .cardDetailsUnknown)
            XCTAssertFalse(result.contains { $0.kind == .cardWindow })
        }
        let old = ProviderQuotaDetails(manualResetCount: 2, manualResetExpirations: [now.addingTimeInterval(9600)], manualResetDetailsReadAt: now.addingTimeInterval(-901))
        let merged = ProviderQuotaDetails().preservingSupplementalDetails(from: old, now: now)
        XCTAssertEqual(merged.manualResetExpirations, old.manualResetExpirations)
        XCTAssertEqual(merged.manualResetDetailsReadAt, old.manualResetDetailsReadAt)
        XCTAssertFalse(merged.hasCurrentManualResetDetails(now: now))
    }
    func testNoCardOrDistantCardLeavesOnlyResetAndClockDoesNotConfirmRecovery() {
        XCTAssertEqual(events(snapshot(count: 0, expirations: [])).map(\.kind), [.naturalReset])
        XCTAssertEqual(events(snapshot(count: 1, expirations: [now.addingTimeInterval(700000)])).map(\.kind), [.naturalReset])
        XCTAssertEqual(events(snapshot(count: 0, expirations: [], resetOffset: -1)).first?.kind, .awaitingResetReading)
    }
    func testConfirmedUseAndNotificationPendingAreIndependentOfFutureAuthorization() {
        let record = ResetCreditExecutionRecord(id: "request-A", expiresAt: now.addingTimeInterval(-100), status: .reset, updatedAt: now.addingTimeInterval(-200), successNotificationPending: true)
        for enabled in [true, false] {
            let result = events(snapshot(), enabled: enabled, records: [record])
            XCTAssertEqual(result.first?.kind, .notificationPending)
            XCTAssertEqual(result.first?.action, .record("request-A"))
            XCTAssertLessThanOrEqual(result.count, 2)
        }
        let matched = QuotaReminderHistoryRecord(id: "reset-used:request-A", kind: .resetCreditUsed, status: .delivered)
        let other = QuotaReminderHistoryRecord(id: "reset-used:request-B", kind: .resetCreditUsed, status: .delivered)
        XCTAssertEqual(record.notificationState(history: [other]), .pending)
        XCTAssertEqual(record.notificationState(history: [matched]), .delivered)
    }
    func testTimePriorityZeroAndPartialDetailsAndOldDecode() throws {
        XCTAssertEqual(events(snapshot(resetOffset: 300)).first?.kind, .naturalReset)
        XCTAssertEqual(events(snapshot(count: 0)).map(\.kind), [.naturalReset], "An explicit zero overrides retained dates")
        XCTAssertEqual(events(snapshot(count: 3)).first?.kind, .cardDetailsUnknown, "Partial dates cannot identify the earliest of missing cards")
        let recent = ProviderQuotaDetails(manualResetCount: 1, manualResetExpirations: [now.addingTimeInterval(3600)], manualResetDetailsReadAt: now.addingTimeInterval(-120))
        let retained = ProviderQuotaDetails().preservingSupplementalDetails(from: recent, now: now)
        XCTAssertTrue(retained.hasCurrentManualResetDetails(now: now))
        XCTAssertFalse(retained.hasCurrentManualResetDetails(now: now.addingTimeInterval(901)))
        XCTAssertFalse(recent.hasCurrentManualResetDetails(now: now.addingTimeInterval(-180)))
        let old = try JSONDecoder().decode(ProviderQuotaDetails.self, from: Data("{\"manualResetExpirations\":[]}".utf8))
        XCTAssertNil(old.manualResetDetailsReadAt)
        for language in [AppLanguage.zhCN, .enUS] {
            let l = LocalizationService(language: language)
            for key in ["next.title", "next.cardWindow.detail", "card.notice.pending", "card.unrecorded", "card.legacyTitle", "card.historyIncomplete", "card.legacyOutcome", "card.legacyNotice", "card.legacyReadOnly"] { XCTAssertNotEqual(l.text(key), key) }
        }
    }

    func testLegacyUnknownNoticeAndReadOnlyAccountHistoryKeepBytes() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("old.json")
        let bytes = try JSONSerialization.data(withJSONObject: ["attempts": [["accountKey": QuotaHistorySample.key(for: "A")!, "creditID": "fixture", "expiresAt": now.timeIntervalSinceReferenceDate, "key": "request-A", "status": "reset", "updatedAt": now.timeIntervalSinceReferenceDate]]])
        try bytes.write(to: file)
        let store = ResetCreditAutomation(fileURL: file)
        let a = try await store.records(account: "A")
        let b = try await store.records(account: "B")
        XCTAssertEqual(a.count, 1); XCTAssertTrue(b.isEmpty)
        XCTAssertNil(a.first?.successNotificationPending)
        XCTAssertEqual(a.first?.notificationState(history: []), .unrecorded)
        XCTAssertEqual(try Data(contentsOf: file), bytes, "Opening details must not migrate, notify or redeem")
        try Data("broken".utf8).write(to: file)
        do { _ = try await store.records(account: "A"); XCTFail("Corrupt history is not an empty successful history") } catch {}
    }
    func testUnconfirmedOutcomeTakesPriorityAndNeverOffersRedemptionRetry() {
        let pending = ResetCreditExecutionRecord(id: "uncertain", expiresAt: now.addingTimeInterval(100), status: .verificationRequired, updatedAt: now, successNotificationPending: nil)
        XCTAssertEqual(events(snapshot(), records: [pending]).first?.kind, .cardResultUnconfirmed)
        XCTAssertEqual(events(snapshot(), records: [pending]).first?.action, .record("uncertain"))
    }

    func testHistoricalExpiryReminderDoesNotBecomeCurrentFailure() {
        let history = ResetCreditExecutionRecord(id: "old-reminder", expiresAt: now.addingTimeInterval(-3600),
            status: .unrecorded, updatedAt: now, successNotificationPending: nil, observedOnly: true, reminderOnly: true)
        XCTAssertEqual(events(snapshot(count: 0, expirations: []), records: [history]).map(\.kind), [.naturalReset])
        XCTAssertEqual(events(snapshot(), records: [history]).map(\.kind), [.cardWindow, .naturalReset])
        XCTAssertEqual(events(snapshot(cached: true), records: [history]).first?.kind, .conditionsUnknown)
    }

    func testHistoricalReminderDoesNotHideRealIssuesOrSuccessNotification() {
        let history = ResetCreditExecutionRecord(id: "old-reminder", expiresAt: now.addingTimeInterval(-3600),
            status: .unrecorded, updatedAt: now, successNotificationPending: nil, observedOnly: true, reminderOnly: true)
        for status: ResetCreditAutomationStatus.Status in [.pending, .verificationRequired, .storageFailed, .disappeared, .missed, .unrecorded] {
            let actual = ResetCreditExecutionRecord(id: "actual-\(status.rawValue)", expiresAt: now,
                status: status, updatedAt: now.addingTimeInterval(-60), successNotificationPending: nil)
            let result = events(snapshot(), records: [history, actual])
            XCTAssertEqual(result.first?.kind, .cardResultUnconfirmed)
            XCTAssertEqual(result.first?.action, .record(actual.id))
        }
        let confirmed = ResetCreditExecutionRecord(id: "actual-success", expiresAt: now, status: .reset,
            updatedAt: now.addingTimeInterval(-60), successNotificationPending: true)
        XCTAssertEqual(events(snapshot(), records: [history, confirmed]).first?.kind, .notificationPending)
    }
}

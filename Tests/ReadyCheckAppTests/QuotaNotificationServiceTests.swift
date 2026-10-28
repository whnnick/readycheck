import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class QuotaNotificationServiceTests: XCTestCase {
    func testEveryNotificationEntryPointIncludesLocalizedSubmissionDateAndTime() async {
        for language: AppLanguage in [.zhCN, .enUS] {
            let store = makeReminderStore()
            let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
            let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
            let localization = LocalizationService(language: language)
            let before = Date()
            _ = await store.setAutomaticRecoveryEnabled(true)
            let recovery = QuotaRecoveryRequest(id: "timestamp-recovery", account: "fixture",
                snapshot: expirySnapshot(expiry: before.addingTimeInterval(3600), now: before))
            _ = await store.setRecoveryRequest(recovery)
            _ = await service.sendTestNotification(localization: localization)
            _ = await service.deliver([.creditsStarted, .quotaRecovered(requestID: recovery.id),
                .manualResetExpiring(index: 1, expiresAt: before.addingTimeInterval(3600), leadHours: 12)],
                localization: localization, reminderStore: store)
            let (lowStore, _, alert) = await prepareLowQuotaAlert()
            _ = await service.deliver([.quotaLow(alert)], localization: localization, reminderStore: lowStore)
            _ = await service.deliverResetCreditSuccess(.init(id: "timestamp-fixture", expiresAt: before.addingTimeInterval(3600)),
                localization: localization, reminderStore: store)
            _ = await service.deliverResetCreditCheckWarning(.init(id: "timestamp-warning", accountKey: "fixture", reason: .credentialsUnavailable,
                firstAt: before.addingTimeInterval(-3600), lastAt: before, count: 1, warningSubmitted: false), localization: localization)
            let after = Date()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: language.rawValue)
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let prefix = language == .zhCN ? "发送于 " : "Sent at "
            let expected = Set([before, after].map { prefix + formatter.string(from: $0) })
            XCTAssertEqual(client.addedRequests.count, 7)
            for request in client.addedRequests {
                XCTAssertTrue(expected.contains(request.content.subtitle), "Missing submission time: \(request.identifier)")
                XCTAssertFalse(request.content.body.isEmpty, "Timestamp must not replace notification content")
            }
        }
    }

    func testDeselectedExpiryNodeIsNotSubmittedFromAnOlderBatch() async {
        let store = makeReminderStore()
        let now = Date()
        let batch = await store.prepare(expirySnapshot(expiry: now.addingTimeInterval(40 * 3600), now: now), now: now)
        _ = await store.setResetExpiryLeadHours([12])
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let delivered = await service.deliver(batch.events, localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertTrue(delivered.isEmpty)
        XCTAssertTrue(client.addedRequests.isEmpty)
    }

    func testAcceptedExpiryIsNotRepeatedWhenDeliveryCannotBeVerifiedOrAfterRestart() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("reminders.json")
        let store = QuotaReminderStore(fileURL: file)
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded())
        let expiry = now.addingTimeInterval(40 * 3600)
        let snapshot = expirySnapshot(expiry: expiry, now: now)
        let first = await store.prepare(snapshot, now: now)
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let verified = await service.deliver(first.events, localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertTrue(verified.isEmpty, "OS acceptance must not claim Notification Center verification")
        await store.commit(first, deliveredEvents: verified, now: now)
        let reloaded = QuotaReminderStore(fileURL: file)
        let next = await reloaded.prepare(snapshot, now: now.addingTimeInterval(60))
        XCTAssertTrue(next.events.isEmpty, "Accepted48-hour reminder must not be queued every minute")
        let other = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        let restarted = QuotaNotificationService(client: other, verificationDelays: [.zero])
        _ = await restarted.deliver(first.events, localization: LocalizationService(language: .enUS), reminderStore: reloaded)
        XCTAssertTrue(other.addedRequests.isEmpty, "Dismissal or restart cannot re-submit the same node")
        let history = await reloaded.history()
        XCTAssertEqual(history.first?.submissionAccepted, true)
        XCTAssertNil(history.first?.deliveredAt)
        XCTAssertEqual(history.first?.attemptCount, 1)
        let later = await reloaded.prepare(snapshot, now: expiry.addingTimeInterval(-23 * 3600))
        XCTAssertEqual(later.events, [.manualResetExpiring(index: 1, expiresAt: expiry, leadHours: 24)])
    }

    func testExistingExpiryInNotificationCenterIsNotAddedAgain() async {
        let expiry = Date().addingTimeInterval(40 * 3600)
        let event = QuotaReminderEvent.manualResetExpiring(index: 1, expiresAt: expiry, leadHours: 48)
        let id = "readycheck.reset-expiry.\(Int64(expiry.timeIntervalSince1970.rounded())).48"
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[id]])
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let verified = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: makeReminderStore())
        XCTAssertEqual(verified, [event])
        XCTAssertTrue(client.addedRequests.isEmpty)
    }

    func testExplicitExpirySubmissionFailureCanRetryWithoutSuppressingTheNode() async {
        let store = makeReminderStore()
        let now = Date()
        let snapshot = expirySnapshot(expiry: now.addingTimeInterval(40 * 3600), now: now)
        let first = await store.prepare(snapshot, now: now)
        let failing = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        failing.rejectAdds = true
        let failed = await QuotaNotificationService(client: failing, verificationDelays: [.zero]).deliver(first.events, localization: LocalizationService(language: .enUS), reminderStore: store)
        await store.commit(first, deliveredEvents: failed, now: now)
        let retry = await store.prepare(snapshot, now: now.addingTimeInterval(60))
        XCTAssertEqual(retry.events, first.events)
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let verified = await QuotaNotificationService(client: client, verificationDelays: [.zero]).deliver(retry.events, localization: LocalizationService(language: .enUS), reminderStore: store)
        await store.commit(retry, deliveredEvents: verified)
        let history = await store.history()
        XCTAssertEqual(history.first?.status, .delivered)
        XCTAssertEqual(history.first?.attemptCount, 2)
    }

    func testOverlappingExpiryDeliverySubmitsOnlyOneRequest() async {
        let store = makeReminderStore()
        let event = QuotaReminderEvent.manualResetExpiring(index: 1, expiresAt: Date().addingTimeInterval(40 * 3600), leadHours: 48)
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        async let first = service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        async let second = service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        _ = await (first, second)
        XCTAssertEqual(client.addedRequests.count, 1)
    }

    func testVerifiedOldExpiryHistorySuppressesResendWhenThresholdMarkerWasLost() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("reminders.json")
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded())
        let expiry = now.addingTimeInterval(40 * 3600)
        let snapshot = expirySnapshot(expiry: expiry, now: now)
        let store = QuotaReminderStore(fileURL: file)
        let first = await store.prepare(snapshot, now: now)
        await store.commit(first, deliveredEvents: first.events, now: now)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        legacy["notifiedManualResetThresholds"] = []
        try JSONSerialization.data(withJSONObject: legacy).write(to: file)
        let reloaded = QuotaReminderStore(fileURL: file)
        let pending = await reloaded.prepare(snapshot, now: now.addingTimeInterval(60))
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let delivered = await service.deliver(pending.events, localization: LocalizationService(language: .enUS), reminderStore: reloaded)
        await reloaded.commit(pending, deliveredEvents: delivered, now: now.addingTimeInterval(60))
        XCTAssertTrue(client.addedRequests.isEmpty)
        let history = await reloaded.history()
        XCTAssertEqual(history.first?.status, .delivered)
        XCTAssertEqual(history.first?.attemptCount, 1)
        let next = await reloaded.prepare(snapshot, now: now.addingTimeInterval(120))
        XCTAssertTrue(next.events.isEmpty)
    }

    private func expirySnapshot(expiry: Date, now: Date) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available, source: .appServer,
            refreshedAt: now, staleAfter: expiry, windows: [], errors: [],
            details: ProviderQuotaDetails(manualResetCount: 1, manualResetExpirations: [expiry]))
    }

    func testExpiryReceiptsStayAccountScopedEvenWhenExpirationMatches() async {
        let store = makeReminderStore()
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let event = QuotaReminderEvent.manualResetExpiring(index: 1, expiresAt: Date().addingTimeInterval(40 * 3600), leadHours: 48)
        await store.updateDetailsAccount("A")
        _ = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        await store.updateDetailsAccount("B")
        _ = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertEqual(client.addedRequests.count, 2)
        XCTAssertNotEqual(client.addedRequests[0].identifier, client.addedRequests[1].identifier)
        await store.updateDetailsAccount("A")
        _ = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertEqual(client.addedRequests.count, 2)
    }

    func testTemporaryUnknownAccountKeepsLegacyExpiryDeduplicationButSwitchClearsIt() async {
        let store = makeReminderStore()
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded())
        let snapshot = expirySnapshot(expiry: now.addingTimeInterval(40 * 3600), now: now)
        await store.updateDetailsAccount("A")
        let batch = await store.prepare(snapshot, now: now)
        await store.commit(batch, deliveredEvents: batch.events, now: now)
        await store.updateDetailsAccount(nil)
        let known = await store.knownManualResetExpirations(now: now)
        XCTAssertTrue(known.isEmpty, "Unknown account must not expose old account details")
        await store.updateDetailsAccount("A")
        let restored = await store.prepare(snapshot, now: now)
        XCTAssertTrue(restored.events.isEmpty, "Keychain retry/restart cannot rearm a previously reminded node")
        await store.updateDetailsAccount(nil)
        await store.updateDetailsAccount("B")
        let other = await store.prepare(snapshot, now: now)
        XCTAssertFalse(other.events.isEmpty)
    }

    func testResetSuccessWithDeniedPermissionRemainsUndeliveredWithoutClaimingSuccess() async {
        let store = makeReminderStore()
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        client.authorizationStatus = .denied
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let result = await service.deliverResetCreditSuccess(ResetCreditSuccessNotice(id: "denied", expiresAt: Date()),
            localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertFalse(result)
        XCTAssertTrue(client.addedRequests.isEmpty)
        let records = await store.history()
        XCTAssertEqual(records.first?.status, .failed)
    }

    func testResetSuccessNotifiesWithExpiryOffAndHistoryDeduplicatesAfterDismissal() async throws {
        let store = makeReminderStore()
        _ = await store.setResetExpiryReminderEnabled(false)
        _ = await store.setAutomaticRecoveryEnabled(false)
        let notice = ResetCreditSuccessNotice(id: "fixture-request", expiresAt: Date(timeIntervalSince1970: 1_900_000_000))
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let sent = await service.deliverResetCreditSuccess(notice, localization: LocalizationService(language: .zhCN), reminderStore: store)
        XCTAssertTrue(sent)
        XCTAssertEqual(client.addedRequests.count, 1)
        XCTAssertEqual(client.addedRequests[0].content.title, "重置卡已自动使用")
        XCTAssertTrue(client.addedRequests[0].content.body.contains("服务端已确认"))
        let dismissedClient = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        let restarted = QuotaNotificationService(client: dismissedClient, verificationDelays: [.zero])
        let deduped = await restarted.deliverResetCreditSuccess(notice, localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertTrue(deduped)
        XCTAssertTrue(dismissedClient.addedRequests.isEmpty)
        let records = await store.history()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].kind, .resetCreditUsed)
        XCTAssertEqual(records[0].status, .delivered)
    }

    func testResetSuccessFailedDeliveryRetriesSameNotificationWithoutLosingHistory() async {
        let store = makeReminderStore()
        let notice = ResetCreditSuccessNotice(id: "fixture-retry", expiresAt: Date())
        let failing = FakeNotificationCenterClient(deliveredSnapshots: [[]])
        let first = QuotaNotificationService(client: failing, verificationDelays: [.zero])
        let failed = await first.deliverResetCreditSuccess(notice, localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertFalse(failed)
        let previous = await store.history()
        XCTAssertEqual(previous.first?.status, .failed)
        let working = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let retry = QuotaNotificationService(client: working, verificationDelays: [.zero])
        let delivered = await retry.deliverResetCreditSuccess(notice, localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertTrue(delivered)
        XCTAssertEqual(failing.addedRequests.first?.identifier, working.addedRequests.first?.identifier)
        let records = await store.history()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.attemptCount, 2)
    }
    func testDisabledExpiryRejectsAlreadyPreparedDeliveryWithoutBlockingCredits() async {
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let store = makeReminderStore()
        _ = await store.setResetExpiryReminderEnabled(false)
        let expiry = QuotaReminderEvent.manualResetExpiring(index: 1, expiresAt: Date().addingTimeInterval(3600), leadHours: 12)
        let delivered = await service.deliver([expiry, .creditsStarted], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertEqual(delivered, [.creditsStarted])
        XCTAssertEqual(client.addedRequests.count, 1)
        XCTAssertEqual(client.addedRequests.first?.content.title, LocalizationService(language: .enUS).text("notification.creditsStarted.title"))
    }

    func testExpiryDisabledDuringPermissionCheckDoesNotQueueNotification() async {
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let store = makeReminderStore()
        client.onConfiguration = { _ = await store.setResetExpiryReminderEnabled(false) }
        let event = QuotaReminderEvent.manualResetExpiring(index: 1, expiresAt: Date().addingTimeInterval(3600), leadHours: 12)
        let delivered = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertTrue(delivered.isEmpty)
        XCTAssertTrue(client.addedRequests.isEmpty)
    }

    func testDismissalWaitsUntilNotificationCenterActuallyRemovesRecoveryAlert() async {
        let identifier = "readycheck.recovered.old"
        let client = FakeNotificationCenterClient(
            deliveredSnapshots: [[identifier], [identifier], []]
        )
        let service = QuotaNotificationService(
            client: client,
            verificationDelays: [.zero, .zero]
        )

        let event = QuotaReminderEvent.dismissQuotaRecovered(requestID: "old")
        let delivered = await service.deliver(
            [event],
            localization: LocalizationService(language: .enUS),
            reminderStore: makeReminderStore()
        )

        XCTAssertEqual(delivered, [event])
        XCTAssertEqual(client.removedDeliveredIdentifiers, [identifier])
    }

    func testDismissalRemainsFailedWhileRecoveryAlertIsStillDelivered() async {
        let identifier = "readycheck.recovered.old"
        let client = FakeNotificationCenterClient(
            deliveredSnapshots: [[identifier], [identifier], [identifier]]
        )
        let service = QuotaNotificationService(
            client: client,
            verificationDelays: [.zero, .zero]
        )

        let delivered = await service.deliver(
            [.dismissQuotaRecovered(requestID: "old")],
            localization: LocalizationService(language: .enUS),
            reminderStore: makeReminderStore()
        )

        XCTAssertTrue(delivered.isEmpty)
    }

    func testLowQuotaAlertUsesWindowNameAndVerifiedDelivery() async throws {
        let (store, batch, alert) = await prepareLowQuotaAlert()
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let event = QuotaReminderEvent.quotaLow(alert)
        let delivered = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertEqual(delivered, [event])
        XCTAssertEqual(client.addedRequests.first?.identifier, "readycheck.low-quota.\(alert.id)")
        XCTAssertTrue(client.addedRequests.first?.content.body.contains("Extra window") == true)
        XCTAssertTrue(client.addedRequests.first?.content.body.contains("10%") == true)
        await store.commit(batch, deliveredEvents: delivered)
    }

    func testExistingLowQuotaNotificationDoesNotProduceAnotherBanner() async {
        let (store, _, alert) = await prepareLowQuotaAlert()
        let client = FakeNotificationCenterClient(deliveredSnapshots: [["readycheck.low-quota.\(alert.id)"]])
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let event = QuotaReminderEvent.quotaLow(alert)
        let delivered = await service.deliver([event], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertEqual(delivered, [event])
        XCTAssertTrue(client.addedRequests.isEmpty)
    }

    func testDisabledLowQuotaAlertIsNotSent() async {
        let (store, _, alert) = await prepareLowQuotaAlert()
        _ = await store.setLowQuotaThreshold(0)
        let client = FakeNotificationCenterClient(deliveredSnapshots: [[]], markDeliveredWhenAdded: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let delivered = await service.deliver([.quotaLow(alert)], localization: LocalizationService(language: .enUS), reminderStore: store)
        XCTAssertTrue(delivered.isEmpty)
        XCTAssertTrue(client.addedRequests.isEmpty)
    }

    private func prepareLowQuotaAlert() async -> (QuotaReminderStore, QuotaReminderDeliveryBatch, LowQuotaAlert) {
        let store = makeReminderStore()
        let now = Date()
        func snapshot(_ ratio: Double, date: Date) -> ProviderQuotaSnapshot {
            ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available, source: .appServer, refreshedAt: date, staleAfter: date.addingTimeInterval(60), windows: [QuotaWindow(id: "extra", labelKey: "quota.fiveHour", displayLabel: "Extra window", kind: .rateLimit, used: (1-ratio)*100, limit: 100, remaining: ratio*100, unit: .percent, resetAt: now.addingTimeInterval(3600), confidence: .verified)], errors: [])
        }
        _ = await store.setLowQuotaThreshold(20)
        let baseline = await store.prepare(snapshot(0.40, date: now), now: now, account: "fixture-account")
        await store.commit(baseline, deliveredEvents: [])
        let date = now.addingTimeInterval(1)
        let batch = await store.prepare(snapshot(0.10, date: date), now: date, account: "fixture-account")
        let alerts = batch.events.compactMap { event -> LowQuotaAlert? in
            if case let .quotaLow(alert) = event { return alert }
            return nil
        }
        return (store, batch, alerts[0])
    }

    private func makeReminderStore() -> QuotaReminderStore {
        QuotaReminderStore(
            fileURL: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("reminders.json")
        )
    }
}

@MainActor
private final class FakeNotificationCenterClient: NotificationCenterClient {
    var rejectAdds = false
    var onConfiguration: (@MainActor () async -> Void)?
    var authorizationStatus: UNAuthorizationStatus = .authorized
    private var deliveredSnapshots: [Set<String>]
    private let markDeliveredWhenAdded: Bool
    private var addedIdentifiers: Set<String> = []
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedDeliveredIdentifiers: Set<String> = []

    init(deliveredSnapshots: [Set<String>], markDeliveredWhenAdded: Bool = false) {
        self.deliveredSnapshots = deliveredSnapshots
        self.markDeliveredWhenAdded = markDeliveredWhenAdded
    }

    func configuration() async -> NotificationCenterConfiguration {
        await onConfiguration?()
        return NotificationCenterConfiguration(
            authorizationStatus: authorizationStatus,
            alertSetting: .enabled,
            alertStyle: .alert
        )
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func add(_ request: UNNotificationRequest) async throws {
        if rejectAdds { throw URLError(.cannotConnectToHost) }
        addedRequests.append(request)
        if markDeliveredWhenAdded { addedIdentifiers.insert(request.identifier) }
    }

    func deliveredIdentifiers() async -> Set<String> {
        guard deliveredSnapshots.count > 1 else { return (deliveredSnapshots.first ?? []).union(addedIdentifiers) }
        return deliveredSnapshots.removeFirst().union(addedIdentifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers.formUnion(identifiers)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class QuotaNotificationServiceTests: XCTestCase {
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

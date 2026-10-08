import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class QuotaNotificationServiceTests: XCTestCase {
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
        NotificationCenterConfiguration(
            authorizationStatus: .authorized,
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

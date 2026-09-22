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
    private(set) var removedDeliveredIdentifiers: Set<String> = []

    init(deliveredSnapshots: [Set<String>]) {
        self.deliveredSnapshots = deliveredSnapshots
    }

    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(
            authorizationStatus: .authorized,
            alertSetting: .enabled,
            alertStyle: .alert
        )
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func add(_ request: UNNotificationRequest) async throws {}

    func deliveredIdentifiers() async -> Set<String> {
        guard deliveredSnapshots.count > 1 else { return deliveredSnapshots.first ?? [] }
        return deliveredSnapshots.removeFirst()
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers.formUnion(identifiers)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

import AppKit
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class WidgetVisibilityLifecycleTests: XCTestCase {
    func testExplicitHideRemainsHiddenAfterModelRecreation() throws {
        _ = NSApplication.shared
        let suite = "ReadyCheck.visibility-test." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let snoozeKey = WidgetSnoozePreference.defaultsKey
        let savedSnooze = UserDefaults.standard.object(forKey: snoozeKey)
        defer {
            if let savedSnooze { UserDefaults.standard.set(savedSnooze, forKey: snoozeKey) }
            else { UserDefaults.standard.removeObject(forKey: snoozeKey) }
        }
        WidgetVisibilityPreference.set(true, defaults: defaults)
        let notificationService = QuotaNotificationService(client: VisibilityNotificationClient(), verificationDelays: [])
        let first = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: notificationService, widgetVisibilityDefaults: defaults)
        XCTAssertTrue(first.widgetVisible)
        first.hideFloatingWidget()
        XCTAssertFalse(first.widgetVisible)
        XCTAssertFalse(WidgetVisibilityPreference.value(defaults: defaults))
        let reopened = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: notificationService, widgetVisibilityDefaults: defaults)
        XCTAssertFalse(reopened.widgetVisible)
    }
}

@MainActor
private final class VisibilityNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .authorized, alertSetting: .enabled, alertStyle: .banner)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

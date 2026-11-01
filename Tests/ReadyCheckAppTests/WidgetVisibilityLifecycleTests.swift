import AppKit
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class WidgetVisibilityLifecycleTests: XCTestCase {
    func testNotchDetachmentEnablesCapsuleAndPreservesServiceQuotaAndLayout() throws {
        _ = NSApplication.shared
        let standard = UserDefaults.standard
        let snapshot = standard.dictionaryRepresentation()
        defer {
            let keys = Set(snapshot.keys).union(standard.dictionaryRepresentation().keys).filter { $0.hasPrefix("ReadyCheck.") }
            for key in keys {
                if let value = snapshot[key] { standard.set(value, forKey: key) }
                else { standard.removeObject(forKey: key) }
            }
        }
        let suite = "ReadyCheck.detach-test." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        WidgetVisibilityPreference.set(false, defaults: defaults)
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: QuotaNotificationService(client: VisibilityNotificationClient(), verificationDelays: []),
            widgetVisibilityDefaults: defaults)
        defer { model.hideFloatingWidget(); model.notchStatusVisible = false }
        model.widgetPresentation = .card
        model.notchStatusVisible = true
        model.selectedDeepSeek = true
        model.notchQuotaSelection = .sevenDay
        model.notchShowsBothQuotas = false
        let visible = try XCTUnwrap(NSScreen.main).visibleFrame
        model.detachNotch(at: CGPoint(x: visible.midX, y: visible.midY))
        XCTAssertFalse(model.notchStatusVisible)
        XCTAssertTrue(model.widgetVisible)
        XCTAssertEqual(model.widgetPresentation, .bubble)
        XCTAssertTrue(WidgetVisibilityPreference.value(defaults: defaults))
        XCTAssertTrue(model.selectedDeepSeek)
        XCTAssertEqual(model.notchQuotaSelection, .sevenDay)
        XCTAssertFalse(model.notchShowsBothQuotas)
    }

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

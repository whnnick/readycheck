import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class NotchWindowControllerTests: XCTestCase {
    func testClickHoldAndOutsideDismissKeepBothFramesAttachedAndCloseCleanly() throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.main)
        let gap = CGRect(x: screen.frame.midX - 92.5, y: screen.frame.maxY - 33, width: 185, height: 33)
        let context = NotchWindowController.ScreenContext(screen: screen, notchGap: gap)
        let controller = NotchWindowController(screenContextProvider: { context })
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            quotaNotificationService: QuotaNotificationService(client: NotchNotificationClient(), verificationDelays: []))
        let existing = Set(NSApp.windows.map(\.windowNumber))
        controller.show(model: model)
        defer { controller.close() }
        let panel = try XCTUnwrap(NSApp.windows.first { $0 is QuotaWidgetPanel && !existing.contains($0.windowNumber) })
        let host = try XCTUnwrap(panel.contentViewController as? NSHostingController<NotchStatusView>)
        XCTAssertFalse(host.rootView.isExpanded)
        XCTAssertEqual(panel.frame.maxY, gap.minY + 1)
        host.rootView.onClick()
        XCTAssertTrue(host.rootView.isExpanded)
        XCTAssertEqual(panel.frame.width, 360)
        XCTAssertEqual(panel.frame.maxY, gap.minY + 1)
        controller.show(model: model)
        XCTAssertTrue(host.rootView.isExpanded)
        XCTAssertTrue(panel.canBecomeKey)
        host.rootView.onDismiss()
        XCTAssertFalse(host.rootView.isExpanded)
        XCTAssertFalse(panel.canBecomeKey)
        host.rootView.onClick()
        XCTAssertTrue(host.rootView.isExpanded)
        controller.dismissFromExternalInteraction()
        XCTAssertFalse(host.rootView.isExpanded)
        XCTAssertEqual(panel.frame.width, 185)
        host.rootView.onClick()
        host.rootView.onClick()
        XCTAssertFalse(host.rootView.isExpanded)
        controller.close()
        XCTAssertFalse(panel.isVisible)
        controller.show(model: model)
        let reopened = try XCTUnwrap(NSApp.windows.first {
            $0 is QuotaWidgetPanel && $0.isVisible && !existing.contains($0.windowNumber)
        })
        XCTAssertEqual(reopened.frame.width, 185)
    }
}

@MainActor
private final class NotchNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

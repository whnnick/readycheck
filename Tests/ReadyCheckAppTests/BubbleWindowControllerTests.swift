import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp

@MainActor
final class BubbleWindowControllerTests: XCTestCase {
    func testOpeningMainWindowKeepsPinnedDetailsExpanded() throws {
        try withBubble { _, _, host in
            var opened = false
            host.rootView.model.openMainWindow = { opened = true }
            host.rootView.model.mainWindowPage = .settings
            host.rootView.onTap()

            host.rootView.openMainWindow()

            XCTAssertTrue(opened)
            XCTAssertEqual(host.rootView.model.mainWindowPage, .overview)
            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertTrue(host.rootView.isPinned)
        }
    }

    func testOpeningMainWindowDismissesTemporaryPreview() throws {
        try withBubble { _, _, host in
            var opened = false
            host.rootView.model.openMainWindow = { opened = true }
            host.rootView.onTap()
            host.rootView.onTogglePin()

            host.rootView.openMainWindow()

            XCTAssertTrue(opened)
            XCTAssertFalse(host.rootView.isExpanded)
        }
    }

    func testPinnedDetailsSurviveWindowFocusLoss() throws {
        try withBubble { controller, panel, host in
            host.rootView.onTap()
            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertTrue(host.rootView.isPinned)

            controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertTrue(host.rootView.isPinned)
        }
    }

    func testFocusChangeForAnotherWindowDoesNotDismissPinnedDetails() throws {
        try withBubble { controller, _, host in
            host.rootView.onTap()
            let otherWindow = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
            otherWindow.isReleasedWhenClosed = false
            defer { otherWindow.close() }

            controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: otherWindow))

            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertTrue(host.rootView.isPinned)
        }
    }

    func testUnpinKeepsHoverPreviewAvailable() throws {
        try withBubble { _, panel, host in
            host.rootView.onTap()
            host.rootView.onTogglePin()

            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertFalse(host.rootView.isPinned)
            XCTAssertFalse(panel.canBecomeKey)
        }
    }

    func testPinnedDetailsIgnoreExternalInteractionUntilUnpinned() throws {
        try withBubble { controller, _, host in
            host.rootView.onTap()
            controller.dismissFromExternalInteraction()
            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertTrue(host.rootView.isPinned)

            host.rootView.onTogglePin()
            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertFalse(host.rootView.isPinned)
            controller.dismissFromExternalInteraction()
            XCTAssertFalse(host.rootView.isExpanded)
            XCTAssertFalse(host.rootView.isPinned)
        }
    }

    func testOwnFocusReleaseWhenUnpinningDoesNotDismissHoverPreview() throws {
        try withBubble { controller, panel, host in
            host.rootView.onTap()
            host.rootView.onTogglePin()

            controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertFalse(host.rootView.isPinned)
        }
    }

    private func withBubble(_ body: (BubbleWindowController, QuotaWidgetPanel, NSHostingController<BubbleWidgetView>) throws -> Void) throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        let visibleFrame = try XCTUnwrap(NSScreen.main).visibleFrame
        defaults.set(NSStringFromRect(CGRect(x: visibleFrame.midX - 46, y: visibleFrame.midY - 46,
            width: 92, height: 92)), forKey: key)
        let controller = BubbleWindowController()
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: BubbleTestNotificationClient(), verificationDelays: []))
        let previous = Set(NSApp.windows.map(\.windowNumber))
        defer {
            controller.close()
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        controller.show(model: model)
        let panel = try XCTUnwrap(NSApp.windows.first {
            $0 is QuotaWidgetPanel && !previous.contains($0.windowNumber)
        } as? QuotaWidgetPanel)
        let host = try XCTUnwrap(panel.contentViewController?.children.first as? NSHostingController<BubbleWidgetView>)
        try body(controller, panel, host)
    }
}

@MainActor
private final class BubbleTestNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

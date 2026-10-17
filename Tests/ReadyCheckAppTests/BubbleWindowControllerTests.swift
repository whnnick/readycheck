import AppKit
import SwiftUI
import ReadyCheckCore
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

    func testClickingPreviewPaddingPinsDetailsAtEveryPlacement() throws {
        for edge in [nil, BubbleWidgetPlacement.Edge.left, .right] {
            try withBubble(edge: edge) { controller, panel, host in
                host.rootView.onTap()
                RunLoop.main.run(until: Date().addingTimeInterval(0.4))
                host.rootView.onTogglePin()
                XCTAssertFalse(host.rootView.isPinned)
                try clickPreviewPadding(panel)
                XCTAssertTrue(host.rootView.isExpanded)
                XCTAssertTrue(host.rootView.isPinned, "A click on preview padding must keep details open")
                try clickPreviewPadding(panel)
                controller.dismissFromExternalInteraction()
                XCTAssertTrue(host.rootView.isPinned, "Further background and outside clicks must not unpin")
            }
        }
    }

    func testClickingPreviewBackgroundDuringExpansionPinsDetails() throws {
        for edge in [nil, BubbleWidgetPlacement.Edge.left, .right] {
            try withBubble(edge: edge) { _, panel, host in
                host.rootView.onTap()
                host.rootView.onTogglePin()
                panel.setFrame(CGRect(origin: panel.frame.origin, size: CGSize(width: 180, height: 220)), display: true)
                panel.contentView?.layoutSubtreeIfNeeded()
                try clickPreviewPadding(panel)
                XCTAssertTrue(host.rootView.isExpanded)
                XCTAssertTrue(host.rootView.isPinned)
            }
        }
    }

    private func clickPreviewPadding(_ panel: QuotaWidgetPanel) throws {
        let point = CGPoint(x: 8, y: panel.frame.height / 2)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: point,
                modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: panel.windowNumber, context: nil, eventNumber: 0,
                clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1))
            panel.sendEvent(event)
        }
    }

    func testUnifiedWidgetRestoresAttachedStripAndOpensSharedPinnedDetails() throws {
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            try withBubble(edge: edge) { _, panel, host in
                XCTAssertEqual(host.rootView.tabEdge, edge)
                XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.tabSize)
                host.rootView.onTap()
                XCTAssertTrue(host.rootView.isPinned)
                XCTAssertEqual(host.rootView.tabEdge, edge)
            }
        }
    }

    private func withBubble(edge: BubbleWidgetPlacement.Edge? = nil, _ body: (BubbleWindowController, QuotaWidgetPanel, NSHostingController<BubbleWidgetView>) throws -> Void) throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        let visibleFrame = try XCTUnwrap(NSScreen.main).visibleFrame
        let bubble = CGRect(x: visibleFrame.midX - 46, y: visibleFrame.midY - 46, width: 92, height: 92)
        let frame = edge.map { BubbleWidgetPlacement.tabFrame(from: bubble, edge: $0, in: visibleFrame) } ?? bubble
        defaults.set(NSStringFromRect(frame), forKey: key)
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

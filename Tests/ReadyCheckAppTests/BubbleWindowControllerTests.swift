import AppKit
import SwiftUI
import ReadyCheckCore
import UserNotifications
import XCTest
@testable import ReadyCheckApp

@MainActor
final class BubbleWindowControllerTests: XCTestCase {
    func testDetachedBubbleAppearsAtDropPointAndPersistsInsteadOfReturningToOldEdge() throws {
        try withBubble(edge: .right) { controller, panel, host in
            let screen = try XCTUnwrap(NSScreen.main)
            let point = CGPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY)
            controller.restoreFromNotch(model: host.rootView.model, at: point)
            XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.bubbleSize)
            let pixel = 1 / screen.backingScaleFactor
            XCTAssertEqual(panel.frame.midX, point.x, accuracy: pixel)
            XCTAssertEqual(panel.frame.midY, point.y, accuracy: pixel)
            XCTAssertNil(host.rootView.tabEdge)
            XCTAssertFalse(host.rootView.isExpanded)
            let saved = try XCTUnwrap(UserDefaults.standard.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"))
            let savedFrame = NSRectFromString(saved)
            XCTAssertEqual(savedFrame.midX, panel.frame.midX, accuracy: pixel)
            XCTAssertEqual(savedFrame.midY, panel.frame.midY, accuracy: pixel)
            XCTAssertEqual(savedFrame.size, panel.frame.size)
            controller.restoreFromNotch(model: host.rootView.model, at: CGPoint(x: screen.frame.maxX + 100, y: screen.frame.maxY + 100))
            XCTAssertTrue(screen.visibleFrame.contains(panel.frame))
        }
    }

    func testDropNearNotchAttachesOnReleaseAndPreservesOriginalPosition() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        let gap = CGRect(x: screen.frame.midX - 92.5, y: screen.frame.maxY - 33, width: 185, height: 33)
        try withBubble(notchContext: .init(screen: screen, notchGap: gap)) { controller, panel, _ in
            let bubble = try XCTUnwrap(panel as? BubbleWidgetPanel)
            let original = UserDefaults.standard.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1")
            var attached = false
            controller.onNotchAttachment = { attached = true; controller.close() }
            bubble.onPointerDrag(CGPoint(x: panel.frame.midX, y: panel.frame.midY),
                CGPoint(x: gap.midX, y: gap.minY - 45))
            XCTAssertFalse(attached)
            bubble.onPointerUp(true)
            XCTAssertTrue(attached)
            XCTAssertFalse(panel.isVisible)
            XCTAssertEqual(UserDefaults.standard.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"), original)
        }
    }

    func testDropWithoutPhysicalNotchKeepsCapsule() throws {
        try withBubble { controller, panel, _ in
            let bubble = try XCTUnwrap(panel as? BubbleWidgetPanel)
            var attached = false
            controller.onNotchAttachment = { attached = true }
            bubble.onPointerDrag(CGPoint(x: panel.frame.midX, y: panel.frame.midY),
                CGPoint(x: NSScreen.main!.frame.midX, y: NSScreen.main!.frame.maxY - 45))
            bubble.onPointerUp(true)
            XCTAssertFalse(attached)
            XCTAssertTrue(panel.isVisible)
        }
    }

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

    private func withBubble(edge: BubbleWidgetPlacement.Edge? = nil, notchContext: NotchWindowController.ScreenContext? = nil,
                            _ body: (BubbleWindowController, QuotaWidgetPanel, NSHostingController<BubbleWidgetView>) throws -> Void) throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        let visibleFrame = try XCTUnwrap(NSScreen.main).visibleFrame
        let bubble = CGRect(x: visibleFrame.midX - 46, y: visibleFrame.midY - 46, width: 92, height: 92)
        let frame = edge.map { BubbleWidgetPlacement.tabFrame(from: bubble, edge: $0, in: visibleFrame) } ?? bubble
        defaults.set(NSStringFromRect(frame), forKey: key)
        let controller = BubbleWindowController(notchContextProvider: { notchContext })
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: BubbleTestNotificationClient(), verificationDelays: []))
        let previous = Set(NSApp.windows.map(\.windowNumber))
        defer {
            controller.onNotchAttachment = nil
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

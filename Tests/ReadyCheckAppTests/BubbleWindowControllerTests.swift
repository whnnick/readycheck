import AppKit
import SwiftUI
import ReadyCheckCore
import UserNotifications
import XCTest
@testable import ReadyCheckApp

@MainActor
final class BubbleWindowControllerTests: XCTestCase {
    func testMuseSwitchKeepsTheSavedCenterAndReturnsToTheCodexDial() async throws {
        try await withConnectedBubble { _, panel, host in
            let original = host.rootView.model.selectedService
            defer { host.rootView.model.selectedService = original }
            let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
            host.rootView.model.selectedService = .muse
            RunLoop.main.run(until: Date().addingTimeInterval(0.15))
            XCTAssertEqual(panel.frame.size, CGSize(width: 180, height: 48))
            host.rootView.onTap(); host.rootView.onTogglePin()
            host.rootView.model.selectedService = .codex
            RunLoop.main.run(until: Date().addingTimeInterval(0.4))
            XCTAssertTrue(host.rootView.isPinned)
            host.rootView.onCollapse()
            RunLoop.main.run(until: Date().addingTimeInterval(0.4))
            XCTAssertEqual(panel.frame.size, CGSize(width: 92, height: 92))
            XCTAssertEqual(panel.frame.midX, center.x, accuracy: 1)
            XCTAssertEqual(panel.frame.midY, center.y, accuracy: 1)
        }
    }

    func testServiceSwitchResizesRestingSurfaceAndRetainsPinnedStateAndCenter() async throws {
        try await withConnectedBubble { _, panel, host in
            let model = host.rootView.model
            let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
            XCTAssertEqual(panel.frame.size, CGSize(width: 92, height: 92))
            for balance in [true, false] {
                model.selectedDeepSeek = balance
                RunLoop.main.run(until: Date().addingTimeInterval(0.15))
                XCTAssertEqual(panel.frame.size, balance ? CGSize(width: 180, height: 48) : CGSize(width: 92, height: 92))
                XCTAssertEqual(panel.frame.midX, center.x, accuracy: 1)
                XCTAssertEqual(panel.frame.midY, center.y, accuracy: 1)
            }
            host.rootView.onTap()
            host.rootView.onTogglePin()
            for balance in [true, false] {
                model.selectedDeepSeek = balance
                RunLoop.main.run(until: Date().addingTimeInterval(0.4))
                XCTAssertTrue(host.rootView.isPinned)
                XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.expandedSize)
            }
            host.rootView.onCollapse()
            RunLoop.main.run(until: Date().addingTimeInterval(0.4))
            XCTAssertEqual(panel.frame.size, CGSize(width: 92, height: 92))
            XCTAssertEqual(panel.frame.midX, center.x, accuracy: 1)
            XCTAssertEqual(panel.frame.midY, center.y, accuracy: 1)
        }
    }

    func testServiceSwitchKeepsEitherAttachedEdgeAndExplicitPin() async throws {
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            try await withConnectedBubble(edge: edge) { _, panel, host in
                let resting = panel.frame
                host.rootView.model.selectedDeepSeek = true
                RunLoop.main.run(until: Date().addingTimeInterval(0.15))
                XCTAssertEqual(panel.frame, resting)
                host.rootView.onTap()
                host.rootView.onTogglePin()
                host.rootView.model.selectedDeepSeek = false
                RunLoop.main.run(until: Date().addingTimeInterval(0.4))
                XCTAssertEqual(host.rootView.tabEdge, edge)
                XCTAssertTrue(host.rootView.isPinned)
                host.rootView.onCollapse()
                RunLoop.main.run(until: Date().addingTimeInterval(0.4))
                XCTAssertEqual(panel.frame, resting)
            }
        }
    }

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
            host.rootView.onTogglePin()

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

            host.rootView.openMainWindow()

            XCTAssertTrue(opened)
            XCTAssertFalse(host.rootView.isExpanded)
        }
    }

    func testPinnedDetailsSurviveWindowFocusLoss() throws {
        try withBubble { controller, panel, host in
            host.rootView.onTap()
            host.rootView.onTogglePin()
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
            host.rootView.onTogglePin()
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
            host.rootView.onTogglePin()

            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertFalse(host.rootView.isPinned)
            XCTAssertFalse(panel.canBecomeKey)
        }
    }

    func testPinnedDetailsIgnoreExternalInteractionUntilUnpinned() throws {
        try withBubble { controller, _, host in
            host.rootView.onTap()
            host.rootView.onTogglePin()
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
            host.rootView.onTogglePin()

            controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertFalse(host.rootView.isPinned)
        }
    }

    func testClickingPreviewPaddingNeverPinsEitherServiceAtEveryPlacement() async throws {
        for deepSeek in [false, true] {
        for edge in [nil, BubbleWidgetPlacement.Edge.left, .right] {
            try await withConnectedBubble(edge: edge, deepSeek: deepSeek) { controller, panel, host in
                host.rootView.onTap()
                RunLoop.main.run(until: Date().addingTimeInterval(0.4))
                XCTAssertFalse(host.rootView.isPinned)
                try clickPreviewPadding(panel)
                XCTAssertTrue(host.rootView.isExpanded)
                XCTAssertFalse(host.rootView.isPinned, "Only the pin button may lock details")
                try clickPreviewPadding(panel)
                controller.dismissFromExternalInteraction()
                XCTAssertFalse(host.rootView.isExpanded, "An unpinned preview must still dismiss")
            }
        }
        }
    }

    func testClickingPreviewBackgroundDuringExpansionDoesNotPin() throws {
        for edge in [nil, BubbleWidgetPlacement.Edge.left, .right] {
            try withBubble(edge: edge) { _, panel, host in
                host.rootView.onTap()
                panel.setFrame(CGRect(origin: panel.frame.origin, size: CGSize(width: 180, height: 220)), display: true)
                panel.contentView?.layoutSubtreeIfNeeded()
                try clickPreviewPadding(panel)
                XCTAssertTrue(host.rootView.isExpanded)
                XCTAssertFalse(host.rootView.isPinned)
            }
        }
    }

    func testBothServiceContentClicksStayPreviewAndThePinControlToggles() async throws {
        for deepSeek in [false, true] {
            try await withConnectedBubble(deepSeek: deepSeek) { _, panel, host in
                host.rootView.onTap()
                RunLoop.main.run(until: Date().addingTimeInterval(0.4))
                try click(panel, at: CGPoint(x: panel.frame.width / 2, y: panel.frame.height / 2))
                XCTAssertFalse(host.rootView.isPinned)
                try click(panel, at: CGPoint(x: panel.frame.width - 50, y: panel.frame.height - 30))
                XCTAssertTrue(host.rootView.isPinned, "The shared pin button must be the explicit locking action")
                try click(panel, at: CGPoint(x: panel.frame.width / 2, y: panel.frame.height / 2))
                XCTAssertTrue(host.rootView.isPinned, "Content clicks must not alter an explicit pin")
                try click(panel, at: CGPoint(x: panel.frame.width - 50, y: panel.frame.height - 30))
                XCTAssertFalse(host.rootView.isPinned)
            }
        }
    }

    private func clickPreviewPadding(_ panel: QuotaWidgetPanel) throws {
        try click(panel, at: CGPoint(x: 8, y: panel.frame.height / 2))
    }

    private func click(_ panel: QuotaWidgetPanel, at point: CGPoint) throws {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: point,
                modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: panel.windowNumber, context: nil, eventNumber: 0,
                clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1))
            panel.sendEvent(event)
        }
    }

    func testUnifiedWidgetRestoresAttachedStripAndPinsOnlyWithTheButton() throws {
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            try withBubble(edge: edge) { _, panel, host in
                XCTAssertEqual(host.rootView.tabEdge, edge)
                XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.tabSize)
                host.rootView.onTap()
                XCTAssertFalse(host.rootView.isPinned)
                host.rootView.onTogglePin()
                XCTAssertTrue(host.rootView.isPinned)
                XCTAssertEqual(host.rootView.tabEdge, edge)
            }
        }
    }

    private func withConnectedBubble(edge: BubbleWidgetPlacement.Edge? = nil, deepSeek: Bool = false,
                                     _ body: (BubbleWindowController, QuotaWidgetPanel, NSHostingController<BubbleWidgetView>) throws -> Void) async throws {
        let suite = "connected-bubble-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        defaults.set(true, forKey: "ReadyCheck.muse.enabled.v1")
        let store = InMemoryCredentialStore()
        let balance = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: AggregateBalanceLoader()),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        await balance.connect(key: "synthetic")
        let muse = MuseConnection(reader: AggregateMuseReader(), defaults: defaults)
        await muse.refresh()
        let model = ReadyCheckAppModel(credentialStore: store, deepSeekConnection: balance, museConnection: muse,
            quotaNotificationService: QuotaNotificationService(client: BubbleTestNotificationClient(), verificationDelays: []),
            widgetVisibilityDefaults: defaults)
        model.codexOAuthStatus = .connected
        try withBubble(edge: edge, deepSeek: deepSeek, connectedModel: model, body)
    }

    private func withBubble(edge: BubbleWidgetPlacement.Edge? = nil, deepSeek: Bool = false, notchContext: NotchWindowController.ScreenContext? = nil,
                            connectedModel: ReadyCheckAppModel? = nil,
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
        let model = connectedModel ?? ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: BubbleTestNotificationClient(), verificationDelays: []))
        let originalService = model.selectedService
        model.selectedDeepSeek = deepSeek
        defer { model.selectedService = originalService }
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

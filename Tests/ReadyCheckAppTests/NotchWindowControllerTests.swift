import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class NotchWindowControllerTests: XCTestCase {
    func testDownwardDragFollowsPointerAndDetachesOnlyOnRelease() throws {
        try withNotch { controller, panel, host in
            let start = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
            let original = panel.frame
            var detached: [CGPoint] = []
            controller.onNotchDetachment = { detached.append($0) }
            try send(.leftMouseDown, at: start, to: panel)
            try send(.leftMouseDragged, at: CGPoint(x: start.x + 50, y: start.y - 80), to: panel)
            XCTAssertTrue(detached.isEmpty)
            XCTAssertFalse(host.rootView.isExpanded)
            XCTAssertEqual(panel.frame.origin, original.offsetBy(dx: 50, dy: -80).origin)
            try send(.leftMouseUp, at: CGPoint(x: start.x + 50, y: start.y - 80), to: panel)
            XCTAssertEqual(detached, [CGPoint(x: start.x + 50, y: start.y - 80)])
        }
    }

    func testSmallSidewaysAndReturningDragsStayAttachedWithoutOpeningDetails() throws {
        try withNotch { controller, panel, host in
            var detached = false
            controller.onNotchDetachment = { _ in detached = true }
            let original = panel.frame
            let start = CGPoint(x: original.midX, y: original.midY)
            for delta in [CGPoint(x: 0, y: -20), CGPoint(x: 100, y: 0), CGPoint(x: 0, y: 40)] {
                try send(.leftMouseDown, at: start, to: panel)
                try send(.leftMouseDragged, at: CGPoint(x: start.x + delta.x, y: start.y + delta.y), to: panel)
                try send(.leftMouseUp, at: CGPoint(x: start.x + delta.x, y: start.y + delta.y), to: panel)
                XCTAssertEqual(panel.frame, original)
                XCTAssertFalse(host.rootView.isExpanded)
            }
            try send(.leftMouseDown, at: start, to: panel)
            try send(.leftMouseDragged, at: CGPoint(x: start.x, y: start.y - 80), to: panel)
            try send(.leftMouseDragged, at: start, to: panel)
            try send(.leftMouseUp, at: start, to: panel)
            XCTAssertFalse(detached)
            XCTAssertEqual(panel.frame, original)
            try send(.leftMouseDown, at: start, to: panel)
            try send(.leftMouseUp, at: start, to: panel)
            XCTAssertTrue(host.rootView.isExpanded, "A click must still open details")
        }
    }

    func testRefreshDoesNotSnapDraggingNotchAndCancellationPreventsDetachment() throws {
        try withNotch { controller, panel, host in
            let original = panel.frame
            let start = CGPoint(x: original.midX, y: original.midY)
            let end = CGPoint(x: start.x, y: start.y - 100)
            var detached = false
            controller.onNotchDetachment = { _ in detached = true }
            try send(.leftMouseDown, at: start, to: panel)
            try send(.leftMouseDragged, at: end, to: panel)
            let dragged = panel.frame
            controller.show(model: host.rootView.model)
            XCTAssertEqual(panel.frame, dragged)
            controller.dismissFromExternalInteraction()
            XCTAssertEqual(panel.frame, original)
            try send(.leftMouseDragged, at: CGPoint(x: end.x, y: end.y - 20), to: panel)
            XCTAssertEqual(panel.frame, original, "Cancellation lasts until the mouse is released")
            try send(.leftMouseUp, at: end, to: panel)
            XCTAssertFalse(detached)
            XCTAssertFalse(host.rootView.isExpanded)
        }
    }

    func testExpandedHeaderDragsButDetailControlsRemainOutsideDragRegion() throws {
        try withNotch { controller, panel, host in
            host.rootView.onClick()
            let draggingPanel = try XCTUnwrap(panel as? BubbleWidgetPanel)
            XCTAssertFalse(draggingPanel.canStartDrag(CGPoint(x: 280, y: panel.frame.height - 30)))
            XCTAssertFalse(draggingPanel.canStartDrag(CGPoint(x: 40, y: 100)))
            XCTAssertTrue(draggingPanel.canStartDrag(CGPoint(x: 40, y: panel.frame.height - 30)))
            var detached = false
            controller.onNotchDetachment = { _ in detached = true }
            let start = CGPoint(x: panel.frame.minX + 40, y: panel.frame.maxY - 30)
            try send(.leftMouseDown, at: start, to: panel)
            try send(.leftMouseDragged, at: CGPoint(x: start.x, y: start.y - 80), to: panel)
            try send(.leftMouseUp, at: CGPoint(x: start.x, y: start.y - 80), to: panel)
            XCTAssertTrue(detached)
            XCTAssertFalse(host.rootView.isExpanded)
        }
    }

    private func withNotch(_ body: (NotchWindowController, QuotaWidgetPanel, NSHostingController<NotchStatusView>) throws -> Void) throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.main)
        let gap = CGRect(x: screen.frame.midX - 92.5, y: screen.frame.maxY - 33, width: 185, height: 33)
        let controller = NotchWindowController(screenContextProvider: { .init(screen: screen, notchGap: gap) }, reduceMotionProvider: { true })
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: QuotaNotificationService(client: NotchNotificationClient(), verificationDelays: []))
        let existing = Set(NSApp.windows.map(\.windowNumber))
        controller.show(model: model)
        defer { controller.close() }
        let panel = try XCTUnwrap(NSApp.windows.first { $0 is QuotaWidgetPanel && !existing.contains($0.windowNumber) } as? QuotaWidgetPanel)
        let host = try XCTUnwrap(panel.contentViewController as? NSHostingController<NotchStatusView>)
        try body(controller, panel, host)
    }

    private func send(_ type: NSEvent.EventType, at screenPoint: CGPoint, to panel: QuotaWidgetPanel) throws {
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: panel.convertPoint(fromScreen: screenPoint),
            modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: panel.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1))
        panel.sendEvent(event)
    }

    func testAnimatedResizeStaysAttachedAndCanReverseBeforeCompletion() throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.main)
        let gap = CGRect(x: screen.frame.midX - 92.5, y: screen.frame.maxY - 33, width: 185, height: 33)
        let controller = NotchWindowController(screenContextProvider: { .init(screen: screen, notchGap: gap) },
            reduceMotionProvider: { false })
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: QuotaNotificationService(client: NotchNotificationClient(), verificationDelays: []))
        let existing = Set(NSApp.windows.map(\.windowNumber))
        controller.show(model: model)
        defer { controller.close() }
        let panel = try XCTUnwrap(NSApp.windows.first { $0 is QuotaWidgetPanel && !existing.contains($0.windowNumber) })
        let host = try XCTUnwrap(panel.contentViewController as? NSHostingController<NotchStatusView>)
        host.rootView.onClick()
        var frames = [CGRect]()
        for index in 0..<22 {
            RunLoop.main.run(until: Date().addingTimeInterval(0.016))
            frames.append(panel.frame)
            if [0, 4, 8, 15, 21].contains(index),
               let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"],
               let view = panel.contentView {
                try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
                view.cacheDisplay(in: view.bounds, to: bitmap)
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to:
                    URL(fileURLWithPath: directory).appendingPathComponent("notch-motion-\(index).png"))
            }
        }
        XCTAssertTrue(frames.contains { $0.width > 186 && $0.width < 359 }, "Expansion must have intermediate frames")
        for frame in frames {
            XCTAssertEqual(frame.maxY, gap.minY + 1, accuracy: 1)
            XCTAssertEqual(frame.midX, gap.midX, accuracy: 1)
        }
        XCTAssertEqual(panel.frame.width, 360, accuracy: 1)
        host.rootView.onDismiss()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        host.rootView.onClick()
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        XCTAssertTrue(host.rootView.isExpanded)
        XCTAssertEqual(panel.frame.width, 360, accuracy: 1)
        host.rootView.onDismiss()
        controller.close()
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        XCTAssertFalse(panel.isVisible, "A stale transition must never reopen a closed panel")
    }

    func testClickHoldAndOutsideDismissKeepBothFramesAttachedAndCloseCleanly() throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.main)
        let gap = CGRect(x: screen.frame.midX - 92.5, y: screen.frame.maxY - 33, width: 185, height: 33)
        let context = NotchWindowController.ScreenContext(screen: screen, notchGap: gap)
        let controller = NotchWindowController(screenContextProvider: { context }, reduceMotionProvider: { true })
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

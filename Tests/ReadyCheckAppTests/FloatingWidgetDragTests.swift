import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class FloatingWidgetDragTests: XCTestCase {
    func testTitleDragUsesNativeWindowDraggingWithoutActivation() throws {
        _ = NSApplication.shared
        let panel = CardDragTestPanel(contentRect: CGRect(x: 200, y: 200, width: 352, height: 420),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        defer { panel.close() }
        let region = WidgetDragView(frame: CGRect(x: 20, y: 350, width: 230, height: 44))
        panel.contentView?.addSubview(region)
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown, location: CGPoint(x: 50, y: 370),
            modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: panel.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        XCTAssertTrue(region.acceptsFirstMouse(for: event))
        for level in [NSWindow.Level.normal, .floating] {
            panel.level = level
            region.mouseDown(with: event)
            XCTAssertTrue(panel.dragEvent === event)
            panel.dragEvent = nil
        }
    }

    func testCardHeaderProvidesDragRegionAndRestoresMovedPosition() throws {
        _ = NSApplication.shared
        let key = "ReadyCheck.floatingWidgetFrame.v1"
        let saved = UserDefaults.standard.object(forKey: key)
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: QuotaNotificationService(client: CardDragNotificationClient(), verificationDelays: []))
        let controller = FloatingWindowController()
        let previous = Set(NSApp.windows.map(\.windowNumber))
        controller.show(model: model)
        defer { controller.close() }
        let panel = try XCTUnwrap(NSApp.windows.first { $0 is NSPanel && !previous.contains($0.windowNumber) })
        let content = try XCTUnwrap(panel.contentView)
        content.layoutSubtreeIfNeeded()
        let regions = descendants(content).filter { String(describing: type(of: $0)) == "WidgetDragView" }
        XCTAssertEqual(regions.count, 1, "The card header needs an explicit native drag region")
        if let region = regions.first {
            let frame = region.convert(region.bounds, to: content)
            XCTAssertGreaterThan(frame.width, 100)
            XCTAssertGreaterThan(frame.height, 20)
            XCTAssertLessThan(frame.maxX, content.bounds.maxX - 40, "Refresh and close stay outside the drag region")
        }
        let visible = try XCTUnwrap(NSScreen.main).visibleFrame
        let moved = CGPoint(x: visible.midX - panel.frame.width / 2, y: visible.midY - panel.frame.height / 2)
        panel.setFrameOrigin(moved)
        controller.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: panel))
        controller.close()
        controller.show(model: model)
        let reopened = try XCTUnwrap(NSApp.windows.first { $0 is NSPanel && !previous.contains($0.windowNumber) })
        XCTAssertEqual(reopened.frame.origin.x, moved.x, accuracy: 1)
        XCTAssertEqual(reopened.frame.origin.y, moved.y, accuracy: 1)
    }

    private func descendants(_ view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }
}

@MainActor
private final class CardDragTestPanel: NSPanel {
    var dragEvent: NSEvent?
    override func performDrag(with event: NSEvent) { dragEvent = event }
}

@MainActor
private final class CardDragNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

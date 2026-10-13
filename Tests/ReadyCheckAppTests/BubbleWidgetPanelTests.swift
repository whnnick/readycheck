import AppKit
import XCTest
@testable import ReadyCheckApp

@MainActor
final class BubbleWidgetPanelTests: XCTestCase {
    func testHorizontalDragKeepsTrackingOutsideNarrowRailInBothDirections() throws {
        _ = NSApplication.shared
        for direction: CGFloat in [-1, 1] {
            let panel = BubbleWidgetPanel(contentRect: CGRect(x: 400, y: 300, width: 28, height: 144),
                styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            defer { panel.close() }
            panel.canStartDrag = { point in CGRect(x: 0, y: 0, width: 28, height: 144).contains(point) }
            var pressed = 0
            var moves: [CGPoint] = []
            var released: [Bool] = []
            panel.onPointerDown = { pressed += 1 }
            panel.onPointerDrag = { start, pointer in
                moves.append(CGPoint(x: pointer.x - start.x, y: pointer.y - start.y))
                // Moving the window must not feed back into screen-pointer movement.
                panel.setFrameOrigin(CGPoint(x: 400 + moves.last!.x, y: 300))
            }
            panel.onPointerUp = { released.append($0) }
            try send(.leftMouseDown, at: CGPoint(x: 14, y: 72), to: panel)
            try send(.leftMouseDragged, at: CGPoint(x: 14 + direction * 3, y: 72), to: panel)
            XCTAssertTrue(moves.isEmpty)
            try send(.leftMouseDragged, at: CGPoint(x: 14 + direction * 40, y: 72), to: panel)
            try send(.leftMouseDragged, at: CGPoint(x: 14 + direction * 60, y: 72), to: panel)
            try send(.leftMouseUp, at: CGPoint(x: 14, y: 72), to: panel)
            XCTAssertEqual(pressed, 1)
            XCTAssertEqual(moves, [CGPoint(x: direction * 40, y: 0), CGPoint(x: direction * 100, y: 0)])
            XCTAssertEqual(released, [true])
            panel.onPointerDrag = { _, _ in }
        }
    }

    func testClickAndSmallMovementRemainClicksAndDetailsAreNotCaptured() throws {
        _ = NSApplication.shared
        let panel = BubbleWidgetPanel(contentRect: CGRect(x: 400, y: 300, width: 500, height: 248),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        defer { panel.close() }
        panel.canStartDrag = { $0.x < 28 }
        var pressed = 0
        var released: [Bool] = []
        panel.onPointerDown = { pressed += 1 }
        panel.onPointerUp = { released.append($0) }
        for _ in 0..<2 {
            try send(.leftMouseDown, at: CGPoint(x: 14, y: 72), to: panel)
            try send(.leftMouseDragged, at: CGPoint(x: 16, y: 72), to: panel)
            try send(.leftMouseUp, at: CGPoint(x: 16, y: 72), to: panel)
        }
        try send(.leftMouseDown, at: CGPoint(x: 300, y: 72), to: panel)
        try send(.leftMouseUp, at: CGPoint(x: 300, y: 72), to: panel)
        XCTAssertEqual(pressed, 2)
        XCTAssertEqual(released, [false, false])
    }

    private func send(_ type: NSEvent.EventType, at point: CGPoint, to panel: BubbleWidgetPanel) throws {
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: panel.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1))
        panel.sendEvent(event)
    }
}

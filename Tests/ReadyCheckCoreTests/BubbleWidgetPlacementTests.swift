import CoreGraphics
import XCTest
@testable import ReadyCheckCore

final class BubbleWidgetPlacementTests: XCTestCase {
    private let display = CGRect(x: -1_920, y: 40, width: 1_920, height: 1_040)

    func testDefaultBubbleIsVisibleAndNotImmediatelySnapped() {
        let frame = BubbleWidgetPlacement.defaultFrame(in: display)
        XCTAssertTrue(display.contains(frame))
        XCTAssertNil(BubbleWidgetPlacement.edge(for: frame, in: display))
    }

    func testRightEdgeTabAndExpandedCardStayInsideDisplay() {
        let dragged = CGRect(x: display.maxX - 77, y: 350, width: 76, height: 76)
        XCTAssertEqual(BubbleWidgetPlacement.edge(for: dragged, in: display), .right)

        let tab = BubbleWidgetPlacement.tabFrame(from: dragged, edge: .right, in: display)
        let expanded = BubbleWidgetPlacement.expandedFrame(from: tab, edge: .right, in: display)
        XCTAssertEqual(tab.size, CGSize(width: 66, height: 114))
        XCTAssertEqual(tab.maxX, display.maxX)
        XCTAssertEqual(expanded.maxX, display.maxX)
        XCTAssertTrue(display.contains(expanded))
    }

    func testLeftEdgeExpansionOpensInwardAndAvoidsMenuBar() {
        let tab = CGRect(x: display.minX, y: display.maxY - 114, width: 66, height: 114)
        let expanded = BubbleWidgetPlacement.expandedFrame(from: tab, edge: .left, in: display)
        XCTAssertEqual(expanded.minX, display.minX)
        XCTAssertEqual(expanded.maxY, display.maxY)
        XCTAssertTrue(display.contains(expanded))
    }

    func testDisconnectedDisplayPositionClampsInsideRemainingDisplay() {
        let remaining = CGRect(x: 0, y: 30, width: 1_440, height: 860)
        let old = CGRect(x: -1_800, y: 200, width: 76, height: 76)
        XCTAssertTrue(remaining.contains(BubbleWidgetPlacement.clamped(old, in: remaining)))
    }

    func testLegacyFramesRestoreAtNewSizeAndKeepSnappedEdge() {
        let bubble = CGRect(x: -200, y: 200, width: 64, height: 64)
        let restoredBubble = BubbleWidgetPlacement.restoredBubbleFrame(from: bubble, in: display)
        XCTAssertEqual(restoredBubble.size, BubbleWidgetPlacement.bubbleSize)
        XCTAssertEqual(restoredBubble.midX, bubble.midX)
        XCTAssertEqual(restoredBubble.midY, bubble.midY)

        let tab = CGRect(x: display.maxX - 32, y: 300, width: 32, height: 72)
        let restoredTab = BubbleWidgetPlacement.restoredBubbleFrame(from: tab, in: display)
        XCTAssertEqual(restoredTab.maxX, display.maxX)
        XCTAssertEqual(restoredTab.midY, tab.midY)
        XCTAssertEqual(BubbleWidgetPlacement.edge(for: restoredTab, in: display), .right)

        let leftTab = CGRect(x: display.minX, y: 300, width: 32, height: 72)
        let restoredLeftTab = BubbleWidgetPlacement.restoredBubbleFrame(from: leftTab, in: display)
        XCTAssertEqual(restoredLeftTab.minX, display.minX)
        XCTAssertEqual(restoredLeftTab.midY, leftTab.midY)
        XCTAssertEqual(BubbleWidgetPlacement.edge(for: restoredLeftTab, in: display), .left)
    }

    func testDraggingUsesAbsolutePointerMovement() {
        let start = CGRect(x: -300, y: 250, width: 76, height: 76)
        let moved = BubbleWidgetPlacement.draggedFrame(
            from: start, pointerStart: CGPoint(x: 700, y: 400), pointerNow: CGPoint(x: 840, y: 510)
        )
        XCTAssertEqual(moved.origin, CGPoint(x: -160, y: 360))
        XCTAssertEqual(moved.size, start.size)
    }
}

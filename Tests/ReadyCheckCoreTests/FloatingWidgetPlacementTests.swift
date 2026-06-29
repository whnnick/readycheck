import CoreGraphics
import XCTest
@testable import ReadyCheckCore

final class FloatingWidgetPlacementTests: XCTestCase {
    func testPlacesWidgetNearBottomTrailingWithMargin() {
        let frame = FloatingWidgetPlacement.frame(
            preferredSize: CGSize(width: 376, height: 360),
            visibleFrame: CGRect(x: 0, y: 80, width: 1440, height: 820)
        )

        XCTAssertEqual(frame, CGRect(x: 1_036, y: 92, width: 376, height: 360))
    }

    func testKeepsWidgetInsideNarrowVisibleFrame() {
        let visibleFrame = CGRect(x: 10, y: 40, width: 320, height: 260)
        let frame = FloatingWidgetPlacement.frame(
            preferredSize: CGSize(width: 376, height: 360),
            visibleFrame: visibleFrame
        )

        XCTAssertTrue(visibleFrame.contains(frame))
        XCTAssertEqual(frame.minX, visibleFrame.minX + FloatingWidgetPlacement.defaultMargin)
        XCTAssertEqual(frame.minY, visibleFrame.minY + FloatingWidgetPlacement.defaultBottomMargin)
    }

    func testKeepsWidgetInsideTinyVisibleFrameWithoutNegativeOrigin() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 48, height: 40)
        let frame = FloatingWidgetPlacement.frame(
            preferredSize: CGSize(width: 376, height: 360),
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(frame, visibleFrame)
        XCTAssertTrue(visibleFrame.contains(frame))
    }

    func testSupportsDisplaysWithNegativeCoordinates() {
        let visibleFrame = CGRect(x: -1_920, y: 60, width: 1_920, height: 1_020)
        let frame = FloatingWidgetPlacement.frame(
            preferredSize: CGSize(width: 376, height: 360),
            visibleFrame: visibleFrame
        )

        XCTAssertTrue(visibleFrame.contains(frame))
        XCTAssertEqual(frame.maxX, visibleFrame.maxX - FloatingWidgetPlacement.defaultMargin)
        XCTAssertEqual(frame.minY, visibleFrame.minY + FloatingWidgetPlacement.defaultBottomMargin)
    }

    func testClampsFrameThatWasPushedBeyondBottomTrailingEdge() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1_440, height: 900)
        let frame = FloatingWidgetPlacement.clampedFrame(
            currentFrame: CGRect(x: 1_430, y: -40, width: 376, height: 360),
            visibleFrame: visibleFrame
        )

        XCTAssertTrue(visibleFrame.contains(frame))
        XCTAssertEqual(frame.maxX, visibleFrame.maxX)
        XCTAssertEqual(frame.minY, visibleFrame.minY)
    }
}

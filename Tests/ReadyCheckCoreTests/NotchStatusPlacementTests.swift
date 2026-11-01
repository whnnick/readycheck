import CoreGraphics
import XCTest
@testable import ReadyCheckCore

final class NotchStatusPlacementTests: XCTestCase {
    func testBubbleDropAttachesOnlyNearPhysicalNotchOnItsScreen() {
        let screen = CGRect(x: -1710, y: 300, width: 1710, height: 1107)
        let gap = CGRect(x: -947, y: 1374, width: 185, height: 33)
        func bubble(_ x: CGFloat, _ y: CGFloat) -> CGRect { CGRect(x: x - 46, y: y - 46, width: 92, height: 92) }
        XCTAssertTrue(NotchStatusPlacement.shouldAttach(bubbleFrame: bubble(gap.midX, gap.minY - 45), notchGap: gap, screenFrame: screen))
        for frame in [bubble(gap.midX, gap.minY - 150), bubble(gap.minX - 100, gap.minY),
                      bubble(100, gap.minY), bubble(gap.midX, screen.maxY + 10)] {
            XCTAssertFalse(NotchStatusPlacement.shouldAttach(bubbleFrame: frame, notchGap: gap, screenFrame: screen))
        }
        XCTAssertFalse(NotchStatusPlacement.shouldAttach(bubbleFrame: bubble(gap.midX, gap.minY), notchGap: nil, screenFrame: screen))
    }

    func testDetachRequiresDeliberateDownwardMovementAndAllowsReturningToNotch() {
        let start = CGPoint(x: -800, y: 1000)
        for end in [CGPoint(x: -800, y: 969), CGPoint(x: -700, y: 1000), CGPoint(x: -800, y: 1050)] {
            XCTAssertFalse(NotchStatusPlacement.shouldDetach(pointerStart: start, pointerNow: end))
        }
        XCTAssertTrue(NotchStatusPlacement.shouldDetach(pointerStart: start, pointerNow: CGPoint(x: -850, y: 960)))
        XCTAssertFalse(NotchStatusPlacement.shouldDetach(pointerStart: start, pointerNow: start))
    }

    func testBuildsGapBetweenAuxiliaryAreas() {
        let gap = NotchStatusPlacement.notchGap(
            leftArea: CGRect(x: 0, y: 1_074, width: 763, height: 33),
            rightArea: CGRect(x: 948, y: 1_074, width: 762, height: 33)
        )

        XCTAssertEqual(gap, CGRect(x: 763, y: 1_074, width: 185, height: 33))
    }

    func testRejectsOverlappingAuxiliaryAreas() {
        XCTAssertNil(
            NotchStatusPlacement.notchGap(
                leftArea: CGRect(x: 0, y: 900, width: 600, height: 30),
                rightArea: CGRect(x: 590, y: 900, width: 610, height: 30)
            )
        )
    }

    func testCentersPanelBelowNotch() {
        let frame = NotchStatusPlacement.frame(
            notchGap: CGRect(x: 763, y: 1_074, width: 185, height: 33),
            screenFrame: CGRect(x: 0, y: 0, width: 1_710, height: 1_107)
        )

        XCTAssertEqual(frame, CGRect(x: 763, y: 1_033, width: 185, height: 42))
    }

    func testBothStatesOverlapPhysicalNotchBottomWithoutAGap() {
        let gap = CGRect(x: 763, y: 1074, width: 185, height: 33)
        let screen = CGRect(x: 0, y: 0, width: 1710, height: 1107)
        for (width, height) in [(CGFloat(185), CGFloat(42)), (360, 264)] {
            let frame = NotchStatusPlacement.frame(notchGap: gap, screenFrame: screen, height: height, width: width)
            XCTAssertEqual(frame.maxY, gap.minY + 1)
            XCTAssertEqual(frame.midX, gap.midX)
            XCTAssertTrue(screen.contains(frame))
        }
    }

    func testKeepsNotchWidthInsideNarrowScreen() {
        let screenFrame = CGRect(x: -800, y: 0, width: 300, height: 500)
        let frame = NotchStatusPlacement.frame(
            notchGap: CGRect(x: -670, y: 470, width: 40, height: 30),
            screenFrame: screenFrame
        )

        XCTAssertEqual(frame.width, 40)
        XCTAssertTrue(screenFrame.contains(frame))
    }
}

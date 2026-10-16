import CoreGraphics
import XCTest
@testable import ReadyCheckCore

final class NotchStatusPlacementTests: XCTestCase {
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

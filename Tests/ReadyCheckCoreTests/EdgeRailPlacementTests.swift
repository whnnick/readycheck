import CoreGraphics
import XCTest
@testable import ReadyCheckCore

final class EdgeRailPlacementTests: XCTestCase {
    private let visible = CGRect(x: 100, y: 50, width: 1_000, height: 700)

    func testModesStayOnChosenEdgeAndKeepSameVerticalCenter() {
        for edge in [EdgeRailPlacement.Edge.left, .right] {
            let frames = [EdgeRailPlacement.Mode.collapsed, .dock, .detail].map {
                EdgeRailPlacement.frame(edge: edge, centerY: 400, mode: $0, in: visible)
            }
            XCTAssertEqual(frames.map(\.width), [32, 84, 354])
            XCTAssertTrue(frames.allSatisfy { $0.midY == 400 })
            XCTAssertTrue(frames.allSatisfy { edge == .left ? $0.minX == visible.minX : $0.maxX == visible.maxX })
        }
    }

    func testVerticalPlacementClampsWithinVisibleScreen() {
        let top = EdgeRailPlacement.frame(edge: .right, centerY: 1_000, mode: .detail, in: visible)
        let bottom = EdgeRailPlacement.frame(edge: .left, centerY: -100, mode: .dock, in: visible)
        XCTAssertEqual(top.maxY, visible.maxY)
        XCTAssertEqual(bottom.minY, visible.minY)
    }

    func testDragSnapsToNearestSide() {
        XCTAssertEqual(EdgeRailPlacement.edge(for: CGPoint(x: 120, y: 400), in: visible), .left)
        XCTAssertEqual(EdgeRailPlacement.edge(for: CGPoint(x: 900, y: 400), in: visible), .right)
    }
}

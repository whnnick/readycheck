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

    func testWeeklyOnlyRailShrinksAndHasNoInventedFiveHourWindow() {
        let weekly = window(id: "codex-secondary", minutes: 10_080)
        let windows = EdgeRailPlacement.displayWindows(in: [weekly])
        XCTAssertEqual(windows.map(\.id), ["codex-secondary"])
        XCTAssertEqual(EdgeRailPlacement.contentHeight(for: windows, maximum: 700), 105)
        XCTAssertEqual(QuotaWindowDisplay.shortLabel(for: weekly), "7d")
    }

    func testKeepsAdditionalNamedBucketsEvenWhenDurationsMatch() {
        let windows = [window(id: "codex-primary", minutes: 300),
                       window(id: "codex-secondary", minutes: 10_080),
                       window(id: "extra-primary", minutes: 300, name: "Extra allowance")]
        XCTAssertEqual(EdgeRailPlacement.displayWindows(in: windows).map(\.id), windows.map(\.id))
        XCTAssertEqual(EdgeRailPlacement.contentHeight(for: windows, maximum: 700), 264)
    }

    func testMissingOrInvalidDataDoesNotCreateRings() {
        let invalid = QuotaWindow(id: "invalid", labelKey: "quota.window.codex.primary",
            kind: .rolling, used: 0, limit: 0, remaining: 0, unit: .percent, resetAt: nil, confidence: .unknown)
        XCTAssertTrue(EdgeRailPlacement.displayWindows(in: [invalid]).isEmpty)
        XCTAssertEqual(EdgeRailPlacement.contentHeight(for: [], maximum: 700), 100)
    }

    func testDynamicFramesStayInsideEitherEdgeOnSmallScreens() {
        let windows = (0..<12).map { window(id: "bucket-\($0)", minutes: 60, name: "Bucket \($0)") }
        let height = EdgeRailPlacement.contentHeight(for: windows, maximum: visible.height)
        XCTAssertEqual(height, visible.height)
        for edge in [EdgeRailPlacement.Edge.left, .right] {
            for mode in [EdgeRailPlacement.Mode.collapsed, .dock, .detail] {
                let frame = EdgeRailPlacement.frame(edge: edge, centerY: 900, mode: mode, in: visible, height: height)
                XCTAssertEqual(frame.maxY, visible.maxY)
                XCTAssertEqual(frame.height, height)
                XCTAssertEqual(edge == .left ? frame.minX : frame.maxX, edge == .left ? visible.minX : visible.maxX)
            }
        }
    }

    private func window(id: String, minutes: Int, name: String? = nil) -> QuotaWindow {
        QuotaWindow(id: id, labelKey: "quota.window.dynamic", displayLabel: name,
            kind: .rolling, used: 30, limit: 100, remaining: 70, unit: .percent, resetAt: nil,
            confidence: .verified, durationMinutes: minutes)
    }

    func testDragSnapsToNearestSide() {
        XCTAssertEqual(EdgeRailPlacement.edge(for: CGPoint(x: 120, y: 400), in: visible), .left)
        XCTAssertEqual(EdgeRailPlacement.edge(for: CGPoint(x: 900, y: 400), in: visible), .right)
    }
}

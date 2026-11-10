import XCTest
@testable import ReadyCheckCore

final class AggregateCapsulePlacementTests: XCTestCase {
    func testRestorationPreservesTheLegacyCenterWithoutChangingLegacySize() {
        let visible = CGRect(x: -1440, y: 20, width: 1440, height: 900)
        let old = CGRect(x: -180, y: 300, width: 92, height: 92)
        let restored = AggregateCapsulePlacement.restoredFrame(from: old, in: visible)
        XCTAssertEqual(restored.midX, old.midX)
        XCTAssertEqual(restored.midY, old.midY)
        XCTAssertEqual(restored.size, AggregateCapsulePlacement.size)
        XCTAssertEqual(old.size, CGSize(width: 92, height: 92))
    }

    func testDetailsOpenInwardWithoutHidingTheRailAtEitherEdge() {
        let visible = CGRect(x: 0, y: 25, width: 1440, height: 875)
        for x: CGFloat in [0, 678, 1356] {
            let rail = AggregateCapsulePlacement.restoredFrame(from: CGRect(x: x, y: 100, width: 84, height: 392), in: visible)
            let detail = AggregateCapsulePlacement.detailFrame(beside: rail, in: visible)
            XCTAssertTrue(visible.contains(detail))
            XCTAssertFalse(rail.intersects(detail))
            XCTAssertGreaterThanOrEqual(detail.width, 360)
        }
    }

    func testShortScreensClampBothSurfacesAndSnapPreservesVerticalPlacement() {
        let visible = CGRect(x: 100, y: -500, width: 500, height: 300)
        let rail = AggregateCapsulePlacement.restoredFrame(from: CGRect(x: 550, y: -100, width: 92, height: 92), in: visible)
        XCTAssertTrue(visible.contains(rail))
        XCTAssertEqual(rail.height, 300)
        let detail = AggregateCapsulePlacement.detailFrame(beside: rail, in: visible)
        XCTAssertTrue(visible.contains(detail))
        XCTAssertFalse(rail.intersects(detail))
        let moved = rail.offsetBy(dx: -15, dy: 0)
        let snapped = AggregateCapsulePlacement.snappedFrame(moved, in: visible)
        XCTAssertEqual(snapped.maxX, visible.maxX)
        XCTAssertEqual(snapped.midY, rail.midY)
    }

    func testAggregatePresentationPersistsWithoutMigratingLegacyPositions() {
        let name = "aggregate-preference-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("{{700, 300}, {92, 92}}", forKey: "ReadyCheck.bubbleWidgetFrame.v1")
        WidgetPresentationPreference.set(.aggregate, defaults: defaults)
        XCTAssertEqual(WidgetPresentationPreference.value(defaults: defaults), .aggregate)
        XCTAssertEqual(defaults.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"), "{{700, 300}, {92, 92}}")
    }
}

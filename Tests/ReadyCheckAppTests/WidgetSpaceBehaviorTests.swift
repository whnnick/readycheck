import AppKit
import XCTest
@testable import ReadyCheckApp

@MainActor
final class WidgetSpaceBehaviorTests: XCTestCase {
    func testFullscreenPolicyKeepsStationaryPlacementAndExcludesFullscreenSpaces() {
        let hidden = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: true)
        XCTAssertFalse(hidden.contains(.canJoinAllSpaces))
        XCTAssertTrue(hidden.contains(.stationary))
        XCTAssertTrue(hidden.contains(.fullScreenNone))
        XCTAssertTrue(hidden.contains(.canJoinAllApplications))
        XCTAssertFalse(hidden.contains(.auxiliary))
        XCTAssertFalse(hidden.contains(.fullScreenAuxiliary))
        let shown = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: false)
        XCTAssertTrue(shown.contains(.fullScreenAuxiliary))
        XCTAssertTrue(shown.contains(.canJoinAllApplications))
        XCTAssertFalse(shown.contains(.auxiliary))
        XCTAssertFalse(shown.contains(.fullScreenNone))
    }
}

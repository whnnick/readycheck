import XCTest
@testable import ReadyCheckApp

final class ServiceSwitcherIconTests: XCTestCase {
    func testBothSwitcherIconsLoadFromBundledResources() {
        XCTAssertNotNil(ServiceSwitcherIcon.image(name: "readycheck", extension: "png"))
        XCTAssertNotNil(ServiceSwitcherIcon.image(name: "deepseek", extension: "svg"))
    }
}

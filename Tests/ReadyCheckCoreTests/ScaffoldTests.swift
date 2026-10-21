import XCTest
@testable import ReadyCheckCore

final class ScaffoldTests: XCTestCase {
    func testCoreVersionIsDefined() {
        XCTAssertEqual(ReadyCheckCore.version, "0.4.0")
    }
}

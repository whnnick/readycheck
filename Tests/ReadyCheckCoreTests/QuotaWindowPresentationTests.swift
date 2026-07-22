import XCTest
@testable import ReadyCheckCore

final class QuotaWindowPresentationTests: XCTestCase {
    func testShowsSevenDayWindow() {
        XCTAssertTrue(QuotaWindowPresentation.shouldShow(labelKey: "quota.window.codex.7d"))
    }

    func testHidesRetiredFiveHourWindow() {
        XCTAssertFalse(QuotaWindowPresentation.shouldShow(labelKey: "quota.window.codex.5h"))
        XCTAssertFalse(QuotaWindowPresentation.shouldShow(labelKey: "quota.fiveHour"))
    }

    func testDoesNotHideOtherProviderWindows() {
        XCTAssertTrue(QuotaWindowPresentation.shouldShow(labelKey: "quota.window.claude.monthly"))
    }
}

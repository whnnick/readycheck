import XCTest
@testable import ReadyCheckCore

final class QuotaWindowPresentationTests: XCTestCase {
    func testShowsSevenDayWindow() {
        XCTAssertTrue(QuotaWindowPresentation.shouldShow(labelKey: "quota.window.codex.7d"))
    }

    func testShowsFiveHourWindowWhenProviderReturnsIt() {
        XCTAssertTrue(QuotaWindowPresentation.shouldShow(labelKey: "quota.window.codex.5h"))
        XCTAssertTrue(QuotaWindowPresentation.shouldShow(labelKey: "quota.fiveHour"))
    }

    func testDoesNotHideOtherProviderWindows() {
        XCTAssertTrue(QuotaWindowPresentation.shouldShow(labelKey: "quota.window.claude.monthly"))
    }
}

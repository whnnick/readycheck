import XCTest
@testable import ReadyCheckCore

final class QuotaFormattersTests: XCTestCase {
    func testPercentageTextReturnsDashForInvalidRatios() {
        XCTAssertEqual(QuotaFormatters.percentageText(for: nil), "—")
        XCTAssertEqual(QuotaFormatters.percentageText(for: -.leastNonzeroMagnitude), "—")
        XCTAssertEqual(QuotaFormatters.percentageText(for: .infinity), "—")
    }

    func testPercentageTextRoundsValidRatioToIntegerPercent() {
        XCTAssertEqual(QuotaFormatters.percentageText(for: 0), "0%")
        XCTAssertEqual(QuotaFormatters.percentageText(for: 0.724), "72%")
        XCTAssertEqual(QuotaFormatters.percentageText(for: 0.725), "73%")
        XCTAssertEqual(QuotaFormatters.percentageText(for: 1), "100%")
    }

    func testSourceTextMapsProviderSourcesToDisplayText() {
        XCTAssertEqual(QuotaFormatters.sourceText(.mock), "Mock")
        XCTAssertEqual(QuotaFormatters.sourceText(.local), "Local")
        XCTAssertEqual(QuotaFormatters.sourceText(.usageAPI), "Usage API")
        XCTAssertEqual(QuotaFormatters.sourceText(.costAPI), "Cost API")
        XCTAssertEqual(QuotaFormatters.sourceText(.oauthAPI), "OAuth API")
        XCTAssertEqual(QuotaFormatters.sourceText(.manual), "Manual")
    }
}

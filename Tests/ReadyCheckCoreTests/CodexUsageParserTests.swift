import XCTest
@testable import ReadyCheckCore

final class CodexUsageParserTests: XCTestCase {
    func testParserBuildsFiveHourAndSevenDayWindows() throws {
        let parser = CodexUsageParser()
        let refreshedAt = Date(timeIntervalSince1970: 1_000)
        let data = Data(
            """
            {
              "rate_limit": {
                "allowed": true,
                "limit_reached": false,
                "primary_window": {
                  "used_percent": 25,
                  "limit_window_seconds": 18000,
                  "reset_after_seconds": 3600,
                  "reset_at": 4600
                },
                "secondary_window": {
                  "used_percent": 40,
                  "limit_window_seconds": 604800,
                  "reset_after_seconds": 86400,
                  "reset_at": 87400
                }
              }
            }
            """.utf8
        )

        let windows = try parser.parse(data, refreshedAt: refreshedAt)

        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0].id, "codex-primary")
        XCTAssertEqual(windows[0].labelKey, "quota.window.codex.5h")
        XCTAssertEqual(windows[0].used, 25)
        XCTAssertEqual(windows[0].remaining, 75)
        XCTAssertEqual(windows[0].limit, 100)
        XCTAssertEqual(windows[0].unit, .percent)
        XCTAssertEqual(windows[0].resetAt, Date(timeIntervalSince1970: 4_600))
        XCTAssertEqual(windows[0].confidence, .verified)
        XCTAssertEqual(windows[1].labelKey, "quota.window.codex.7d")
        XCTAssertEqual(windows[1].used, 40)
        XCTAssertEqual(windows[1].remaining, 60)
    }

    func testParserClampsUsedPercentOverOneHundred() throws {
        let parser = CodexUsageParser()
        let data = Data(
            """
            {
              "rate_limit": {
                "primary_window": {
                  "used_percent": 125,
                  "limit_window_seconds": 18000
                }
              }
            }
            """.utf8
        )

        let windows = try parser.parse(data, refreshedAt: Date(timeIntervalSince1970: 1_000))

        XCTAssertEqual(windows[0].used, 100)
        XCTAssertEqual(windows[0].remaining, 0)
        XCTAssertNotNil(windows[0].remainingRatio)
    }

    func testParserFailsClosedWithoutDisplayableWindows() throws {
        let parser = CodexUsageParser()
        let data = Data(#"{"rate_limit":{"primary_window":{"limit_window_seconds":18000}}}"#.utf8)

        XCTAssertThrowsError(try parser.parse(data, refreshedAt: Date())) { error in
            XCTAssertEqual(error as? CodexUsageParserError, .noDisplayableWindows)
        }
    }

    func testParserExtractsManualResetDetailsWhenProvided() {
        let parser = CodexUsageParser()
        let data = Data(
            """
            {
              "rate_limit": {
                "manual_reset_count": 1,
                "manual_reset_expirations": [1782526542]
              }
            }
            """.utf8
        )

        let details = parser.parseManualResetDetails(data)

        XCTAssertEqual(details.manualResetCount, 1)
        XCTAssertEqual(details.manualResetExpirations, [Date(timeIntervalSince1970: 1_782_526_542)])
    }

    func testParserExtractsZeroManualResetCountFromEmptyArray() {
        let parser = CodexUsageParser()
        let data = Data(
            """
            {
              "rate_limit": {
                "manual_resets": []
              }
            }
            """.utf8
        )

        let details = parser.parseManualResetDetails(data)

        XCTAssertEqual(details.manualResetCount, 0)
        XCTAssertEqual(details.manualResetExpirations, [])
    }
}

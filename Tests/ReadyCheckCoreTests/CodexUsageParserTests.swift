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

    func testParserExtractsManualResetCreditsAvailableCount() {
        let parser = CodexUsageParser()
        let data = Data(
            """
            {
              "rate_limit_reset_credits": {
                "available_count": 1
              }
            }
            """.utf8
        )

        let details = parser.parseManualResetDetails(data)

        XCTAssertEqual(details.manualResetCount, 1)
    }

    func testParserExtractsManualResetCreditsEndpointExpirations() {
        let parser = CodexUsageParser()
        let data = Data(
            """
            {
              "available_count": 1,
              "credits": [
                {
                  "reset_type": "codex_rate_limits",
                  "status": "available",
                  "granted_at": "2026-07-01T20:38:12.468133Z",
                  "expires_at": "2026-07-31T20:38:12.468133Z"
                },
                {
                  "reset_type": "codex_rate_limits",
                  "status": "consumed",
                  "expires_at": "2026-08-01T20:38:12.468133Z"
                }
              ]
            }
            """.utf8
        )

        let details = parser.parseManualResetDetails(data)

        XCTAssertEqual(details.manualResetCount, 1)
        XCTAssertEqual(details.manualResetExpirations.map { Int($0.timeIntervalSince1970) }, [1_785_530_292])
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

    func testParserExtractsCodexCreditBalance() {
        let parser = CodexUsageParser()
        let data = Data(
            """
            {
              "credits": {
                "has_credits": true,
                "unlimited": false,
                "balance": "3336.500"
              }
            }
            """.utf8
        )

        let details = parser.parseManualResetDetails(data)

        XCTAssertEqual(details.creditBalance, "3336.5")
        XCTAssertEqual(details.creditsUnlimited, false)
    }

    func testParserExtractsNumericAndUnlimitedCodexCredits() {
        let parser = CodexUsageParser()
        let numeric = parser.parseManualResetDetails(
            Data(#"{"credits":{"unlimited":false,"balance":12.75}}"#.utf8)
        )
        let zero = parser.parseManualResetDetails(
            Data(#"{"credits":{"unlimited":false,"balance":"0"}}"#.utf8)
        )
        let unlimited = parser.parseManualResetDetails(
            Data(#"{"credits":{"unlimited":true}}"#.utf8)
        )

        XCTAssertEqual(numeric.creditBalance, "12.75")
        XCTAssertEqual(numeric.creditsUnlimited, false)
        XCTAssertEqual(zero.creditBalance, "0")
        XCTAssertEqual(zero.creditsUnlimited, false)
        XCTAssertNil(unlimited.creditBalance)
        XCTAssertEqual(unlimited.creditsUnlimited, true)
    }

    func testParserIgnoresMissingOrInvalidCodexCreditBalance() {
        let parser = CodexUsageParser()
        let missing = parser.parseManualResetDetails(Data(#"{}"#.utf8))
        let invalid = parser.parseManualResetDetails(
            Data(#"{"credits":{"unlimited":false,"balance":"not-a-number"}}"#.utf8)
        )

        XCTAssertNil(missing.creditBalance)
        XCTAssertNil(missing.creditsUnlimited)
        XCTAssertNil(invalid.creditBalance)
        XCTAssertEqual(invalid.creditsUnlimited, false)
    }
}

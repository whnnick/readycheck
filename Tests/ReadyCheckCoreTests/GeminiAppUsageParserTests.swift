import Foundation
import XCTest
@testable import ReadyCheckCore

final class GeminiAppUsageParserTests: XCTestCase {
    func testRecognizesIndependentFiveHourAndWeeklyUsage() throws {
        let body = ")]}'\n" + #"[{"data":{"viewer":{"rpcs":{"getUsageInfo":{"pools":[{"poolType":"GXU_FIVE_HOURLY","percentageUsed":0.24,"gxu":{"windowRefreshesAt":"2026-10-31T04:43:53.558200Z"}},{"poolType":"GXU_WEEKLY","percentageUsed":0,"gxu":{"windowRefreshesAt":"2026-11-05T04:43:53Z"}}]}}}}}]"#
        let reading = try GeminiAppUsageParser.parse(Data(body.utf8))
        XCTAssertEqual(reading.fiveHour?.usedFraction, 0.24)
        XCTAssertEqual(reading.weekly?.usedFraction, 0)
        XCTAssertNotNil(reading.fiveHour?.resetsAt)
        XCTAssertNotNil(reading.weekly?.resetsAt)
    }

    func testMissingAndUnknownWindowsAreNotInvented() throws {
        let body = #"[{"data":{"viewer":{"rpcs":{"getUsageInfo":{"pools":[{"poolType":"OTHER","percentageUsed":0.2}]}}}}}]"#
        let reading = try GeminiAppUsageParser.parse(Data(body.utf8))
        XCTAssertNil(reading.fiveHour)
        XCTAssertNil(reading.weekly)
    }

    func testRejectsOutOfRangeDuplicateAndMalformedData() {
        for pools in [
            #"[{"poolType":"GXU_WEEKLY","percentageUsed":1.1}]"#,
            #"[{"poolType":"GXU_WEEKLY","percentageUsed":-0.01}]"#,
            #"[{"poolType":"GXU_WEEKLY","percentageUsed":true}]"#,
            #"[{"poolType":"GXU_WEEKLY","percentageUsed":0.5,"gxu":{"windowRefreshesAt":"not-a-date"}}]"#,
            #"[{"poolType":"GXU_WEEKLY","percentageUsed":0.1},{"poolType":"GXU_WEEKLY","percentageUsed":0.2}]"#,
            #"[{"poolType":"GXU_WEEKLY","percentageUsed":"0.5"}]"#
        ] {
            let body = "[{\"data\":{\"viewer\":{\"rpcs\":{\"getUsageInfo\":{\"pools\":\(pools)}}}}}]"
            XCTAssertThrowsError(try GeminiAppUsageParser.parse(Data(body.utf8)))
        }
        XCTAssertThrowsError(try GeminiAppUsageParser.parse(Data("<html>".utf8)))
    }

    func testSignedOutAndQueryFailureAreDistinct() {
        let signedOut = #"[{"data":{"viewer":null}}]"#
        XCTAssertThrowsError(try GeminiAppUsageParser.parse(Data(signedOut.utf8))) { XCTAssertEqual($0 as? GeminiAppUsageParser.Error, .signedOut) }
        let rejected = #"[{"data":null,"errors":[{"message":"query rejected"}]}]"#
        XCTAssertThrowsError(try GeminiAppUsageParser.parse(Data(rejected.utf8))) { XCTAssertEqual($0 as? GeminiAppUsageParser.Error, .invalidResponse) }
    }
}

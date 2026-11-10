import Foundation
import XCTest
@testable import ReadyCheckCore

final class MuseUsageTests: XCTestCase {
    func testPaidWeeklyUsagePreservesProviderLabelsWithoutInventingTokenTotals() throws {
        let result = try parse(#"{"tier":{"name":"Power"},"usage":{"percentUsed":27,"resetsAt":1900000000},"usageRowValueLabel":"27% used (400M tokens left)","topupRowValueLabel":"1M tokens left","agreement":{"currentPeriodEndTime":1910000000}}"#)
        XCTAssertEqual(result.remainingRatio, 0.73, accuracy: 0.00001)
        XCTAssertEqual(result.plan, "Power")
        XCTAssertEqual(result.resetsAt, Date(timeIntervalSince1970: 1900000000))
        XCTAssertEqual(result.usageLabel, "27% used (400M tokens left)")
        XCTAssertEqual(result.additionalLabel, "1M tokens left")
        XCTAssertNotNil(result.renewsAt)
    }

    func testFreeUnknownAndZeroValuesRemainDistinct() throws {
        let empty = try parse(#"{"usage":{"percentUsed":0},"topupBalance":80000000}"#)
        XCTAssertEqual(empty.remainingRatio, 1)
        XCTAssertNil(empty.plan)
        XCTAssertNil(empty.resetsAt)
        XCTAssertNil(empty.additionalLabel, "Micro-dollar balance is not a token count")
        XCTAssertEqual(try parse(#"{"usage":{"percentUsed":100}}"#).remainingRatio, 0)
        XCTAssertThrowsError(try parse(#"{"usage":{}}"#))
    }

    func testMalformedOrOutOfRangeReadingsAreRejected() {
        for body in [#"{"usage":{"percentUsed":-1}}"#, #"{"usage":{"percentUsed":101}}"#,
                     #"{"usage":{"percentUsed":true}}"#, #"{"usage":{"percentUsed":"12"}}"#] {
            XCTAssertThrowsError(try parse(body))
        }
        XCTAssertThrowsError(try MuseUsageParser.parse(Data("1:{\"success\":false}".utf8)))
        XCTAssertThrowsError(try MuseUsageParser.parse(Data(repeating: 32, count: 524_289)))
        XCTAssertThrowsError(try MuseUsageParser.parse(Data("<html>Sign in</html>".utf8)))
    }

    func testInvalidDatesAndControlTextDoNotBecomeValidAccountFields() throws {
        let snapshot = try parse(#"{"tier":{"name":"bad\nplan"},"usage":{"percentUsed":12,"resetsAt":-1},"agreement":{"currentPeriodEndTime":999999999999999}}"#)
        XCTAssertNil(snapshot.plan)
        XCTAssertNil(snapshot.resetsAt)
        XCTAssertNil(snapshot.renewsAt)
    }

    func testAgeAndElapsedResetInvalidateThePercentageWithoutInventingRecovery() throws {
        let snapshot = try parse(#"{"usage":{"percentUsed":25,"resetsAt":1900000000}}"#)
        let date = Date(timeIntervalSince1970: 1899999900)
        XCTAssertTrue(snapshot.isCurrent(observedAt: date, now: date))
        XCTAssertFalse(snapshot.isCurrent(observedAt: date, now: date.addingTimeInterval(100)))
        let noReset = try parse(#"{"usage":{"percentUsed":25}}"#)
        XCTAssertFalse(noReset.isCurrent(observedAt: date, now: date.addingTimeInterval(301)))
        XCTAssertFalse(noReset.isCurrent(observedAt: date, now: date.addingTimeInterval(-1)))
    }

    private func parse(_ subscription: String) throws -> MuseUsageSnapshot {
        try MuseUsageParser.parse(Data(("0:{\"a\":\"$@1\"}\n1:{\"success\":true,\"subscription\":" + subscription + "}\n").utf8))
    }
}

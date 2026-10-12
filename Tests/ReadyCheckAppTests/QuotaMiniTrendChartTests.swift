import SwiftUI
import XCTest
@testable import ReadyCheckApp

final class QuotaMiniTrendChartTests: XCTestCase {
    func testMissingBinsBreakTheLineWithoutMovingSamples() {
        let segments = QuotaMiniTrendChart.segments(values: [0, 0.02, nil, 0.01], size: CGSize(width: 120, height: 22))
        XCTAssertEqual(segments.map(\.count), [2, 1])
        XCTAssertEqual(segments[0].map(\.x), [15, 45])
        XCTAssertEqual(segments[1][0].x, 105)
        XCTAssertEqual(segments[0][0].y, 20.5)
        XCTAssertEqual(segments[0][1].y, 1.5)
    }

    func testZeroAndInvalidValuesRemainDistinct() {
        let segments = QuotaMiniTrendChart.segments(values: [nil, 0, .nan, -1, .infinity, 0],
            size: CGSize(width: 120, height: 22))
        XCTAssertEqual(segments.map(\.count), [1, 1])
        XCTAssertEqual(segments.flatMap { $0 }.map(\.y), [20.5, 20.5])
        XCTAssertTrue(QuotaMiniTrendChart.segments(values: [nil, nil], size: CGSize(width: 120, height: 22)).isEmpty)
    }

    func testPeakAndIntermediateValuesArePreserved() {
        let points = QuotaMiniTrendChart.segments(values: [0.01, 0.04, 0.02], size: CGSize(width: 120, height: 22))[0]
        XCTAssertEqual(points.map(\.y), [15.75, 1.5, 11])
        XCTAssertTrue(QuotaMiniTrendChart.segments(values: [1], size: .zero).isEmpty)
    }
}

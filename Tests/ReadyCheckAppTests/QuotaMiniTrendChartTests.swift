import SwiftUI
import XCTest
@testable import ReadyCheckApp

final class QuotaMiniTrendChartTests: XCTestCase {
    func testOneBarPerObservedBinPreservesMissingTimeSlots() {
        let bars = QuotaMiniTrendChart.bars(values: [0, 0.02, nil, 0.01], size: CGSize(width: 120, height: 22))
        XCTAssertEqual(bars.count, 3)
        XCTAssertEqual(bars.map { $0.rect.midX }, [15, 45, 105])
        XCTAssertEqual(bars.map(\.isZero), [true, false, false])
        XCTAssertEqual(bars[1].rect.height, 20)
        XCTAssertEqual(bars[2].rect.height, 10)
        XCTAssertEqual(bars[1].rect.maxY, bars[2].rect.maxY)
    }

    func testZeroMarkersAndInvalidValuesRemainDistinct() {
        let bars = QuotaMiniTrendChart.bars(values: [nil, 0, .nan, -1, .infinity, 0],
            size: CGSize(width: 120, height: 22))
        XCTAssertEqual(bars.count, 2)
        XCTAssertTrue(bars.allSatisfy(\.isZero))
        XCTAssertEqual(bars.map { $0.rect.midX }, [30, 110])
        XCTAssertTrue(QuotaMiniTrendChart.bars(values: [nil, nil], size: CGSize(width: 120, height: 22)).isEmpty)
    }

    func testRelativeHeightsAndTwelveSeparateBarsFitCompactChart() {
        let bars = QuotaMiniTrendChart.bars(values: [0.01, 0.04, 0.02], size: CGSize(width: 120, height: 22))
        XCTAssertEqual(bars.map { $0.rect.height }, [5, 20, 10])
        let hourly = QuotaMiniTrendChart.bars(values: Array(repeating: 0.01, count: 12),
            size: CGSize(width: 228, height: 22))
        XCTAssertEqual(hourly.count, 12)
        for (index, bar) in hourly.enumerated() {
            XCTAssertGreaterThanOrEqual(bar.rect.minX, 0)
            XCTAssertLessThanOrEqual(bar.rect.maxX, 228)
            if index > 0 { XCTAssertGreaterThan(bar.rect.minX, hourly[index - 1].rect.maxX) }
        }
        XCTAssertTrue(QuotaMiniTrendChart.bars(values: [1], size: .zero).isEmpty)
    }
}

import AppKit
import SwiftUI
import XCTest
@testable import ReadyCheckApp
import ReadyCheckCore

@MainActor
final class LocalQuotaUsageChartTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testInspectionHitsVisibleBarIncludingFirstAndLastEdges() {
        let buckets = fixtureBuckets
        let size = CGSize(width: 200, height: 100)
        let positions = [CGPoint(x: 24, y: 20), CGPoint(x: 100, y: 60), CGPoint(x: 176, y: 40)]
        for index in buckets.indices {
            let hit = LocalQuotaUsageChart.inspectedBucket(at: CGPoint(x: positions[index].x, y: 80),
                plotSize: size, buckets: buckets, position: { positions[buckets.firstIndex(of: $0)!] })
            XCTAssertEqual(hit, buckets[index])
        }
        for point in [CGPoint(x: -1, y: 80), CGPoint(x: 24, y: -1), CGPoint(x: 24, y: 101),
                      CGPoint(x: 24, y: 10), CGPoint(x: 60, y: 80)] {
            XCTAssertNil(LocalQuotaUsageChart.inspectedBucket(at: point, plotSize: size,
                buckets: buckets, position: { positions[buckets.firstIndex(of: $0)!] }))
        }
    }

    func testInspectionDoesNotInventBarsForZeroOrMissingProjection() {
        let zero = QuotaUsageBucket(start: start, end: start.addingTimeInterval(3600), consumedRatio: 0)
        XCTAssertNil(LocalQuotaUsageChart.inspectedBucket(at: CGPoint(x: 24, y: 100),
            plotSize: CGSize(width: 200, height: 100), buckets: [zero], position: { _ in CGPoint(x: 24, y: 100) }))
        XCTAssertNil(LocalQuotaUsageChart.inspectedBucket(at: CGPoint(x: 24, y: 80),
            plotSize: CGSize(width: 200, height: 100), buckets: fixtureBuckets, position: { _ in nil }))
    }

    func testTooltipStaysInsidePlotAtBothEdges() {
        let plot = CGRect(x: 35, y: 10, width: 379, height: 160)
        for barX: CGFloat in [35, 59, 224, 390, 414] {
            let leading = LocalQuotaUsageChart.tooltipLeading(barX: barX, plotFrame: plot)
            XCTAssertGreaterThanOrEqual(leading, plot.minX)
            XCTAssertLessThanOrEqual(leading + 220, plot.maxX)
        }
    }

    func testTooltipUsesPercentagePointsAndKeepsFractionalValuesInBothLanguages() {
        let bucket = QuotaUsageBucket(start: start, end: start.addingTimeInterval(3600), consumedRatio: 0.125)
        XCTAssertEqual(QuotaUsageTooltip.consumptionText(bucket, localization: .init(language: .zhCN)), "消耗 12.5 个百分点")
        XCTAssertEqual(QuotaUsageTooltip.consumptionText(bucket, localization: .init(language: .enUS)), "Used 12.5 percentage points")
        for language in [AppLanguage.zhCN, .enUS] {
            XCTAssertFalse(QuotaUsageTooltip.periodText(bucket, localization: .init(language: language)).isEmpty)
        }
    }

    func testInspectedFirstMiddleLastBarsRenderAtMinimumWidthInBothLanguages() throws {
        _ = NSApplication.shared
        for language in [AppLanguage.zhCN, .enUS] {
            let localization = LocalizationService(language: language)
            for index in fixtureBuckets.indices {
                let view = LocalQuotaUsageChart(buckets: fixtureBuckets, localization: localization,
                    axisFormat: .dateTime.locale(Locale(identifier: language.rawValue)).hour(),
                    revealProgress: 1, inspectedBucketID: .constant(fixtureBuckets[index].id))
                    .padding(16)
                let host = NSHostingView(rootView: view.frame(width: 430).background(Color(nsColor: .windowBackgroundColor)))
                let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 430, height: 230),
                    styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.contentView = host
                host.frame = CGRect(x: 0, y: 0, width: 430, height: 230)
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                defer { window.close() }
                XCTAssertEqual(host.bounds.width, 430, accuracy: 1)
                if let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                    let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to:
                        URL(fileURLWithPath: directory).appendingPathComponent("quota-tooltip-\(index)-\(language.rawValue).png"))
                }
            }
        }
    }

    private var fixtureBuckets: [QuotaUsageBucket] {
        [0.31, 0.125, 0.07].enumerated().map { index, amount in
            let date = start.addingTimeInterval(Double(index) * 3600)
            return QuotaUsageBucket(start: date, end: date.addingTimeInterval(3600), consumedRatio: amount)
        }
    }
}

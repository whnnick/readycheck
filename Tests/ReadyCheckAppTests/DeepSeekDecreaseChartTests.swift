import AppKit
import SwiftUI
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class DeepSeekDecreaseChartTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testInspectionHitsOnlyVisibleBarsIncludingBothEdges() {
        let bins = fixtureBins
        let frames = [CGRect(x: 0, y: 20, width: 20, height: 80),
                      CGRect(x: 90, y: 60, width: 20, height: 40),
                      CGRect(x: 180, y: 40, width: 20, height: 60)]
        let size = CGSize(width: 200, height: 100)
        for index in bins.indices {
            XCTAssertEqual(DeepSeekDecreaseChart.inspectedBucket(at: CGPoint(x: frames[index].midX, y: 80),
                plotSize: size, bins: bins, barFrame: { frames[bins.firstIndex(of: $0)!] }), bins[index])
        }
        for point in [CGPoint(x: -1, y: 80), CGPoint(x: 10, y: 10), CGPoint(x: 40, y: 80), CGPoint(x: 190, y: 101)] {
            XCTAssertNil(DeepSeekDecreaseChart.inspectedBucket(at: point, plotSize: size, bins: bins,
                barFrame: { frames[bins.firstIndex(of: $0)!] }))
        }
        for amount: Decimal? in [nil, 0] {
            let bin = DeepSeekConsumptionBucket(start: start, end: start.addingTimeInterval(3600), decrease: amount)
            XCTAssertNil(DeepSeekDecreaseChart.inspectedBucket(at: CGPoint(x: 10, y: 80), plotSize: size,
                bins: [bin], barFrame: { _ in frames[0] }))
        }
        XCTAssertNil(DeepSeekDecreaseChart.inspectedBucket(at: CGPoint(x: 10, y: 80), plotSize: size,
            bins: bins, barFrame: { _ in nil }))
    }

    func testTooltipPreservesSmallCurrencyAmountsAndLocalizesPeriod() {
        let bin = fixtureBins[0]
        XCTAssertEqual(DeepSeekDecreaseTooltip.amountText(bin, currency: "CNY", language: .zhCN), "已观测减少 0.0006 CNY")
        XCTAssertEqual(DeepSeekDecreaseTooltip.amountText(bin, currency: "USD", language: .enUS), "Observed decrease 0.0006 USD")
        for language in [AppLanguage.zhCN, .enUS] {
            XCTAssertFalse(DeepSeekDecreaseTooltip.periodText(bin, language: language).isEmpty)
        }
    }

    func testTooltipStaysInsideNarrowAndRegularPlots() {
        for width: CGFloat in [160, 379] {
            let plot = CGRect(x: 35, y: 10, width: width, height: 160)
            for x in [plot.minX, plot.midX, plot.maxX] {
                let leading = DeepSeekDecreaseChart.tooltipLeading(barX: x, plotFrame: plot)
                XCTAssertGreaterThanOrEqual(leading, plot.minX)
                XCTAssertLessThanOrEqual(leading + min(220, width), plot.maxX)
            }
        }
    }

    func testInspectedEdgeBarsRenderInBothLanguagesAndAppearances() throws {
        _ = NSApplication.shared
        for language in [AppLanguage.zhCN, .enUS] {
            for dark in [false, true] {
                for index in [0, 2] {
                    let view = DeepSeekDecreaseChart(bins: fixtureBins, range: start...start.addingTimeInterval(10800),
                        interval: 3600, compact: false, currency: "CNY", language: language,
                        inspectedBucketID: .constant(fixtureBins[index].id))
                        .frame(height: 178).padding(16)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .environment(\.colorScheme, dark ? .dark : .light)
                    let host = NSHostingView(rootView: view.frame(width: 430, height: 230))
                    let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 430, height: 230),
                        styleMask: [.borderless], backing: .buffered, defer: false)
                    window.isReleasedWhenClosed = false
                    window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                    window.contentView = host
                    host.frame = CGRect(x: 0, y: 0, width: 430, height: 230)
                    host.layoutSubtreeIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                    defer { window.close() }
                    XCTAssertLessThanOrEqual(host.fittingSize.width, 431)
                    if let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                        host.cacheDisplay(in: host.bounds, to: bitmap)
                        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to:
                            URL(fileURLWithPath: directory).appendingPathComponent("deepseek-tooltip-\(index)-\(language.rawValue)-\(dark).png"))
                    }
                }
            }
        }
    }

    private var fixtureBins: [DeepSeekConsumptionBucket] {
        ["0.0006", "0.002", "0.001"].enumerated().map { index, value in
            let date = start.addingTimeInterval(Double(index) * 3600)
            return .init(start: date, end: date.addingTimeInterval(3600), decrease: Decimal(string: value)!)
        }
    }
}

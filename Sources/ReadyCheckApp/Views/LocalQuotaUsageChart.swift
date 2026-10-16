import Charts
import ReadyCheckCore
import SwiftUI

struct LocalQuotaUsageChart: View {
    let buckets: [QuotaUsageBucket]
    let localization: LocalizationService
    let axisFormat: Date.FormatStyle
    let revealProgress: Double
    @Binding var inspectedBucketID: TimeInterval?

    private var maximum: Double {
        QuotaUsageAggregation.chartMaximumPercent(for: buckets.map { $0.consumedRatio * 100 })
    }

    private var axisDates: [Date] {
        guard !buckets.isEmpty else { return [] }
        return [0, buckets.count / 2, buckets.count - 1].reduce(into: []) { dates, index in
            let date = buckets[index].start
            if dates.last != date { dates.append(date) }
        }
    }

    var body: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value(localization.text("usage.time"), bucket.start),
                y: .value(localization.text("usage.consumedPercent"), bucket.consumedRatio * 100 * revealProgress),
                width: .fixed(12)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .accessibilityLabel(Text(QuotaUsageTooltip.periodText(bucket, localization: localization)))
            .accessibilityValue(Text(QuotaUsageTooltip.consumptionText(bucket, localization: localization)))
        }
        .chartYScale(domain: 0...maximum)
        .chartXScale(range: .plotDimension(startPadding: 24, endPadding: 24))
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, maximum / 2, maximum]) { value in
                AxisGridLine()
                AxisValueLabel(anchor: .trailing) {
                    if let amount = value.as(Double.self) {
                        Text(amount, format: .number.precision(.fractionLength(0...1)))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                AxisValueLabel(anchor: .top) {
                    if let date = value.as(Date.self) { Text(date.formatted(axisFormat)) }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.background(Color.primary.opacity(0.025)).clipped()
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case let .active(location): inspect(location, proxy: proxy, geometry: geometry)
                        case .ended: inspectedBucketID = nil
                        }
                    }
                    .onTapGesture { location in inspect(location, proxy: proxy, geometry: geometry) }
                    .overlay(alignment: .topLeading) {
                        if let bucket = buckets.first(where: { $0.id == inspectedBucketID }),
                           let anchor = proxy.plotFrame, let x = proxy.position(forX: bucket.start) {
                            let frame = geometry[anchor]
                            QuotaUsageTooltip(bucket: bucket, localization: localization)
                                .offset(x: Self.tooltipLeading(barX: frame.minX + x, plotFrame: frame),
                                        y: frame.minY + 4)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .onChange(of: buckets) { _, _ in inspectedBucketID = nil }
        .frame(height: 178)
    }

    private func inspect(_ location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let anchor = proxy.plotFrame else { inspectedBucketID = nil; return }
        let frame = geometry[anchor]
        let point = CGPoint(x: location.x - frame.minX, y: location.y - frame.minY)
        inspectedBucketID = Self.inspectedBucket(at: point, plotSize: frame.size, buckets: buckets) { bucket in
            guard let x = proxy.position(forX: bucket.start),
                  let y = proxy.position(forY: bucket.consumedRatio * 100 * revealProgress) else { return nil }
            return CGPoint(x: x, y: y)
        }?.id
    }

    static func inspectedBucket(at point: CGPoint, plotSize: CGSize, buckets: [QuotaUsageBucket],
                                position: (QuotaUsageBucket) -> CGPoint?) -> QuotaUsageBucket? {
        guard point.x >= 0, point.x <= plotSize.width, point.y >= 0, point.y <= plotSize.height else { return nil }
        return buckets.compactMap { bucket -> (QuotaUsageBucket, CGFloat)? in
            guard bucket.consumedRatio > 0, let bar = position(bucket),
                  abs(point.x - bar.x) <= 8, point.y >= bar.y else { return nil }
            return (bucket, abs(point.x - bar.x))
        }.min { $0.1 < $1.1 }?.0
    }

    static func tooltipLeading(barX: CGFloat, plotFrame: CGRect) -> CGFloat {
        min(max(barX - 110, plotFrame.minX), max(plotFrame.minX, plotFrame.maxX - 220))
    }
}

struct QuotaUsageTooltip: View {
    let bucket: QuotaUsageBucket
    let localization: LocalizationService

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.periodText(bucket, localization: localization))
                .foregroundStyle(.secondary)
            Text(Self.consumptionText(bucket, localization: localization))
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.caption)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 200, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.12)))
    }

    static func periodText(_ bucket: QuotaUsageBucket, localization: LocalizationService) -> String {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: localization.language.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: bucket.start, to: bucket.end)
    }

    static func consumptionText(_ bucket: QuotaUsageBucket, localization: LocalizationService) -> String {
        let number = (bucket.consumedRatio * 100).formatted(.number
            .precision(.fractionLength(0...1)).locale(Locale(identifier: localization.language.rawValue)))
        return String(format: localization.text("usage.inspectedConsumptionFormat"), number)
    }
}

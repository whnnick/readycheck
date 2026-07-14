import Charts
import ReadyCheckCore
import SwiftUI

struct RecentUsageView: View {
    private enum Range: TimeInterval, CaseIterable, Identifiable {
        case day = 86_400
        case week = 604_800
        case month = 2_592_000

        var id: TimeInterval { rawValue }

        var bucketInterval: TimeInterval {
            switch self {
            case .day: 3_600
            case .week: 6 * 3_600
            case .month: 86_400
            }
        }
    }

    private struct UsageWindow: Identifiable, Equatable {
        let id: String
        let labelKey: String
    }

    let samples: [QuotaHistorySample]
    let localization: LocalizationService
    let now: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedRange: Range = .day
    @State private var selectedWindowID = "codex-primary"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label(localization.text("usage.title"), systemImage: "chart.bar.xaxis")
                    .font(.headline)

                Text(localization.text("usage.localRecord"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.07), in: Capsule())

                Spacer()

                Picker(localization.text("usage.range"), selection: $selectedRange) {
                    ForEach(Range.allCases) { range in
                        Text(rangeTitle(range)).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 184)
            }

            Text(localization.text("usage.subtitle"))
                .font(.caption)
                .foregroundStyle(.secondary)

            if windows.isEmpty {
                collectingState
            } else {
                HStack(spacing: 10) {
                    ForEach(windows) { window in
                        metricCard(window)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(localization.text("usage.lastRecorded"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastRecordedText)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }

                if selectedPoints.count < 2 {
                    collectingState
                } else {
                    Text(chartTitle)
                        .font(.subheadline.weight(.semibold))

                    Chart(buckets) { bucket in
                        BarMark(
                            x: .value(localization.text("usage.time"), bucket.start, unit: axisUnit),
                            y: .value(localization.text("usage.consumedPercent"), bucket.consumedRatio * 100)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .annotation(position: .top, alignment: .center) {
                            if bucket.consumedRatio > 0, bucket == highestBucket {
                                Text(String(format: "%.0f", bucket.consumedRatio * 100))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartYScale(domain: 0...chartMaximum)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yAxisValues) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text("\(Int(amount))")
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: selectedRange == .day ? 5 : 4)) { value in
                            AxisValueLabel(format: axisFormat)
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea.background(Color.primary.opacity(0.025))
                    }
                    .frame(height: 178)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: buckets)

                    if buckets.allSatisfy({ $0.consumedRatio == 0 }) {
                        Text(localization.text("usage.noConsumption"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text((currentRemainingRatio ?? 1) <= 0 ? localization.text("usage.zeroExplanation") : localization.text("usage.help"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var providerSamples: [QuotaHistorySample] {
        samples.filter { $0.providerID == "codex-oauth" }.sorted { $0.recordedAt < $1.recordedAt }
    }

    private var windows: [UsageWindow] {
        let values = providerSamples.flatMap(\.values)
        var seen = Set<String>()
        return values.compactMap { value in
            guard seen.insert(value.windowID).inserted else { return nil }
            return UsageWindow(id: value.windowID, labelKey: value.labelKey)
        }
    }

    private var activeWindow: UsageWindow? {
        windows.first(where: { $0.id == selectedWindowID }) ?? windows.first
    }

    private var selectedPoints: [(date: Date, ratio: Double)] {
        guard let window = activeWindow else { return [] }
        return providerSamples.compactMap { sample in
            guard let value = sample.values.first(where: { $0.windowID == window.id }) else { return nil }
            return (sample.recordedAt, value.remainingRatio)
        }
    }

    private var rangeStart: Date {
        now.addingTimeInterval(-selectedRange.rawValue)
    }

    private var buckets: [QuotaUsageBucket] {
        guard let window = activeWindow else { return [] }
        return QuotaUsageAggregation.buckets(
            samples: providerSamples,
            providerID: "codex-oauth",
            windowID: window.id,
            rangeStart: rangeStart,
            rangeEnd: now,
            bucketInterval: selectedRange.bucketInterval
        )
    }

    private var highestBucket: QuotaUsageBucket? {
        buckets.max { $0.consumedRatio < $1.consumedRatio }
    }

    private var chartMaximum: Double {
        let highest = (buckets.map(\.consumedRatio).max() ?? 0) * 100
        return max(5, ceil(highest / 5) * 5)
    }

    private var yAxisValues: [Double] {
        [0, chartMaximum / 2, chartMaximum]
    }

    private var axisUnit: Calendar.Component {
        switch selectedRange {
        case .day: .hour
        case .week: .hour
        case .month: .day
        }
    }

    private var axisFormat: Date.FormatStyle {
        switch selectedRange {
        case .day: .dateTime.hour()
        case .week: .dateTime.weekday(.abbreviated).hour()
        case .month: .dateTime.month().day()
        }
    }

    private var lastRecordedText: String {
        guard let date = providerSamples.last?.recordedAt else { return localization.text("usage.collecting") }
        return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }

    private var currentRemainingRatio: Double? {
        selectedPoints.last?.ratio
    }

    private var chartTitle: String {
        guard let window = activeWindow else { return "" }
        return "\(localization.text(window.labelKey)) · \(localization.text("usage.barTitle"))"
    }

    private var collectingState: some View {
        ContentUnavailableView {
            Label(localization.text("usage.emptyTitle"), systemImage: "chart.bar.xaxis")
        } description: {
            Text(localization.text("usage.emptyMessage"))
        }
        .frame(maxWidth: .infinity, minHeight: 126)
    }

    private func metricCard(_ window: UsageWindow) -> some View {
        let isSelected = activeWindow?.id == window.id
        let currentRatio = providerSamples.last?.values.first(where: { $0.windowID == window.id })?.remainingRatio
        let consumed = consumedRatio(windowID: window.id)

        return Button {
            selectedWindowID = window.id
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(localization.text(window.labelKey))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(consumed.map { String(format: localization.text("usage.consumedFormat"), $0 * 100) } ?? localization.text("usage.collecting"))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                HStack(spacing: 4) {
                    Text(localization.text("usage.currentRemaining"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(currentRatio.map { String(format: "%.0f%%", $0 * 100) } ?? "--")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle((currentRatio ?? 1) < 0.25 ? .red : .primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.25)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(localization.text(window.labelKey)) \(localization.text("usage.selectWindow"))")
    }

    private func consumedRatio(windowID: String) -> Double? {
        let points = providerSamples.compactMap { sample -> (date: Date, ratio: Double)? in
            guard sample.recordedAt >= rangeStart,
                  let value = sample.values.first(where: { $0.windowID == windowID })
            else { return nil }
            return (sample.recordedAt, value.remainingRatio)
        }
        guard points.count > 1 else { return nil }
        return zip(points, points.dropFirst()).reduce(0) { result, pair in
            let gap = pair.1.date.timeIntervalSince(pair.0.date)
            guard gap > 0, gap <= 10 * 60 else { return result }
            return result + max(0, pair.0.ratio - pair.1.ratio)
        }
    }

    private func rangeTitle(_ range: Range) -> String {
        switch range {
        case .day: localization.text("usage.range.day")
        case .week: localization.text("usage.range.week")
        case .month: localization.text("usage.range.month")
        }
    }
}

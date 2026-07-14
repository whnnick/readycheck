import Charts
import ReadyCheckCore
import SwiftUI

struct RecentUsageView: View {
    private enum Range: TimeInterval, CaseIterable, Identifiable {
        case day = 86_400
        case week = 604_800
        case month = 2_592_000

        var id: TimeInterval { rawValue }
    }

    private struct ChartPoint: Identifiable {
        let recordedAt: Date
        let label: String
        let remainingPercent: Double
        let windowID: String

        var id: String { "\(windowID)-\(recordedAt.timeIntervalSince1970)" }
    }

    let samples: [QuotaHistorySample]
    let localization: LocalizationService
    let now: Date

    @State private var selectedRange: Range = .day

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label(localization.text("usage.title"), systemImage: "chart.xyaxis.line")
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

            if chartPoints.isEmpty {
                ContentUnavailableView {
                    Label(localization.text("usage.emptyTitle"), systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text(localization.text("usage.emptyMessage"))
                }
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                HStack(spacing: 12) {
                    metricCard(labelKey: "quota.window.codex.5h", windowID: "codex-primary")
                    metricCard(labelKey: "quota.window.codex.7d", windowID: "codex-secondary")

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

                Chart(chartPoints) { point in
                    LineMark(
                        x: .value(localization.text("usage.time"), point.recordedAt),
                        y: .value(localization.text("usage.remainingPercent"), point.remainingPercent)
                    )
                    .foregroundStyle(by: .value(localization.text("usage.window"), point.label))
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let percent = value.as(Int.self) {
                                Text("\(percent)%")
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 14)
                .frame(height: 178)

                Text(localization.text("usage.help"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filteredSamples: [QuotaHistorySample] {
        let cutoff = now.addingTimeInterval(-selectedRange.rawValue)
        return samples.filter { $0.providerID == "codex-oauth" && $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    private var chartPoints: [ChartPoint] {
        filteredSamples.flatMap { sample in
            sample.values.map { value in
                ChartPoint(
                    recordedAt: sample.recordedAt,
                    label: localization.text(value.labelKey),
                    remainingPercent: value.remainingRatio * 100,
                    windowID: value.windowID
                )
            }
        }
    }

    private func metricCard(labelKey: String, windowID: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(localization.text(labelKey))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(consumedText(windowID: windowID))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private func consumedText(windowID: String) -> String {
        let values = filteredSamples.compactMap { sample in
            sample.values.first(where: { $0.windowID == windowID })?.remainingRatio
        }
        guard values.count > 1 else { return localization.text("usage.collecting") }
        let consumed = zip(values, values.dropFirst()).reduce(0.0) { result, pair in
            result + max(0, pair.0 - pair.1)
        }
        return String(format: localization.text("usage.consumedFormat"), consumed * 100)
    }

    private var lastRecordedText: String {
        guard let date = filteredSamples.last?.recordedAt else {
            return localization.text("usage.collecting")
        }
        return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }

    private func rangeTitle(_ range: Range) -> String {
        switch range {
        case .day: localization.text("usage.range.day")
        case .week: localization.text("usage.range.week")
        case .month: localization.text("usage.range.month")
        }
    }
}

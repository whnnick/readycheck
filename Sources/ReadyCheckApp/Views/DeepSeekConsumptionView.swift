import Charts
import ReadyCheckCore
import SwiftUI

struct DeepSeekConsumptionView: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    let range: ClosedRange<Date>
    let interval: TimeInterval
    var height: CGFloat = 150
    @State private var inspectedBuckets: [String: Date] = [:]

    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }

    var body: some View {
        ForEach(connection.snapshot?.balances ?? [], id: \.currency) { balance in
            let bins = connection.connectionID.map {
                DeepSeekBalanceConsumption.buckets(observations: connection.history, connectionID: $0,
                    currency: balance.currency, range: range, interval: interval)
            } ?? []
            let observed = bins.compactMap(\.decrease)
            let total = observed.reduce(Decimal.zero, +)
            let positive = bins.filter { ($0.decrease ?? 0) > 0 }
            VStack(alignment: .leading, spacing: 6) {
                Text(text("已观测余额减少", "Observed balance decrease") + " · " + balance.currency)
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                if observed.isEmpty {
                    Text(text("等待连续读数；未观测时段留空。", "Waiting for consecutive readings; unobserved periods stay blank."))
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(NSDecimalNumber(decimal: total).stringValue + " " + balance.currency)
                        .font(.headline).monospacedDigit()
                    if positive.isEmpty {
                        Text(text("此时段未观测到余额减少。", "No balance decrease observed in this period."))
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        DeepSeekDecreaseChart(bins: positive, range: range, interval: interval, compact: height < 100,
                            currency: balance.currency, language: language, inspectedBucketID: Binding(
                                get: { inspectedBuckets[balance.currency] },
                                set: { inspectedBuckets[balance.currency] = $0 }))
                        .frame(height: height)
                        .accessibilityLabel(text("本机观测的余额减少，单位", "Locally observed balance decrease in") + " " + balance.currency)
                    }
                }
            }
        }
    }
}

struct DeepSeekDecreaseChart: View {
    let bins: [DeepSeekConsumptionBucket]
    let range: ClosedRange<Date>
    let interval: TimeInterval
    let compact: Bool
    let currency: String
    let language: AppLanguage
    @Binding var inspectedBucketID: Date?

    private var maximum: Double {
        max(0.00000001, bins.map { NSDecimalNumber(decimal: $0.decrease ?? 0).doubleValue }.max() ?? 0)
    }

    var body: some View {
        Chart(bins) { bin in
            RectangleMark(
                xStart: .value("Start", bin.start.addingTimeInterval(interval * 0.1)),
                xEnd: .value("End", bin.end.addingTimeInterval(-interval * 0.1)),
                yStart: .value("Baseline", 0.0),
                yEnd: .value("Decrease", NSDecimalNumber(decimal: bin.decrease ?? 0).doubleValue)
            ).foregroundStyle(Color.accentColor.gradient)
                .accessibilityLabel(DeepSeekDecreaseTooltip.periodText(bin, language: language))
                .accessibilityValue(DeepSeekDecreaseTooltip.amountText(bin, currency: currency, language: language))
        }
        .chartXScale(domain: range)
        .chartYScale(domain: 0...(maximum * 1.15))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: compact ? 3 : 5)) {
                AxisGridLine()
                AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...8)))
            }
        }
        .chartXAxis {
            if !compact { AxisMarks(values: .automatic(desiredCount: 4)) }
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
                        if let bin = bins.first(where: { $0.id == inspectedBucketID }),
                           let anchor = proxy.plotFrame,
                           let x = proxy.position(forX: bin.start.addingTimeInterval(bin.end.timeIntervalSince(bin.start) / 2)) {
                            let frame = geometry[anchor]
                            DeepSeekDecreaseTooltip(bin: bin, currency: currency, language: language,
                                width: min(220, frame.width))
                                .offset(x: Self.tooltipLeading(barX: frame.minX + x, plotFrame: frame), y: frame.minY + 4)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .onChange(of: bins) { _, _ in inspectedBucketID = nil }
    }

    private func inspect(_ location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let anchor = proxy.plotFrame else { inspectedBucketID = nil; return }
        let plot = geometry[anchor]
        inspectedBucketID = Self.inspectedBucket(at: CGPoint(x: location.x - plot.minX, y: location.y - plot.minY),
            plotSize: plot.size, bins: bins) { bin in
                guard let x1 = proxy.position(forX: bin.start.addingTimeInterval(interval * 0.1)),
                      let x2 = proxy.position(forX: bin.end.addingTimeInterval(-interval * 0.1)),
                      let top = proxy.position(forY: NSDecimalNumber(decimal: bin.decrease ?? 0).doubleValue),
                      let bottom = proxy.position(forY: 0.0) else { return nil }
                return CGRect(x: x1, y: top, width: x2 - x1, height: bottom - top)
            }?.id
    }

    static func inspectedBucket(at point: CGPoint, plotSize: CGSize, bins: [DeepSeekConsumptionBucket],
                                barFrame: (DeepSeekConsumptionBucket) -> CGRect?) -> DeepSeekConsumptionBucket? {
        guard CGRect(origin: .zero, size: plotSize).contains(point) else { return nil }
        return bins.first { bin in
            guard let amount = bin.decrease, amount > 0, let frame = barFrame(bin) else { return false }
            return frame.contains(point)
        }
    }

    static func tooltipLeading(barX: CGFloat, plotFrame: CGRect) -> CGFloat {
        let width = min(220, plotFrame.width)
        return min(max(barX - width / 2, plotFrame.minX), plotFrame.maxX - width)
    }
}

struct DeepSeekDecreaseTooltip: View {
    let bin: DeepSeekConsumptionBucket
    let currency: String
    let language: AppLanguage
    var width: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.periodText(bin, language: language)).foregroundStyle(.secondary)
            Text(Self.amountText(bin, currency: currency, language: language))
                .fontWeight(.semibold).monospacedDigit()
        }
        .font(.caption).fixedSize(horizontal: false, vertical: true)
        .frame(width: max(0, width - 20), alignment: .leading).padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.12)))
    }

    static func periodText(_ bin: DeepSeekConsumptionBucket, language: AppLanguage) -> String {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: bin.start, to: bin.end)
    }

    static func amountText(_ bin: DeepSeekConsumptionBucket, currency: String, language: AppLanguage) -> String {
        let amount = bin.decrease.map { NSDecimalNumber(decimal: $0).stringValue } ?? "—"
        return (language == .zhCN ? "已观测减少 " : "Observed decrease ") + amount + " " + currency
    }
}

struct DeepSeekRefreshFeedback: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }
    var body: some View {
        HStack(spacing: 6) {
            if connection.isBusy {
                ProgressView().controlSize(.small)
                Text(text("正在更新 DeepSeek 余额…", "Updating DeepSeek balance…"))
            } else if let result = connection.refreshOutcome {
                Image(systemName: result == .failed ? "exclamationmark.triangle" : "checkmark.circle")
                Text(result == .failed ? (connection.snapshot == nil
                    ? text("更新失败，请检查连接", "Update failed; check the connection")
                    : text("更新失败，保留上次读数", "Update failed; keeping the last reading"))
                    : result == .unchanged ? text("更新成功，余额未变化", "Updated; balance unchanged")
                    : text("余额已更新", "Balance updated"))
            }
        }
        .font(.caption).foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}

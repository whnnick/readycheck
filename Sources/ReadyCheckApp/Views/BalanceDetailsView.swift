import ReadyCheckCore
import SwiftUI

struct BalanceDetailsView: View {
    let model: ReadyCheckAppModel
    let now: Date
    var isPinned = false
    var onTogglePin: (() -> Void)?
    var compact = false
    let openMainWindow: () -> Void
    @State private var inspectedBuckets: [String: Date] = [:]

    private func text(_ zh: String, _ en: String) -> String { model.language == .zhCN ? zh : en }
    private var readings: [BalanceSurfaceReading] { DeepSeekDisplay.readings(connection: model.deepSeek, now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if readings.isEmpty {
                        Text(model.deepSeek.isBusy ? text("正在读取余额…", "Reading balance…")
                             : model.deepSeek.credentialError ? text("需要系统授权", "System access required")
                             : text("暂无余额读数", "No balance reading"))
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    ForEach(readings) { reading in
                        currencySummary(reading)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.scrollIndicators(.hidden)
            footer
        }
        .foregroundStyle(.white).tint(.cyan)
        .environment(\.colorScheme, .dark)
    }

    var header: some View {
        WidgetDetailHeader(model: model, now: now, isPinned: isPinned, onTogglePin: onTogglePin)
    }

    var footer: some View {
        WidgetDetailFooter(model: model, openMainWindow: openMainWindow)
    }

    func currencySummary(_ reading: BalanceSurfaceReading) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 9) {
            HStack(alignment: .center, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(reading.currency).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                Text(BalanceSurfaceReading.amount(reading.total))
                    .font(.system(size: compact ? 28 : 30, weight: .semibold, design: .rounded)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
                }.layoutPriority(1)
                Spacer(minLength: 0)
                if reading.granted != nil || reading.toppedUp != nil {
                    Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        if let granted = reading.granted {
                            breakdown(text("赠送", "Granted"), amount: granted)
                        }
                        if let toppedUp = reading.toppedUp {
                            breakdown(text("充值", "Topped up"), amount: toppedUp)
                        }
                    }.frame(maxWidth: compact ? 116 : 132, alignment: .leading)
                }
            }.accessibilityElement(children: .combine)
            if reading.isStale {
                Label(text("上次读数，待确认", "Last reading, unconfirmed"), systemImage: "clock.badge.exclamationmark")
                    .font(.caption).foregroundStyle(.orange)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(text("近1小时减少", "Last-hour decrease")).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Text(reading.observedDecrease.map { BalanceSurfaceReading.amount($0) + " " + reading.currency } ?? "—")
                    .font(.system(size: 12, weight: .semibold)).monospacedDigit()
            }
            historyChart(reading)
            Text(text("本机观测，非官方账单 · 缺口留空", "Local observation, not billing · gaps stay blank"))
                .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func breakdown(_ label: String, amount: Decimal) -> some View {
        HStack(spacing: 6) {
            Text(label).foregroundStyle(.secondary)
            Text(BalanceSurfaceReading.amount(amount)).fontWeight(.medium).monospacedDigit()
        }.font(.system(size: 11)).lineLimit(1).minimumScaleFactor(0.7)
    }

    @ViewBuilder
    private func historyChart(_ reading: BalanceSurfaceReading) -> some View {
        let end = max(now, model.deepSeek.observedAt ?? now)
        let bins = DeepSeekDisplay.buckets(connection: model.deepSeek, currency: reading.currency, now: end)
            .filter { ($0.decrease ?? 0) > 0 }
        if !bins.isEmpty {
            DeepSeekDecreaseChart(bins: bins, range: end.addingTimeInterval(-3600)...end, interval: 300,
                compact: true, currency: reading.currency, language: model.language,
                inspectedBucketID: Binding(get: { inspectedBuckets[reading.currency] },
                    set: { inspectedBuckets[reading.currency] = $0 }))
                .frame(height: compact ? 60 : 102)
        } else {
            Text(reading.observedDecrease == nil
                 ? text("等待连续读数，未观测时段留空。", "Waiting for consecutive readings; gaps stay blank.")
                 : text("此时段未观测到余额减少。", "No balance decrease observed in this period."))
                .font(.caption).foregroundStyle(.secondary).frame(minHeight: 38, alignment: .leading)
        }
    }
}

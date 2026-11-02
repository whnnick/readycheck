import ReadyCheckCore
import SwiftUI

struct ServiceCompactReadout: View {
    let model: ReadyCheckAppModel
    let now: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var balance: BalanceSurfaceReading? {
        DeepSeekDisplay.readings(connection: model.deepSeek, now: now).first
    }
    private var quota: ProviderQuotaSnapshot? { model.snapshots.first { $0.providerId == "codex-oauth" } }
    private var window: QuotaWindow? {
        model.notchQuotaSelection.resolve(in: quota?.windows.filter(QuotaWindowPresentation.shouldShow) ?? [])
    }
    private var isBalance: Bool { model.selectedService.presentation.readoutKind == .balance }
    private var timestamp: Date? { isBalance ? model.deepSeek.observedAt : quota?.refreshedAt }

    var body: some View {
        HStack(spacing: 8) {
            ServiceSwitcherIcon(name: isBalance ? "deepseek" : "readycheck", extension: isBalance ? "svg" : "png")
                .frame(width: 18, height: 18)
            if !isBalance {
                Rectangle().fill(.white.opacity(0.16)).frame(width: 1, height: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                if isBalance {
                    Text(balanceHeading).font(.system(size: 9)).foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                Text(primaryText).font(.system(size: 13, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.7)
                if !isBalance {
                    Text(secondaryText).font(.system(size: 9)).foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).layoutPriority(1)
            QuotaMiniTrendChart(values: chartValues, minimumScale: isBalance ? 0.00000001 : 0.01)
                .frame(width: isBalance ? 46 : 36, height: 20).accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .foregroundStyle(.white)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: timestamp)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((isBalance ? "DeepSeek " : "Codex ") + primaryText + ", " + secondaryText)
        .help(isBalance ? secondaryText : "")
    }

    var balanceHeading: String {
        if model.deepSeek.isBusy || model.deepSeek.credentialError || model.deepSeek.error != nil
            || balance == nil || balance?.isStale == true { return secondaryText }
        return balance?.currency ?? "DeepSeek"
    }

    var primaryText: String {
        if isBalance {
            guard let balance, !balance.isStale else { return "—" }
            return balance.total.formatted(.number.precision(.fractionLength(2...4)))
        }
        let ratio = NotchStatusView.ratio(for: window, snapshot: quota, now: now)
        return (window.map(QuotaWindowDisplay.shortLabel) ?? "Codex") + " " + QuotaFormatters.percentageText(for: ratio)
    }

    var secondaryText: String {
        if isBalance {
            if model.deepSeek.isBusy { return model.language == .zhCN ? "正在更新" : "Updating" }
            if model.deepSeek.credentialError { return model.language == .zhCN ? "需要系统授权" : "System access required" }
            if model.deepSeek.error != nil { return model.language == .zhCN ? "更新失败" : "Update failed" }
            if balance == nil { return model.language == .zhCN ? "连接未就绪" : "Connection not ready" }
            if balance?.isStale == true { return model.language == .zhCN ? "读数待确认" : "Reading unconfirmed" }
            guard let amount = balance?.observedDecrease else { return model.language == .zhCN ? "等待连续读数" : "Collecting readings" }
            return (model.language == .zhCN ? "近1h减少 " : "1h decrease ") + BalanceSurfaceReading.amount(amount)
        }
        if quota?.isCached != true, quota?.canShowPercentages(now: now) == true,
           let reset = window?.resetAt, reset > now {
            return reset.formatted(date: reset.timeIntervalSince(now) > 86400 ? .abbreviated : .omitted,
                time: .shortened) + (model.language == .zhCN ? " 重置" : " reset")
        }
        return model.language == .zhCN ? "重置时间待确认" : "Reset unconfirmed"
    }

    private var chartValues: [Double?] {
        if isBalance { return balance?.chartValues ?? Array(repeating: nil, count: 12) }
        guard let window else { return Array(repeating: nil, count: 12) }
        return QuotaMiniTrend.values(samples: model.quotaHistorySamples, providerID: "codex-oauth", windowID: window.id, now: now)
    }
}

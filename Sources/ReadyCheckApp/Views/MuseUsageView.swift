import ReadyCheckCore
import SwiftUI

struct MuseUsageView: View {
    let connection: MuseConnection
    let language: AppLanguage
    var now = Date()
    var detailed = true
    var progressColor: Color?
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Muse").font(.headline)
                Spacer()
                Text(connection.snapshot?.plan ?? text("周额度", "Weekly allowance")).font(.caption).foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(QuotaFormatters.percentageText(for: connection.remainingRatio(now: now)))
                    .font(.system(size: detailed ? 34 : 22, weight: .semibold, design: .rounded)).monospacedDigit()
                Text(text("本周剩余", "remaining this week")).font(.caption).foregroundStyle(.secondary)
            }
            if let ratio = connection.remainingRatio(now: now) {
                GeometryReader { geometry in
                    Capsule().fill(.secondary.opacity(0.2))
                        .overlay(alignment: .leading) {
                            Capsule().fill(progressColor ?? OrbitalQuotaDial.color(for: ratio)).frame(width: geometry.size.width * ratio)
                        }
                }.frame(height: 4).accessibilityLabel(text("本周剩余", "Remaining this week"))
                    .accessibilityValue(QuotaFormatters.percentageText(for: ratio))
            } else {
                Capsule().fill(.secondary.opacity(0.2)).frame(height: 4)
            }
            Text(connection.statusText(language: language, now: now))
                .font(.caption).foregroundStyle(connection.error == nil ? Color.secondary : .orange)
                .fixedSize(horizontal: false, vertical: true)
            if let date = connection.snapshot?.resetsAt {
                Text(text("重置：", "Resets: ") + date.formatted(.dateTime.locale(Locale(identifier: language.rawValue)).month().day().hour().minute()))
                    .font(.caption).foregroundStyle(.secondary)
            }
            if detailed {
                if let label = connection.snapshot?.usageLabel {
                    Text(label).font(.caption).foregroundStyle(.secondary)
                }
                if let label = connection.snapshot?.additionalLabel {
                    LabeledContent(text("额外额度", "Additional allowance"), value: label).font(.caption)
                }
                if let date = connection.snapshot?.renewsAt {
                    LabeledContent(date > now ? text("订阅续期", "Subscription renewal") : text("订阅日期（历史）", "Subscription date (past)"),
                                   value: date.formatted(date: .abbreviated, time: .omitted)).font(.caption)
                }
                Text(LocalizationService(language: language).text("dashboard.refreshCadence"))
                    .font(.caption2).foregroundStyle(.secondary)
                if let date = connection.observedAt {
                    Text(text("最近读取：", "Last read: ") + date.formatted(date: .omitted, time: .standard)).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MuseConnectionControls: View {
    let model: ReadyCheckAppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muse · muse.ai").font(.headline)
            Text(model.language == .zhCN
                 ? "登录 Muse 应用账户后读取周额度、重置和套餐。登录会话单独保存在 ReadyCheck 中。"
                 : "Sign in to your Muse app account to read weekly allowance, reset and plan. The sign-in session stays separate in ReadyCheck.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text(model.muse.statusText(language: model.language, now: Date())).font(.caption).foregroundStyle(.secondary)
            HStack {
                Button(model.language == .zhCN ? "登录 / 重新登录 Muse" : "Sign in / reconnect Muse") {
                    model.selectedService = .muse
                    model.muse.connect(language: model.language)
                }.disabled(model.muse.isBusy)
                Button(model.localization.text("action.refresh")) { Task { await model.muse.refresh() } }
                    .disabled(!model.muse.isEnabled || model.muse.isBusy)
                if model.muse.isEnabled {
                    Button(model.language == .zhCN ? "断开连接" : "Disconnect") { Task { await model.muse.disconnect() } }
                }
            }
            Text(model.language == .zhCN ? "仅查询用量，不发送模型请求；此连接不读取 Muse Code 或 Meta API 账单。"
                 : "Usage reads only, with no model requests. This connection does not read Muse Code or Meta API billing.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MuseCompactReadout: View {
    let connection: MuseConnection
    let language: AppLanguage
    let now: Date
    var vertical = false
    var body: some View {
        Group {
            if vertical {
                VStack(spacing: 8) {
                    Text("M").font(.headline)
                    Text("7d").font(.caption2)
                    Text(percentage).font(.system(size: 10, weight: .semibold)).monospacedDigit()
                }
            } else {
                HStack(spacing: 10) {
                    Text("M").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Muse 7d " + percentage).font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text(connection.statusText(language: language, now: now)).font(.system(size: 9)).foregroundStyle(.white.opacity(0.6))
                    }.lineLimit(1).minimumScaleFactor(0.7)
                }.padding(.horizontal, 12)
            }
        }.foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var percentage: String { QuotaFormatters.percentageText(for: connection.remainingRatio(now: now)) }
}

extension MuseConnection {
    func statusText(language: AppLanguage, now: Date) -> String {
        let zh = language == .zhCN
        if !isEnabled { return zh ? "尚未连接 Muse" : "Muse is not connected" }
        if isBusy { return zh ? "正在读取" : "Reading usage" }
        switch error {
        case .loginRequired: return zh ? "请登录或重新登录 Muse" : "Sign in to Muse again"
        case .network, .timedOut: return zh ? "读取失败，请稍后刷新" : "Read failed. Refresh to retry"
        case .responseChanged: return zh ? "用量页面已变化，暂时无法读取" : "Usage page changed; reading unavailable"
        case nil: break
        }
        guard let snapshot, let observedAt else { return zh ? "登录后点击读取额度" : "Sign in, then read usage" }
        guard snapshot.isCurrent(observedAt: observedAt, now: now) else { return zh ? "读数待刷新确认" : "Refresh to confirm the reading" }
        return zh ? "额度已更新" : "Usage is up to date"
    }
}

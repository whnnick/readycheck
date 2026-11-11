import ReadyCheckCore
import SwiftUI

struct AggregateCapsuleDetailView: View {
    let model: ReadyCheckAppModel
    let service: ServiceSettingsTarget
    let isPinned: Bool
    let onTogglePin: () -> Void
    let onHover: (Bool) -> Void
    @State private var now = Date()

    var body: some View {
        VStack(spacing: 12) {
            WidgetDetailHeader(model: model, now: now, isPinned: isPinned, onTogglePin: onTogglePin, service: service)
            Divider().overlay(.white.opacity(0.08))
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    switch service {
                    case .codex: codexDetails
                    case .muse: MuseUsageView(connection: model.muse, language: model.language, now: now,
                        progressColor: AggregateServiceMark.ringColor(model.muse.remainingRatio(now: now), normal: AggregateServiceMark.tint(.muse)))
                    case .deepSeek:
                        let details = BalanceDetailsView(model: model, now: now, openMainWindow: {})
                        let readings = DeepSeekDisplay.readings(connection: model.deepSeek, now: now)
                        if readings.isEmpty {
                            Text(model.language == .zhCN ? "暂无余额，请在连接设置中重试。" : "No balance. Retry in connection settings.")
                                .font(.callout).foregroundStyle(.secondary)
                        }
                        ForEach(readings) { details.currencySummary($0) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.scrollIndicators(.hidden)
            WidgetDetailFooter(model: model, openMainWindow: {
                model.selectedService = service
                model.mainWindowPage = .overview
                model.openMainWindowFromWidget()
            }, service: service)
        }
        .padding(16).foregroundStyle(.white).environment(\.colorScheme, .dark)
        .background(AggregateCapsuleSurface())
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onHover(perform: onHover)
        .task { while !Task.isCancelled { now = Date(); try? await Task.sleep(for: .seconds(1)) } }
        .onChange(of: model.muse.observedAt) { _, _ in now = Date() }
    }

    @ViewBuilder private var codexDetails: some View {
        let snapshot = model.snapshots.first { $0.providerId == "codex-oauth" }
        if let snapshot {
            ForEach(snapshot.windows.filter(QuotaWindowPresentation.shouldShow)) { window in
                let ratio = NotchStatusView.ratio(for: window, snapshot: snapshot, now: now)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(QuotaWindowDisplay.title(for: window, localization: model.localization)).font(.callout).foregroundStyle(.secondary)
                        Spacer()
                        Text(QuotaFormatters.percentageText(for: ratio)).font(.system(size: 27, weight: .semibold, design: .rounded)).monospacedDigit()
                    }
                    GeometryReader { proxy in
                        Capsule().fill(.white.opacity(0.1)).overlay(alignment: .leading) {
                            Capsule().fill(AggregateServiceMark.ringColor(ratio, normal: .cyan)).frame(width: proxy.size.width * (ratio ?? 0))
                        }
                    }.frame(height: 4)
                    if let reset = window.resetAt {
                        Text((model.language == .zhCN ? "重置：" : "Resets: ") + reset.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Text(model.language == .zhCN ? "Codex 尚无额度读数，请在连接设置中重试。" : "No Codex reading. Retry in connection settings.")
                .font(.callout).foregroundStyle(.secondary)
        }
    }
}

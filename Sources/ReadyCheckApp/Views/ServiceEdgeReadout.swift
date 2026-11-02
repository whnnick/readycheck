import ReadyCheckCore
import SwiftUI

struct ServiceEdgeReadout: View {
    let model: ReadyCheckAppModel
    let now: Date
    private var isBalance: Bool { model.selectedService.presentation.readoutKind == .balance }
    private var reading: BalanceSurfaceReading? { DeepSeekDisplay.readings(connection: model.deepSeek, now: now).first }
    private var snapshot: ProviderQuotaSnapshot? { model.snapshots.first { $0.providerId == "codex-oauth" } }

    var body: some View {
        VStack(spacing: 8) {
            ServiceSwitcherIcon(name: isBalance ? "deepseek" : "readycheck", extension: isBalance ? "svg" : "png")
            if isBalance {
                Text(reading?.currency ?? "DS").font(.system(size: 8, weight: .medium)).foregroundStyle(.white.opacity(0.65))
                Text(reading.flatMap { $0.isStale ? nil : $0.total }?.formatted(.number.precision(.fractionLength(2...4))) ?? "—")
                    .font(.system(size: 10, weight: .semibold, design: .rounded)).monospacedDigit()
                    .frame(width: 22).lineLimit(2).minimumScaleFactor(0.6)
                QuotaMiniTrendChart(values: reading?.chartValues ?? [], minimumScale: 0.00000001)
                    .frame(width: 40, height: 18)
                    .rotationEffect(.degrees(90))
                    .frame(width: 18, height: 40)
            } else {
                ForEach(model.notchQuotaSelection.displayWindows(in:
                    snapshot?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []).prefix(2)) { window in
                    let ratio = NotchStatusView.ratio(for: window, snapshot: snapshot, now: now)
                    Capsule().fill(.white.opacity(0.18))
                        .overlay(alignment: .bottom) {
                            Capsule().fill(color(ratio)).frame(height: 40 * max(0, min(ratio ?? 0, 1)))
                        }.frame(width: 6, height: 40)
                }
            }
        }
        .foregroundStyle(.white)
        .frame(width: BubbleWidgetPlacement.tabSize.width, height: BubbleWidgetPlacement.tabSize.height)
        .accessibilityHidden(true)
    }

    private func color(_ ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: .green
        case .warning: .orange
        case .critical, .exhausted: .red
        case .unknown: .gray
        }
    }
}

import ReadyCheckCore
import SwiftUI

struct CompactQuotaRow: View {
    let window: QuotaWindow
    let snapshot: ProviderQuotaSnapshot
    let localization: LocalizationService
    let now: Date

    var body: some View {
        let ratio = snapshot.canShowPercentages(now: now) ? window.displayableRemainingRatio : nil
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(QuotaWindowDisplay.title(for: window, localization: localization))
                    .font(.subheadline.weight(.semibold)).lineLimit(2)
                Spacer(minLength: 8)
                Text(QuotaFormatters.percentageText(for: ratio))
                    .font(.system(size: 24, weight: .semibold, design: .rounded)).monospacedDigit()
            }
            GeometryReader { geometry in
                Capsule().fill(Color.primary.opacity(0.10))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color(ratio)).frame(width: geometry.size.width * max(0, min(1, ratio ?? 0)))
                    }
            }.frame(height: 4)
            Text(QuotaResetCountdown(window: window, snapshot: snapshot, now: now).text(localization: localization))
                .font(.caption2).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func color(_ ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: .green
        case .warning: .orange
        case .critical, .exhausted: .red
        case .unknown: .secondary
        }
    }
}

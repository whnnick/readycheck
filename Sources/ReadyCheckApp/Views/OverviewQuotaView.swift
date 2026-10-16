import ReadyCheckCore
import SwiftUI

struct OverviewQuotaView: View {
    @Bindable var model: ReadyCheckAppModel
    let now: Date

    private var snapshot: ProviderQuotaSnapshot? {
        model.snapshots.first { $0.providerId == "codex-oauth" }
    }

    private var windows: [QuotaWindow] {
        let reported = snapshot?.windows ?? []
        guard !reported.isEmpty else {
            return [NotchQuotaSelection.fiveHour, .sevenDay].compactMap { $0.displayWindows(in: []).first }
        }
        return model.notchQuotaSelection.displayWindows(in: reported, primaryFirst: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(windows) { window in card(window) }
            }
            if let snapshot, snapshot.isCached != true {
                Text(model.localization.text(snapshot.availabilityTextKey(now: now)))
                    .font(.caption).foregroundStyle(.secondary)
            }
            if snapshot?.isCached == true {
                Label(model.localization.text("overview.cached"), systemImage: "clock.badge.exclamationmark")
                    .font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func card(_ window: QuotaWindow) -> some View {
        let ratio = snapshot?.canShowPercentages(now: now) == true ? window.displayableRemainingRatio : nil
        let primary = model.notchQuotaSelection.displayWindows(in: snapshot?.windows ?? []).first?.id == window.id
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(QuotaWindowDisplay.title(for: window, localization: model.localization))
                    .font(.subheadline.weight(.semibold)).lineLimit(2)
                Spacer(minLength: 0)
                if primary {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(.secondary)
                        .accessibilityLabel(model.localization.text("overview.primary"))
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(QuotaFormatters.percentageText(for: ratio))
                    .font(.system(size: 40, weight: .semibold, design: .rounded)).monospacedDigit()
                Text(model.localization.text("overview.remaining"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                Capsule().fill(Color.primary.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color(ratio))
                            .frame(width: geometry.size.width * max(0, min(1, ratio ?? 0)))
                    }
            }.frame(height: 5)
            Text(QuotaResetCountdown(window: window, snapshot: snapshot, now: now).text(localization: model.localization))
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            if let resetAt = window.resetAt {
                Text("\(model.localization.text("quota.resetAt")) \(resetAt.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue)).month().day().hour().minute()))")
                    .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
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

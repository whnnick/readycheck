import ReadyCheckCore
import SwiftUI

struct NotchStatusView: View {
    @Bindable var model: ReadyCheckAppModel

    @State private var now = Date()

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.75), radius: 4)

                Text("Codex")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer(minLength: 4)

                quotaItem
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.16))

                    Capsule()
                        .fill(quotaColor(displayedRatio).gradient)
                        .frame(width: proxy.size.width * max(0, min(displayedRatio ?? 0, 1)))
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 13)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 14,
                bottomTrailingRadius: 14,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(Color.black.opacity(0.94))
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 14,
                    bottomTrailingRadius: 14,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.openMainWindowFromWidget()
        }
        .help(model.localization.text("notch.openMainWindow"))
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private var snapshot: ProviderQuotaSnapshot? {
        model.snapshots.first { $0.providerId == "codex-oauth" }
    }

    private var statusColor: Color {
        QuotaUrgency(remainingRatio: displayedRatio).hasRemainingQuota ? .green : .gray
    }

    private var displayedWindow: QuotaWindow? {
        let windows = snapshot?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []
        return windows.first(where: { $0.labelKey == "quota.window.codex.7d" })
            ?? windows.first
    }

    private var displayedRatio: Double? {
        guard snapshot?.canShowPercentages(now: now) == true else { return nil }
        return displayedWindow?.remainingRatio
    }

    private var displayedWindowLabel: String {
        switch displayedWindow?.labelKey {
        case "quota.window.codex.7d", "quota.sevenDay":
            "7d"
        case "quota.window.codex.5h", "quota.fiveHour":
            "5h"
        default:
            "Limit"
        }
    }

    private var quotaItem: some View {
        HStack(spacing: 4) {
            Text(displayedWindowLabel)
                .foregroundStyle(.white.opacity(0.58))
            Text(QuotaFormatters.percentageText(for: displayedRatio))
                .foregroundStyle(quotaColor(displayedRatio))
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .monospacedDigit()
        .fixedSize()
    }

    private func quotaColor(_ ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal:
            .green
        case .warning:
            .orange
        case .critical, .exhausted:
            .red
        case .unknown:
            .white.opacity(0.58)
        }
    }
}

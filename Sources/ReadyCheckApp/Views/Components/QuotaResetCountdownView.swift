import ReadyCheckCore
import SwiftUI

struct QuotaResetCountdownView: View {
    let window: QuotaWindow
    let snapshot: ProviderQuotaSnapshot?
    let localization: LocalizationService

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(QuotaResetCountdown(window: window, snapshot: snapshot, now: context.date)
                .text(localization: localization))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .monospacedDigit()
                .help(window.resetAt.map {
                    localization.text("quota.resetAt") + " "
                        + DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short)
                } ?? localization.text("quota.resetUnknown"))
        }
    }
}

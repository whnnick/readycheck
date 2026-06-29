import ReadyCheckCore
import SwiftUI

struct QuotaCardView: View {
    enum DisplayMode {
        case full
        case compact
    }

    let snapshot: ProviderQuotaSnapshot
    let localization: LocalizationService
    let now: Date
    let displayMode: DisplayMode

    init(
        snapshot: ProviderQuotaSnapshot,
        localization: LocalizationService,
        now: Date,
        displayMode: DisplayMode = .compact
    ) {
        self.snapshot = snapshot
        self.localization = localization
        self.now = now
        self.displayMode = displayMode
    }

    private var canShowPercentages: Bool {
        snapshot.canShowPercentages(now: now)
    }

    private var isStale: Bool {
        snapshot.isStale(now: now)
    }

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: 12) {
                header

                if snapshot.windows.isEmpty {
                    errorContent
                } else {
                    detailGrid

                    VStack(spacing: 10) {
                        ForEach(snapshot.windows) { window in
                            windowRow(window)
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(snapshot.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.82), in: Capsule())

            Spacer()

            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12), in: Capsule())
        }
    }

    private var detailGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            summaryRows

            if displayMode == .full {
                VStack(alignment: .leading, spacing: 5) {
                    if manualResetExpirations.isEmpty {
                        inlineDetail(
                            label: localization.text("quota.manualResetExpires"),
                            value: localization.text("quota.notProvided")
                        )
                    } else {
                        ForEach(Array(manualResetExpirations.enumerated()), id: \.offset) { index, date in
                            inlineDetail(
                                label: index == 0 ? localization.text("quota.manualResetExpires") : "",
                                value: "\(localization.text("quota.manualResetIndex")) \(index + 1) \(localization.text("quota.manualResetTimes")) - \(dateText(for: date, forceFullDate: true))"
                            )
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
    }

    private var summaryRows: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 18) {
                subscriptionSummaryItems
            }

            VStack(alignment: .leading, spacing: 5) {
                subscriptionSummaryItems
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.86)
    }

    private func inlineDetail(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.58))

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.92))
                .monospacedDigit()
                .truncationMode(.tail)
                .help(value)
        }
    }

    @ViewBuilder
    private var subscriptionSummaryItems: some View {
        inlineDetail(
            label: localization.text("quota.plan"),
            value: displayPlanName
        )

        inlineDetail(
            label: localization.text("quota.subscriptionRenewal"),
            value: subscriptionRenewalText
        )

        inlineDetail(
            label: localization.text("quota.manualResetCount"),
            value: manualResetCountText
        )
    }

    private var displayPlanName: String {
        guard let plan = nonEmpty(snapshot.details?.planName) else {
            return localization.text("quota.notProvided")
        }

        return plan.prefix(1).uppercased() + String(plan.dropFirst())
    }

    private var subscriptionRenewalText: String {
        guard let date = snapshot.details?.subscriptionRenewalAt else {
            return localization.text("quota.notProvided")
        }

        return dateText(for: date, forceFullDate: true)
    }

    private var manualResetCountText: String {
        if let count = snapshot.details?.manualResetCount {
            return "\(count)"
        }

        let expirations = manualResetExpirations
        return "\(expirations.count)"
    }

    private var manualResetExpirations: [Date] {
        snapshot.details?.manualResetExpirations ?? []
    }

    private func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return nil
    }

    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if snapshot.errors.isEmpty {
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else {
                ForEach(snapshot.errors, id: \.self) { error in
                    Text(localization.text(error))
                        .font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .lineLimit(2)
                }
            }
        }
    }

    private func windowRow(_ window: QuotaWindow) -> some View {
        let ratio = canShowPercentages ? window.remainingRatio : nil
        let showsProgress = ratio != nil
        let progress = ratio ?? 0

        return VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(localization.text(window.labelKey))
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(canShowPercentages ? QuotaFormatters.percentageText(for: ratio) : "—")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(showsProgress ? .primary : .tertiary)

                    if let resetAt = window.resetAt {
                        Text(dateText(for: resetAt))
                            .font(.headline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(Color.primary.opacity(0.58))
                            .lineLimit(1)
                    }
                }
            }

            QuotaProgressBar(
                progress: progress,
                tint: progressTint(for: progress),
                isActive: showsProgress
            )

            Text(metadataText(for: window))
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .lineLimit(2)
        }
    }

    private var statusText: String {
        if isStale {
            return localization.text("status.stale")
        }

        return switch snapshot.status {
        case .available:
            localization.text("status.available")
        case .estimated:
            localization.text("status.estimated")
        case .unavailable:
            localization.text("status.unavailable")
        case .error:
            localization.text("status.error")
        }
    }

    private var statusColor: Color {
        if isStale {
            return .orange
        }

        return switch snapshot.status {
        case .available:
            .green
        case .estimated:
            .orange
        case .unavailable:
            .secondary
        case .error:
            .red
        }
    }

    private func confidenceText(_ confidence: QuotaConfidence) -> String {
        switch confidence {
        case .verified:
            localization.text("confidence.verified")
        case .estimated:
            localization.text("confidence.estimated")
        case .manual:
            localization.text("confidence.manual")
        case .unknown:
            localization.text("confidence.unknown")
        }
    }

    private func sourceText(_ source: ProviderSource) -> String {
        switch source {
        case .mock:
            localization.text("source.mock")
        case .local:
            localization.text("source.local")
        case .usageAPI:
            localization.text("source.usageAPI")
        case .costAPI:
            localization.text("source.costAPI")
        case .oauthAPI:
            localization.text("source.oauthAPI")
        case .manual:
            localization.text("source.manual")
        }
    }

    private func metadataText(for window: QuotaWindow) -> String {
        [
            sourceText(snapshot.source),
            confidenceText(window.confidence)
        ].joined(separator: " · ")
    }

    private func dateText(for date: Date, forceFullDate: Bool = false) -> String {
        let calendar = Calendar.current
        let dateStyle: DateFormatter.Style = forceFullDate || !calendar.isDate(date, inSameDayAs: now) ? .short : .none
        return DateFormatter.localizedString(from: date, dateStyle: dateStyle, timeStyle: .short)
    }

    private func progressTint(for progress: Double) -> Color {
        switch progress {
        case 0..<0.25:
            .red
        case 0.25..<0.5:
            .orange
        default:
            .green
        }
    }
}

private struct QuotaProgressBar: View {
    let progress: Double
    let tint: Color
    let isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)
            let width = proxy.size.width * clampedProgress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.14))

                Capsule()
                    .fill(isActive ? tint.gradient : Color.primary.opacity(0.22).gradient)
                    .frame(width: width)
            }
        }
        .frame(height: 7)
        .opacity(isActive ? 1 : 0.55)
        .accessibilityHidden(true)
    }
}

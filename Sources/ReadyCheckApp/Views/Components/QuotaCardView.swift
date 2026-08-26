import ReadyCheckCore
import SwiftUI

struct QuotaCardView: View {
    enum DisplayMode {
        case full
        case widgetDetailed
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

    private var visibleWindows: [QuotaWindow] {
        snapshot.windows.filter(QuotaWindowPresentation.shouldShow)
    }

    private var firstLimitStateWindowID: String? {
        visibleWindows.first(where: { limitStateText($0.limitStateCode) != nil })?.id
    }

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: 12) {
                header

                if visibleWindows.isEmpty {
                    errorContent
                } else {
                    if showsDetails {
                        detailGrid
                    }

                    VStack(spacing: 10) {
                        ForEach(visibleWindows) { window in
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

            if showsDetails {
                VStack(alignment: .leading, spacing: 5) {
                    if manualResetCount == nil {
                        inlineDetail(
                            label: localization.text("quota.manualResetExpires"),
                            value: localization.text("quota.manualResetUnavailable")
                        )
                    } else if manualResetCount == 0 {
                        inlineDetail(
                            label: localization.text("quota.manualResetExpires"),
                            value: localization.text("quota.manualResetNone")
                        )
                    } else {
                        ForEach(0..<(manualResetCount ?? 0), id: \.self) { index in
                            inlineDetail(
                                label: index == 0 ? localization.text("quota.manualResetExpires") : "",
                                value: manualResetExpirationText(index: index)
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
    }

    private func inlineDetail(label: String, value: String) -> some View {
        Group {
            if displayMode == .widgetDetailed {
                VStack(alignment: .leading, spacing: 2) {
                    if !label.isEmpty {
                        Text(label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.58))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.92))
                        .monospacedDigit()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .help(value)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.58))
                        .lineLimit(1)

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.92))
                        .monospacedDigit()
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(value)
                }
            }
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

        if let creditBalanceText {
            inlineDetail(
                label: localization.text("quota.codexCredits"),
                value: creditBalanceText
            )
        }
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

    private var manualResetExpirations: [Date] {
        snapshot.details?.manualResetExpirations ?? []
    }

    private var manualResetCount: Int? {
        snapshot.details?.manualResetCount
            ?? (manualResetExpirations.isEmpty ? nil : manualResetExpirations.count)
    }

    private var creditBalanceText: String? {
        if snapshot.details?.creditsUnlimited == true {
            return localization.text("quota.creditsUnlimited")
        }

        guard let rawBalance = nonEmpty(snapshot.details?.creditBalance),
              let decimal = Decimal(string: rawBalance, locale: Locale(identifier: "en_US_POSIX"))
        else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return formatter.string(from: NSDecimalNumber(decimal: decimal)) ?? rawBalance
    }

    private func manualResetExpirationText(index: Int) -> String {
        let prefix = "\(localization.text("quota.manualResetIndex")) \(index + 1) \(localization.text("quota.manualResetTimes"))"
        let expirationText = manualResetExpirations.indices.contains(index)
            ? dateText(for: manualResetExpirations[index], forceFullDate: true)
            : localization.text("quota.manualResetExpirationUnavailable")
        if displayMode == .widgetDetailed {
            return "\(prefix)\n\(expirationText)"
        }
        return "\(prefix) - \(expirationText)"
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
            if !snapshot.windows.isEmpty, visibleWindows.isEmpty {
                Text(localization.text("quota.currentSevenDayUnavailable"))
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else if snapshot.errors.isEmpty {
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
                Text(windowTitle(window))
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

            if showsMetadata {
                Text(metadataText(for: window))
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .lineLimit(2)
            }

            let currentUrgency = urgency(for: progress, isActive: showsProgress)
            if window.id == firstLimitStateWindowID,
               let limitStateText = limitStateText(window.limitStateCode) {
                Label(limitStateText, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            } else if shouldShowLowQuotaWarning(urgency: currentUrgency) {
                Label(lowQuotaWarningText(for: currentUrgency), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        currentUrgency == .critical || currentUrgency == .exhausted ? .red : .orange
                    )
                    .lineLimit(1)
            }
        }
    }

    private var statusText: String {
        if isStale {
            return localization.text("status.stale")
        }

        guard !visibleWindows.isEmpty else {
            return localization.text("status.unavailable")
        }

        if let stateText = visibleWindows.lazy.compactMap({ limitStateText($0.limitStateCode) }).first {
            return stateText
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

    private var showsDetails: Bool {
        switch displayMode {
        case .full, .widgetDetailed:
            true
        case .compact:
            false
        }
    }

    private var showsMetadata: Bool {
        displayMode == .full
    }

    private var statusColor: Color {
        if isStale {
            return .orange
        }

        guard !visibleWindows.isEmpty else {
            return .secondary
        }

        if visibleWindows.contains(where: { limitStateText($0.limitStateCode) != nil }) {
            return .red
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

    private func windowTitle(_ window: QuotaWindow) -> String {
        if let displayLabel = window.displayLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !displayLabel.isEmpty {
            if window.labelKey == "quota.window.codex.secondary" {
                return "\(displayLabel) · \(localization.text("quota.window.secondarySuffix"))"
            }
            return displayLabel
        }
        return localization.text(window.labelKey)
    }

    private func limitStateText(_ code: String?) -> String? {
        guard let code else { return nil }
        return switch code {
        case "rate_limit_reached": localization.text("quota.limit.rateLimitReached")
        case "workspace_owner_credits_depleted": localization.text("quota.limit.ownerCreditsDepleted")
        case "workspace_member_credits_depleted": localization.text("quota.limit.memberCreditsDepleted")
        case "workspace_owner_usage_limit_reached": localization.text("quota.limit.ownerUsageLimitReached")
        case "workspace_member_usage_limit_reached": localization.text("quota.limit.memberUsageLimitReached")
        default: localization.text("quota.limit.reached")
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
        case .appServer:
            localization.text("source.appServer")
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
        switch urgency(for: progress, isActive: true) {
        case .exhausted:
            .red
        case .critical:
            .red
        case .warning:
            .orange
        case .normal:
            .green
        case .unknown:
            .secondary
        }
    }

    private func urgency(for progress: Double, isActive: Bool) -> QuotaUrgency {
        guard isActive else { return .unknown }
        return QuotaUrgency(remainingRatio: progress)
    }

    private func shouldShowLowQuotaWarning(urgency: QuotaUrgency) -> Bool {
        urgency.shouldDisplayWarning
    }

    private func lowQuotaWarningText(for urgency: QuotaUrgency) -> String {
        switch urgency {
        case .exhausted:
            localization.text("quota.exhaustedWarning")
        case .critical:
            localization.text("quota.criticalQuotaWarning")
        default:
            localization.text("quota.lowQuotaWarning")
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

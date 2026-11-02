import ReadyCheckCore
import SwiftUI

struct NotchStatusView: View {
    @Bindable var model: ReadyCheckAppModel

    var isExpanded = false
    var isDragging = false
    var presentationAnimation: Animation?
    var collapsedWidth: CGFloat?
    var onClick: () -> Void = {}
    var onDismiss: () -> Void = {}

    @State private var now = Date()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                compactContent
                    .frame(width: min(collapsedWidth ?? geometry.size.width, geometry.size.width),
                           height: NotchStatusPlacement.defaultHeight)
                    .transaction { $0.animation = nil }
                    .opacity(isExpanded ? 0 : 1)
                    .animation(presentationAnimation?.speed(2), value: isExpanded)
                    .position(x: geometry.size.width / 2, y: NotchStatusPlacement.defaultHeight / 2)
                    .allowsHitTesting(!isExpanded).accessibilityHidden(isExpanded)
                NotchDetailsView(model: model, now: now, onDismiss: onDismiss)
                    .frame(width: 360, height: 264)
                    // Fade the content without animating its internal text layout.
                    .transaction { $0.animation = nil }
                    .opacity(isExpanded ? 1 : 0)
                    .animation(presentationAnimation?.speed(isExpanded ? 1 : 2).delay(isExpanded ? 0.10 : 0), value: isExpanded)
                    .position(x: geometry.size.width / 2, y: 132)
                    .allowsHitTesting(isExpanded).accessibilityHidden(!isExpanded)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .background(notchBackground.animation(presentationAnimation, value: isExpanded))
        .clipped()
        .transaction { $0.animation = nil }
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private var compactContent: some View {
        Group {
            if model.selectedService.presentation.readoutKind == .balance {
                ServiceCompactReadout(model: model, now: now)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(notchShape)
                .onTapGesture(perform: onClick)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onClick() }
                .help(model.localization.text("notch.previewHint"))
            } else if model.notchShowsBothQuotas {
                dualStatus
            } else { compactStatus }
        }
    }

    private var notchShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: isExpanded || isDragging ? 20 : 0, bottomLeadingRadius: isExpanded ? 22 : 16,
            bottomTrailingRadius: isExpanded ? 22 : 16, topTrailingRadius: isExpanded || isDragging ? 20 : 0, style: .continuous)
    }

    private var notchBackground: some View {
        notchShape.fill(.black)
            .overlay(notchShape.strokeBorder(.white.opacity(0.10), lineWidth: 0.6))
    }

    private var dualStatus: some View {
        let windows = Self.dualWindows(in: snapshot?.windows ?? [])
        return VStack(spacing: 5) {
            quotaLine("5h", window: windows[0])
            quotaLine("7d", window: windows[1])
        }
        .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(notchShape)
        .onTapGesture(perform: onClick)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onClick() }
        .help(model.localization.text("notch.previewHint"))
    }

    private func quotaLine(_ label: String, window: QuotaWindow?) -> some View {
        let ratio = Self.ratio(for: window, snapshot: snapshot, now: now)
        return HStack(spacing: 6) {
            Text(label).foregroundStyle(.white.opacity(0.7)).frame(width: 17, alignment: .leading)
            GeometryReader { geometry in
                Capsule().fill(.white.opacity(0.16))
                    .overlay(alignment: .leading) {
                        Capsule().fill(quotaColor(ratio).gradient)
                            .frame(width: geometry.size.width * max(0, min(ratio ?? 0, 1)))
                    }
            }.frame(height: 3)
            Text(QuotaFormatters.percentageText(for: ratio)).foregroundStyle(quotaColor(ratio))
                .frame(width: 32, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .medium, design: .rounded)).monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Codex " + label)
        .accessibilityValue(QuotaFormatters.percentageText(for: ratio))
    }

    static func dualWindows(in windows: [QuotaWindow]) -> [QuotaWindow?] {
        [windows.first { $0.durationMinutes == 300 || $0.labelKey == "quota.window.codex.5h" || $0.labelKey == "quota.fiveHour" },
         windows.first { $0.durationMinutes == 10080 || $0.labelKey == "quota.window.codex.7d" || $0.labelKey == "quota.sevenDay" }]
    }

    static func ratio(for window: QuotaWindow?, snapshot: ProviderQuotaSnapshot?, now: Date) -> Double? {
        guard snapshot?.isCached != true, snapshot?.canShowPercentages(now: now) == true else { return nil }
        return window?.displayableRemainingRatio
    }

    private var compactStatus: some View {
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
        .contentShape(notchShape)
        .onTapGesture(perform: onClick)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onClick() }
        .help(model.localization.text("notch.previewHint"))
    }

    private var snapshot: ProviderQuotaSnapshot? {
        model.snapshots.first { $0.providerId == "codex-oauth" }
    }

    private var statusColor: Color {
        QuotaUrgency(remainingRatio: displayedRatio).hasRemainingQuota ? .green : .gray
    }

    private var displayedWindow: QuotaWindow? {
        let windows = snapshot?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []
        return model.notchQuotaSelection.displayWindows(in: windows).first
    }

    private var displayedRatio: Double? {
        guard snapshot?.canShowPercentages(now: now) == true else { return nil }
        return displayedWindow?.displayableRemainingRatio
    }

    private var displayedWindowLabel: String {
        displayedWindow.map(QuotaWindowDisplay.shortLabel) ?? "—"
    }

    private var quotaItem: some View {
        HStack(spacing: 4) {
            if snapshot?.isCached == true {
                Image(systemName: "clock.badge.exclamationmark")
                    .accessibilityLabel(model.localization.text("status.stale"))
            }
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

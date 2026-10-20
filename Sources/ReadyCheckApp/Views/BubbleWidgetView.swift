import AppKit
import ReadyCheckCore
import SwiftUI

struct BubbleQuotaDisplay: Equatable {
    let selection: NotchQuotaSelection
    let windowID: String?
    let ratio: Double?

    func shouldHighlight(after previous: Self) -> Bool {
        guard selection == previous.selection,
              let windowID, windowID == previous.windowID,
              let ratio, let previousRatio = previous.ratio else { return false }
        return ratio > previousRatio + 0.005
    }
}

struct BubbleWidgetView: View {
    @Bindable var model: ReadyCheckAppModel
    let isExpanded: Bool
    var isPinned = true
    var onPin: () -> Void = {}
    var onTogglePin: () -> Void = {}
    let tabEdge: BubbleWidgetPlacement.Edge?
    let onTap: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onCollapse: () -> Void

    @State private var now = Date()
    @State private var recoveryHighlight = false

    private var snapshot: ProviderQuotaSnapshot? {
        model.snapshots.first { $0.providerId == "codex-oauth" }
    }

    private var windows: [QuotaWindow] {
        snapshot?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []
    }

    private var primaryWindow: QuotaWindow? {
        model.notchQuotaSelection.resolve(in: windows)
    }

    private var primaryRatio: Double? {
        guard snapshot?.canShowPercentages(now: now) == true else { return nil }
        return primaryWindow?.displayableRemainingRatio
    }

    private var displayedQuota: BubbleQuotaDisplay {
        BubbleQuotaDisplay(selection: model.notchQuotaSelection, windowID: primaryWindow?.id, ratio: primaryRatio)
    }

    private var primaryWindowShortLabel: String {
        expandedWindows.first.map(QuotaWindowDisplay.shortLabel) ?? "—"
    }

    var expandedWindows: [QuotaWindow] {
        model.notchQuotaSelection.displayWindows(in: windows)
    }

    private var floatingSurfaceColor: Color {
        Color(red: 0.10, green: 0.12, blue: 0.15)
    }

    private func quotaColor(for ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: .green
        case .warning: .orange
        case .critical, .exhausted: .red
        case .unknown: .gray
        }
    }

    var body: some View {
        Group {
            if let tabEdge { attachedSurface(tabEdge) }
            else { orbitalSurface }
        }
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(30))
            }
        }
        .onChange(of: displayedQuota) { oldQuota, newQuota in
            recoveryHighlight = newQuota.shouldHighlight(after: oldQuota)
            guard recoveryHighlight else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                recoveryHighlight = false
            }
        }
    }

    private var orbitalSurface: some View {
        GeometryReader { geometry in
            let reveal = min(1, max(0, (geometry.size.width - 140) / 200))
            let shape = WidgetPanelShape()
            ZStack {
                shape.fill(floatingSurfaceColor)
                    .overlay(shape.strokeBorder(.white.opacity(0.22), lineWidth: 1))
                    .onTapGesture { if isExpanded { onPin() } }
                expandedDetails
                    .frame(width: max(0, geometry.size.width - 32), height: max(0, geometry.size.height - 32))
                    .clipped().padding(16)
                    .opacity(reveal).allowsHitTesting(isExpanded && reveal > 0.9)
                    .accessibilityHidden(!isExpanded)
                OrbitalQuotaDial(windows: expandedWindows, primaryLabel: primaryWindowShortLabel,
                    canShow: snapshot?.canShowPercentages(now: now) == true, recoveryHighlight: recoveryHighlight)
                    .overlay(alignment: .topTrailing) {
                        if snapshot?.isCached == true {
                            Image(systemName: "clock.badge.exclamationmark").font(.caption).foregroundStyle(.orange)
                        }
                    }
                    .frame(width: 76, height: 76).opacity(1 - reveal)
                    .contentShape(Circle()).onTapGesture(perform: onTap)
                    .simultaneousGesture(dragGesture).contextMenu { contextMenu }
                    .allowsHitTesting(!isExpanded).accessibilityHidden(isExpanded)
                    .accessibilityAddTraits(.isButton).accessibilityAction { onTap() }
                    .help(model.localization.text("widget.previewHint"))
                    .accessibilityLabel(model.localization.text("bubble.accessibility") + " "
                        + expandedWindows.prefix(2).map {
                            QuotaWindowDisplay.title(for: $0, localization: model.localization) + " "
                                + QuotaFormatters.percentageText(for: snapshot?.canShowPercentages(now: now) == true ? $0.displayableRemainingRatio : nil)
                        }.joined(separator: ", "))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func attachedSurface(_ edge: BubbleWidgetPlacement.Edge) -> some View {
        GeometryReader { geometry in
            let progress = min(1, max(0, (geometry.size.width - BubbleWidgetPlacement.tabSize.width)
                / (BubbleWidgetPlacement.expandedSize.width - BubbleWidgetPlacement.tabSize.width)))
            let reveal = min(1, max(0, (geometry.size.width - 140) / 200))
            let shape = WidgetPanelShape(tabProgress: 1 - progress)
            ZStack(alignment: edge == .left ? .leading : .trailing) {
                bubbleSurface(shape)
                    .onTapGesture { if isExpanded { onPin() } }
                expandedDetails
                    .frame(width: max(0, geometry.size.width - 32), height: max(0, geometry.size.height - 32))
                    .clipped().padding(16)
                    .opacity(reveal).allowsHitTesting(isExpanded && reveal > 0.9)
                    .accessibilityHidden(!isExpanded)
                edgeTab(edge)
                    .opacity(1 - min(1, progress * 4))
                    .allowsHitTesting(!isExpanded).accessibilityHidden(isExpanded)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func edgeTab(_ edge: BubbleWidgetPlacement.Edge) -> some View {
        VStack(spacing: 10) {
            codexIcon.frame(width: 16, height: 16)
            ForEach(expandedWindows.prefix(2)) { window in
                let ratio = snapshot?.canShowPercentages(now: now) == true ? window.displayableRemainingRatio : nil
                Capsule().fill(Color.white.opacity(0.18))
                    .overlay(alignment: .bottom) {
                        Capsule().fill(quotaColor(for: ratio))
                            .frame(height: 44 * max(0, min(ratio ?? 0, 1)))
                    }
                    .frame(width: 6, height: 44)
            }
        }
        .frame(width: BubbleWidgetPlacement.tabSize.width, height: BubbleWidgetPlacement.tabSize.height)
        .foregroundStyle(.white)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onTap)
        .simultaneousGesture(dragGesture)
        .contextMenu { contextMenu }
        .help(model.localization.text("widget.previewHint"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .accessibilityLabel(model.localization.text("bubble.accessibility") + " " + expandedWindows.prefix(2).map {
            QuotaWindowDisplay.title(for: $0, localization: model.localization) + " "
                + QuotaFormatters.percentageText(for: snapshot?.canShowPercentages(now: now) == true ? $0.displayableRemainingRatio : nil)
        }.joined(separator: ", "))
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                codexIcon.frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ReadyCheck").font(.system(size: 14, weight: .semibold))
                    Text("Codex · " + model.localization.text(snapshot?.availabilityTextKey(now: now) ?? "status.unavailable"))
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
                Spacer()
                Button(action: onTogglePin) {
                    Label(model.localization.text(isPinned ? "widget.pinStateOn" : "widget.pinStateOff"),
                        systemImage: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isPinned ? Color.cyan : .white.opacity(0.75))
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(isPinned ? Color.blue.opacity(0.15) : .white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .help(model.localization.text(isPinned ? "bubble.unpinHelp" : "bubble.pinHelp"))
                .accessibilityLabel(model.localization.text(isPinned ? "widget.unpinDetails" : "widget.pinDetails"))
                .accessibilityValue(model.localization.text(isPinned ? "widget.pinStateOn" : "widget.pinStateOff"))
            }

            if let snapshot, !windows.isEmpty {
                ScrollView(.vertical) {
                    VStack(spacing: 8) {
                        ForEach(expandedWindows) { window in
                            quotaRow(window, canShow: snapshot.canShowPercentages(now: now))
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: .infinity)
            } else {
                Text(model.localization.text("empty.quota.title"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if let pace = model.quotaPace(now: now) {
                QuotaPaceView(pace: pace, localization: model.localization, now: now, compact: true)
            }
            miniTrend
            if snapshot?.isCached == true {
                Text(model.localization.text("status.stale")).font(.caption2).foregroundStyle(.orange)
            }

            HStack {
                Text(snapshot.map { model.localization.text("status.lastUpdated") + " "
                    + DateFormatter.localizedString(from: $0.refreshedAt, dateStyle: .none, timeStyle: .short) } ?? "—")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                Spacer(minLength: 6)
                Button {
                    model.mainWindowPage = .settings
                    model.mainSettingsSection = .reminders
                    model.openMainWindowFromWidget()
                } label: {
                    Image(systemName: "bell")
                }
                .buttonStyle(.plain)
                .help(model.localization.text("navigation.reminders"))
                .accessibilityLabel(model.localization.text("navigation.reminders"))
                Button {
                    openMainWindow()
                } label: {
                    Text(model.localization.text("bubble.openMainWindow"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(red: 0.10, green: 0.65, blue: 1))
                }
                .buttonStyle(.plain)
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.white)
        .tint(Color(red: 0.62, green: 0.80, blue: 1))
        .onTapGesture { if !isPinned { onPin() } }
    }

    func openMainWindow() {
        model.mainWindowPage = .overview
        model.openMainWindowFromWidget()
        if !isPinned { onCollapse() }
    }

    private func quotaRow(_ window: QuotaWindow, canShow: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(quotaColor(for: canShow ? window.displayableRemainingRatio : nil))
                .frame(width: 8, height: 8).padding(.top, 16)
            if let snapshot {
                CompactQuotaRow(window: window, snapshot: snapshot, localization: model.localization, now: now)
                    .environment(\.colorScheme, .dark)
            }
        }
    }

    private var codexIcon: some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable().scaledToFit().accessibilityHidden(true)
    }

    var lastHourValues: [Double?] {
        primaryWindow.map {
            QuotaMiniTrend.values(samples: model.quotaHistorySamples, providerID: "codex-oauth",
                                  windowID: $0.id, now: now)
        } ?? [Double?](repeating: nil, count: 12)
    }

    private var miniTrend: some View {
        let values = lastHourValues
        return VStack(alignment: .leading, spacing: 4) {
            Text(String(format: model.localization.text("orbital.recentConsumption"),
                primaryWindow.map { QuotaWindowDisplay.title(for: $0, localization: model.localization) } ?? "—"))
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            Text(model.localization.text("orbital.trendCaption"))
                .font(.system(size: 9)).foregroundStyle(.white.opacity(0.5))
            if values.contains(where: { $0 != nil }) {
                QuotaMiniTrendChart(values: values)
                .frame(height: 22)
                .accessibilityLabel(model.localization.text("orbital.trendHelp"))
            } else {
                Text(model.localization.text("orbital.collecting"))
                    .font(.caption2).foregroundStyle(.white.opacity(0.5))
                    .frame(height: 20)
            }
        }
        .help(model.localization.text("orbital.trendHelp"))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { onDragChanged($0.translation) }
            .onEnded { _ in onDragEnded() }
    }

    private func bubbleSurface<S: InsettableShape>(_ shape: S) -> some View {
        shape.fill(floatingSurfaceColor)
            .overlay(shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button(model.localization.text("bubble.openDetails"), action: onTap)
        Button(model.localization.text("bubble.openMainWindow")) { model.openMainWindowFromWidget() }
        Divider()
        WidgetSnoozeMenu(model: model)
        Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
    }
}

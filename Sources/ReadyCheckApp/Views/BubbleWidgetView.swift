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
    var isPinned = false
    var onTogglePin: () -> Void = {}
    var onServiceChange: () -> Void = {}
    let tabEdge: BubbleWidgetPlacement.Edge?
    let onTap: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onCollapse: () -> Void

    @State private var now = Date()
    @State private var recoveryHighlight = false

    private var previewHint: String {
        let hint = model.localization.text("widget.previewHint")
        guard model.notchStatusAvailable else { return hint }
        return hint + "\n" + (model.language == .zhCN
            ? "拖到刘海附近松开，切换为刘海显示。"
            : "Drop near the notch to switch to notch display.")
    }

    private var snapshot: ProviderQuotaSnapshot? {
        model.snapshots.first { $0.providerId == "codex-oauth" }
    }

    private var windows: [QuotaWindow] {
        snapshot?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []
    }

    private var primaryWindow: QuotaWindow? {
        model.notchQuotaSelection.resolve(in: windows)
    }

    private var displayedQuota: BubbleQuotaDisplay {
        BubbleQuotaDisplay(selection: model.notchQuotaSelection, windowID: primaryWindow?.id,
            ratio: snapshot?.canShowPercentages(now: now) == true ? primaryWindow?.displayableRemainingRatio : nil)
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
        .onChange(of: model.quickDisplayService) { onServiceChange() }
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
            let size = model.bubbleRestingSize
            let reveal = min(1, max(0, (geometry.size.width - size.width)
                / (BubbleWidgetPlacement.expandedSize.width - size.width)))
            let shape = WidgetPanelShape(compactWidth: size.width)
            ZStack {
                shape.fill(floatingSurfaceColor)
                    .overlay(shape.strokeBorder(.white.opacity(0.22), lineWidth: 1))
                expandedDetails
                    .frame(width: max(0, geometry.size.width - 32), height: max(0, geometry.size.height - 32))
                    .clipped().padding(16)
                    .opacity(reveal).allowsHitTesting(isExpanded && reveal > 0.9)
                    .accessibilityHidden(!isExpanded)
                Group {
                    if model.quickDisplayService == nil {
                        Image(systemName: "slider.horizontal.3").foregroundStyle(.white)
                    } else if model.quickDisplayService == .muse {
                        MuseCompactReadout(connection: model.muse, language: model.language, now: now)
                    } else if model.quickDisplayService == .deepSeek {
                        ServiceCompactReadout(model: model, now: now)
                    } else {
                        OrbitalQuotaDial(windows: expandedWindows,
                            primaryLabel: expandedWindows.first.map(QuotaWindowDisplay.shortLabel) ?? "—",
                            canShow: snapshot?.canShowPercentages(now: now) == true, recoveryHighlight: recoveryHighlight)
                            .frame(width: 76, height: 76)
                            .overlay(alignment: .topTrailing) {
                                if snapshot?.isCached == true {
                                    Image(systemName: "clock.badge.exclamationmark").font(.caption).foregroundStyle(.orange)
                                }
                            }
                    }
                }
                    .frame(width: size.width, height: size.height)
                    .opacity(1 - reveal)
                    .contentShape(Capsule()).onTapGesture(perform: openPreviewOrSettings)
                    .simultaneousGesture(dragGesture).contextMenu { contextMenu }
                    .allowsHitTesting(!isExpanded).accessibilityHidden(isExpanded)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton).accessibilityAction { openPreviewOrSettings() }
                    .help(model.quickDisplayService == nil ? model.localization.text("settings.quickDisplay") : previewHint)
                    .accessibilityLabel(compactAccessibilityLabel)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func attachedSurface(_ edge: BubbleWidgetPlacement.Edge) -> some View {
        GeometryReader { geometry in
            let progress = min(1, max(0, (geometry.size.width - BubbleWidgetPlacement.tabSize.width)
                / (BubbleWidgetPlacement.expandedSize.width - BubbleWidgetPlacement.tabSize.width)))
            let size = model.bubbleRestingSize
            let reveal = min(1, max(0, (geometry.size.width - size.width)
                / (BubbleWidgetPlacement.expandedSize.width - size.width)))
            let shape = WidgetPanelShape(tabProgress: 1 - progress, compactWidth: size.width)
            ZStack(alignment: edge == .left ? .leading : .trailing) {
                bubbleSurface(shape)
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
        Group {
            if model.quickDisplayService == nil { Image(systemName: "slider.horizontal.3") }
            else if model.quickDisplayService == .muse { MuseCompactReadout(connection: model.muse, language: model.language, now: now, vertical: true) }
            else { ServiceEdgeReadout(model: model, now: now) }
        }
        .frame(width: BubbleWidgetPlacement.tabSize.width, height: BubbleWidgetPlacement.tabSize.height)
        .foregroundStyle(.white)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: openPreviewOrSettings)
        .simultaneousGesture(dragGesture)
        .contextMenu { contextMenu }
        .help(model.quickDisplayService == nil ? model.localization.text("settings.quickDisplay") : previewHint)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { openPreviewOrSettings() }
        .accessibilityLabel(compactAccessibilityLabel)
    }

    private var expandedDetails: some View {
        Group {
            if model.quickDisplayService == nil {
                VStack(alignment: .leading, spacing: 12) {
                    WidgetDetailHeader(model: model, now: now, isPinned: isPinned, onTogglePin: onTogglePin)
                    Button(model.localization.text("settings.quickDisplay"), action: model.showQuickDisplaySettings)
                    Spacer()
                }.foregroundStyle(.white).environment(\.colorScheme, .dark)
            } else if model.quickDisplayService == .muse {
                VStack(alignment: .leading, spacing: 10) {
                    WidgetDetailHeader(model: model, now: now, isPinned: isPinned, onTogglePin: onTogglePin)
                    ScrollView { MuseUsageView(connection: model.muse, language: model.language, now: now) }
                    WidgetDetailFooter(model: model, openMainWindow: openMainWindow)
                }.foregroundStyle(.white).environment(\.colorScheme, .dark)
            } else if model.quickDisplayService == .deepSeek {
                BalanceDetailsView(model: model, now: now, isPinned: isPinned,
                    onTogglePin: onTogglePin, openMainWindow: openMainWindow)
            } else {
                quotaExpandedDetails
            }
        }
    }

    private var quotaExpandedDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetDetailHeader(model: model, now: now, isPinned: isPinned, onTogglePin: onTogglePin)

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

            NextEventsView(model: model, now: now, compact: true, openMain: model.openMainWindowFromWidget)
            miniTrend
            WidgetDetailFooter(model: model, openMainWindow: openMainWindow)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.white)
        .tint(Color(red: 0.62, green: 0.80, blue: 1))
    }

    private var compactAccessibilityLabel: String {
        switch model.quickDisplayService {
        case .muse:
            return "Muse 7d " + QuotaFormatters.percentageText(for: model.muse.remainingRatio(now: now))
        case .deepSeek:
            return "DeepSeek API " + DeepSeekDisplay.balanceText(connection: model.deepSeek, now: now)
        case .codex:
            let canShow = snapshot?.canShowPercentages(now: now) == true
            let remaining = expandedWindows.prefix(2).map { window in
                QuotaWindowDisplay.title(for: window, localization: model.localization) + " "
                    + QuotaFormatters.percentageText(for: canShow ? window.displayableRemainingRatio : nil)
            }.joined(separator: ", ")
            return model.localization.text("bubble.accessibility") + " " + remaining
        case nil:
            return model.localization.text("settings.quickDisplay")
        }
    }

    private func openPreviewOrSettings() {
        if model.quickDisplayService == nil { model.showQuickDisplaySettings() }
        else { onTap() }
    }

    func openMainWindow() {
        model.openQuickDisplayOverview()
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
        if model.quickDisplayService != nil {
            Button(model.localization.text("bubble.openDetails"), action: onTap)
        }
        Button(model.localization.text("bubble.openMainWindow"), action: openMainWindow)
        Button(model.localization.text("settings.quickDisplay"), action: model.showQuickDisplaySettings)
        Divider()
        WidgetSnoozeMenu(model: model)
        Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
    }
}

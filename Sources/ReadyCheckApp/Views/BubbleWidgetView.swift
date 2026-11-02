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
    let tabEdge: BubbleWidgetPlacement.Edge?
    let onTap: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onCollapse: () -> Void

    @State private var now = Date()

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
    }

    private var orbitalSurface: some View {
        GeometryReader { geometry in
            let reveal = min(1, max(0, (geometry.size.width - BubbleWidgetPlacement.bubbleSize.width)
                / (BubbleWidgetPlacement.expandedSize.width - BubbleWidgetPlacement.bubbleSize.width)))
            let shape = WidgetPanelShape()
            ZStack {
                shape.fill(floatingSurfaceColor)
                    .overlay(shape.strokeBorder(.white.opacity(0.22), lineWidth: 1))
                expandedDetails
                    .frame(width: max(0, geometry.size.width - 32), height: max(0, geometry.size.height - 32))
                    .clipped().padding(16)
                    .opacity(reveal).allowsHitTesting(isExpanded && reveal > 0.9)
                    .accessibilityHidden(!isExpanded)
                ServiceCompactReadout(model: model, now: now)
                    .frame(width: BubbleWidgetPlacement.bubbleSize.width, height: BubbleWidgetPlacement.bubbleSize.height)
                    .opacity(1 - reveal)
                    .contentShape(Capsule()).onTapGesture(perform: onTap)
                    .simultaneousGesture(dragGesture).contextMenu { contextMenu }
                    .allowsHitTesting(!isExpanded).accessibilityHidden(isExpanded)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton).accessibilityAction { onTap() }
                    .help(previewHint)
                    .accessibilityLabel(model.selectedDeepSeek ? "DeepSeek API " + DeepSeekDisplay.balanceText(connection: model.deepSeek, now: now) : model.localization.text("bubble.accessibility") + " "
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
            let reveal = min(1, max(0, (geometry.size.width - BubbleWidgetPlacement.bubbleSize.width)
                / (BubbleWidgetPlacement.expandedSize.width - BubbleWidgetPlacement.bubbleSize.width)))
            let shape = WidgetPanelShape(tabProgress: 1 - progress)
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
        ServiceEdgeReadout(model: model, now: now)
        .frame(width: BubbleWidgetPlacement.tabSize.width, height: BubbleWidgetPlacement.tabSize.height)
        .foregroundStyle(.white)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onTap)
        .simultaneousGesture(dragGesture)
        .contextMenu { contextMenu }
        .help(previewHint)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .accessibilityLabel(model.selectedDeepSeek ? "DeepSeek API " + DeepSeekDisplay.balanceText(connection: model.deepSeek, now: now) : model.localization.text("bubble.accessibility") + " " + expandedWindows.prefix(2).map {
            QuotaWindowDisplay.title(for: $0, localization: model.localization) + " "
                + QuotaFormatters.percentageText(for: snapshot?.canShowPercentages(now: now) == true ? $0.displayableRemainingRatio : nil)
        }.joined(separator: ", "))
    }

    private var expandedDetails: some View {
        Group {
            if model.selectedService.presentation.readoutKind == .balance {
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

            if !model.selectedDeepSeek {
                NextEventsView(model: model, now: now, compact: true, openMain: model.openMainWindowFromWidget)
                miniTrend
            }
            WidgetDetailFooter(model: model, openMainWindow: openMainWindow)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.white)
        .tint(Color(red: 0.62, green: 0.80, blue: 1))
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

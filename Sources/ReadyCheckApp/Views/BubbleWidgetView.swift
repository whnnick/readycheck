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
    var expansionSide: BubbleWidgetPlacement.Edge = .right
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
        return primaryWindow?.remainingRatio
    }

    private var displayedQuota: BubbleQuotaDisplay {
        BubbleQuotaDisplay(selection: model.notchQuotaSelection, windowID: primaryWindow?.id, ratio: primaryRatio)
    }

    private var refreshDate: String? {
        guard let snapshot else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: snapshot.refreshedAt)
    }

    private var primaryWindowShortLabel: String {
        primaryWindow.map(QuotaWindowDisplay.shortLabel) ?? "—"
    }

    var expandedWindows: [QuotaWindow] {
        guard let primaryWindow else { return windows }
        return [primaryWindow] + windows.filter { $0.id != primaryWindow.id }
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
            if !isExpanded, let tabEdge { edgeTab(tabEdge) }
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
            let size = geometry.size
            let orbWidth = BubbleWidgetPlacement.dialDiameter(in: size)
            let detailWidth = max(0, size.width - orbWidth)
            let reveal = min(1, max(0, (detailWidth - 24) / 200))
            let shape = OrbitalWidgetShape(orbOnLeft: expansionSide == .left)
            ZStack {
                shape.fill(LinearGradient(colors: [Color(red: 0.13, green: 0.15, blue: 0.18),
                    Color(red: 0.055, green: 0.065, blue: 0.075)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.38), .white.opacity(0.10),
                        .white.opacity(0.27)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                expandedDetails
                    .frame(width: max(190, detailWidth - 48), height: max(0, size.height - 32))
                    .frame(width: detailWidth, height: size.height)
                    .clipped()
                    .opacity(reveal)
                    .allowsHitTesting(isExpanded && reveal > 0.9)
                    .accessibilityHidden(!isExpanded)
                    .position(x: expansionSide == .left ? orbWidth + detailWidth / 2 : detailWidth / 2,
                              y: size.height / 2)
                OrbitalQuotaDial(windows: expandedWindows, canShow: snapshot?.canShowPercentages(now: now) == true,
                    expansion: reveal, recoveryHighlight: recoveryHighlight)
                    .frame(width: max(0, orbWidth - 16), height: max(0, orbWidth - 16))
                    .contentShape(Circle())
                    .onTapGesture(perform: onTap)
                    .simultaneousGesture(dragGesture)
                    .contextMenu { contextMenu }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { onTap() }
                    .help(model.localization.text(isPinned && isExpanded ? "bubble.pinnedHint" : "widget.previewHint"))
                    .accessibilityLabel(model.localization.text("bubble.accessibility") + " "
                        + (expandedWindows.isEmpty ? QuotaFormatters.percentageText(for: nil) : expandedWindows.prefix(2).map {
                            QuotaWindowDisplay.title(for: $0, localization: model.localization) + " "
                                + QuotaFormatters.percentageText(for: snapshot?.canShowPercentages(now: now) == true ? $0.remainingRatio : nil)
                        }.joined(separator: ", ")))
                    .position(x: expansionSide == .left ? orbWidth / 2 : size.width - orbWidth / 2,
                              y: size.height / 2)
            }
        }
    }

    private func edgeTab(_ edge: BubbleWidgetPlacement.Edge) -> some View {
        VStack(spacing: 10) {
            codexIcon.frame(width: 16, height: 16)
            ForEach(expandedWindows.prefix(2)) { window in
                let ratio = snapshot?.canShowPercentages(now: now) == true ? window.remainingRatio : nil
                Capsule().fill(Color.white.opacity(0.18))
                    .overlay(alignment: .bottom) {
                        Capsule().fill(quotaColor(for: ratio))
                            .frame(height: 44 * max(0, min(ratio ?? 0, 1)))
                    }
                    .frame(width: 6, height: 44)
            }
        }
        .frame(width: BubbleWidgetPlacement.tabSize.width, height: BubbleWidgetPlacement.tabSize.height)
        .background { bubbleSurface(RoundedRectangle(cornerRadius: 14, style: .continuous)) }
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
                + QuotaFormatters.percentageText(for: snapshot?.canShowPercentages(now: now) == true ? $0.remainingRatio : nil)
        }.joined(separator: ", "))
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                Text("ReadyCheck")
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                Text("· Codex")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.55))
                }
                .layoutPriority(1)
                if let refreshDate {
                    Text(refreshDate)
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                }
                }
                Spacer()
                Button(action: onTogglePin) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isPinned ? Color(red: 0.20, green: 0.70, blue: 1) : .white.opacity(0.75))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(isPinned ? Color.blue.opacity(0.15) : .clear))
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

            miniTrend

            HStack {
                Text(snapshot.map { model.localization.text("status.lastUpdated") + " "
                    + DateFormatter.localizedString(from: $0.refreshedAt, dateStyle: .none, timeStyle: .short) } ?? "—")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                Spacer(minLength: 6)
                Button {
                    model.openMainWindowFromWidget()
                    onCollapse()
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

    private func quotaRow(_ window: QuotaWindow, canShow: Bool) -> some View {
        let ratio = canShow ? window.remainingRatio : nil
        return HStack(alignment: .top, spacing: 12) {
            Circle().fill(quotaColor(for: ratio)).frame(width: 10, height: 10).padding(.top, 5)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(QuotaWindowDisplay.title(for: window, localization: model.localization))
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                    Text(QuotaFormatters.percentageText(for: ratio))
                        .font(.system(size: 16, weight: .bold).monospacedDigit())
                        .foregroundStyle(quotaColor(for: ratio))
                }
                Text(QuotaResetCountdown(window: window, snapshot: snapshot, now: now).text(localization: model.localization))
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2).monospacedDigit()
            }
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.18)).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    private var codexIcon: some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable().scaledToFit().accessibilityHidden(true)
    }

    private var miniTrend: some View {
        let values = primaryWindow.map {
            QuotaMiniTrend.values(samples: model.quotaHistorySamples, providerID: "codex-oauth",
                                  windowID: $0.id, now: now)
        } ?? [Double?](repeating: nil, count: 12)
        return VStack(alignment: .leading, spacing: 4) {
            Text(String(format: model.localization.text("orbital.recentConsumption"), primaryWindowShortLabel))
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
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

    private func bubbleSurface<S: Shape>(_ shape: S) -> some View {
        shape.fill(floatingSurfaceColor)
            .overlay(shape.stroke(Color.white.opacity(0.24), lineWidth: 0.8))
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

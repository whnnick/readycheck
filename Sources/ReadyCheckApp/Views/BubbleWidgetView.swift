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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var model: ReadyCheckAppModel
    let isExpanded: Bool
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
        windows.first { model.notchQuotaSelection.matches(labelKey: $0.labelKey) } ?? windows.first
    }

    private var primaryRatio: Double? {
        guard snapshot?.canShowPercentages(now: now) == true else { return nil }
        return primaryWindow?.remainingRatio
    }

    private var displayedQuota: BubbleQuotaDisplay {
        BubbleQuotaDisplay(selection: model.notchQuotaSelection, windowID: primaryWindow?.id, ratio: primaryRatio)
    }

    private var primaryWindowShortLabel: String {
        guard let labelKey = primaryWindow?.labelKey else { return model.notchQuotaSelection.shortLabel }
        if NotchQuotaSelection.fiveHour.matches(labelKey: labelKey) { return NotchQuotaSelection.fiveHour.shortLabel }
        if NotchQuotaSelection.sevenDay.matches(labelKey: labelKey) { return NotchQuotaSelection.sevenDay.shortLabel }
        return model.notchQuotaSelection.shortLabel
    }

    private var urgencyColor: Color {
        quotaColor(for: primaryRatio)
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
            if isExpanded { expandedCard.transition(surfaceTransition) }
            else if let tabEdge { edgeTab(tabEdge) }
            else { circleBubble }
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
                try? await Task.sleep(for: .seconds(2))
                recoveryHighlight = false
            }
        }
    }

    private var circleBubble: some View {
        ZStack {
            bubbleSurface(Circle())
                .overlay(Circle().stroke(recoveryHighlight ? urgencyColor : .clear, lineWidth: 2))
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 4)
                .padding(6)
            Circle()
                .trim(from: 0, to: max(0, min(primaryRatio ?? 0, 1)))
                .stroke(urgencyColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(6)
            VStack(spacing: 0) {
                codexIcon
                    .frame(width: 23, height: 23)
                Text(QuotaFormatters.percentageText(for: primaryRatio))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
        }
        .frame(width: BubbleWidgetPlacement.bubbleSize.width, height: BubbleWidgetPlacement.bubbleSize.height)
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
        .simultaneousGesture(dragGesture)
        .contextMenu { contextMenu }
        .help(model.localization.text("bubble.openDetails"))
        .accessibilityLabel(model.localization.text("bubble.accessibility") + " " + QuotaFormatters.percentageText(for: primaryRatio))
    }

    private func edgeTab(_ edge: BubbleWidgetPlacement.Edge) -> some View {
        HStack(spacing: 6) {
            if edge == .right { edgeProgressRail }
            VStack(spacing: 7) {
                codexIcon.frame(width: 25, height: 25)
                Text(QuotaFormatters.percentageText(for: primaryRatio))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                HStack(spacing: 3) {
                    Text(primaryWindowShortLabel)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                    Image(systemName: edge == .right ? "chevron.left" : "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity)
            if edge == .left { edgeProgressRail }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(width: BubbleWidgetPlacement.tabSize.width, height: BubbleWidgetPlacement.tabSize.height)
        .background { bubbleSurface(RoundedRectangle(cornerRadius: 21, style: .continuous)) }
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(recoveryHighlight ? urgencyColor : .clear, lineWidth: 2))
        .contentShape(RoundedRectangle(cornerRadius: 21))
        .onTapGesture(perform: onTap)
        .simultaneousGesture(dragGesture)
        .contextMenu { contextMenu }
        .help(model.localization.text("bubble.openDetails"))
        .accessibilityLabel(model.localization.text("bubble.accessibility") + " " + QuotaFormatters.percentageText(for: primaryRatio))
    }

    private var edgeProgressRail: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(Color.white.opacity(0.18))
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(urgencyColor)
                        .frame(height: geometry.size.height * max(0, min(primaryRatio ?? 0, 1)))
                }
        }
        .frame(width: 5, height: 64)
    }

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                codexIcon.frame(width: 18, height: 18)
                Text("ReadyCheck")
                    .font(.subheadline.weight(.semibold))
                Text("· Codex")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                Button(action: onCollapse) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.plain)
                .help(model.localization.text("bubble.collapse"))
            }

            if let snapshot, !windows.isEmpty {
                ForEach(Array(windows.prefix(2))) { window in
                    quotaRow(window, canShow: snapshot.canShowPercentages(now: now))
                }
            } else {
                Text(model.localization.text("empty.quota.title"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Button {
                model.openMainWindowFromWidget()
                onCollapse()
            } label: {
                Text(model.localization.text("bubble.openMainWindow"))
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.62, green: 0.80, blue: 1))
            }
            .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .tint(Color(red: 0.62, green: 0.80, blue: 1))
        .padding(12)
        .background { bubbleSurface(RoundedRectangle(cornerRadius: 18, style: .continuous)) }
        .padding(7)
        .frame(width: 282, height: 156)
    }

    private func quotaRow(_ window: QuotaWindow, canShow: Bool) -> some View {
        let ratio = canShow ? window.remainingRatio : nil
        return HStack(spacing: 8) {
            Text(window.displayLabel ?? model.localization.text(window.labelKey))
                .font(.caption)
                .lineLimit(1)
                .frame(width: 82, alignment: .leading)
            GeometryReader { geometry in
                Capsule().fill(Color.white.opacity(0.18))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(quotaColor(for: ratio))
                            .frame(width: geometry.size.width * max(0, min(ratio ?? 0, 1)))
                    }
            }
            .frame(height: 5)
            Text(QuotaFormatters.percentageText(for: ratio))
                .font(.caption.weight(.semibold).monospacedDigit())
                .frame(width: 38, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var codexIcon: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex")
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.chat") {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { onDragChanged($0.translation) }
            .onEnded { _ in onDragEnded() }
    }

    private var surfaceTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.94))
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
        Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
    }
}

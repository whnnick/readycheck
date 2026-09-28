import AppKit
import ReadyCheckCore
import SwiftUI

struct EdgeRailWidgetView: View {
    @Bindable var model: ReadyCheckAppModel
    let edge: EdgeRailPlacement.Edge
    let mode: EdgeRailPlacement.Mode
    let onHover: (Bool) -> Void
    let onExpand: () -> Void
    let onToggleDetail: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

    @State private var now = Date()
    @State private var isHandleHovered = false

    private var snapshot: ProviderQuotaSnapshot? {
        model.snapshots.first { $0.providerId == "codex-oauth" }
    }

    private var windows: [QuotaWindow] {
        snapshot?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []
    }

    private var fiveHourWindow: QuotaWindow? {
        windows.first { $0.labelKey == "quota.window.codex.5h" || $0.labelKey == "quota.fiveHour" || $0.durationMinutes == 300 }
    }

    private var sevenDayWindow: QuotaWindow? {
        windows.first { $0.labelKey == "quota.window.codex.7d" || $0.labelKey == "quota.sevenDay" || $0.durationMinutes == 10_080 }
    }

    private var canShowPercentages: Bool { snapshot?.canShowPercentages(now: now) == true }

    private func ratio(for selection: NotchQuotaSelection) -> Double? {
        guard canShowPercentages else { return nil }
        switch selection {
        case .fiveHour: return fiveHourWindow?.remainingRatio
        case .sevenDay: return sevenDayWindow?.remainingRatio
        default: return nil
        }
    }

    private func color(for ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: .green
        case .warning: .orange
        case .critical, .exhausted: .red
        case .unknown: .gray
        }
    }

    var body: some View {
        Group {
            switch mode {
            case .collapsed: collapsedHandle
            case .dock: dock
            case .detail:
                HStack(spacing: 10) {
                    if edge == .right { detailCard }
                    dock
                    if edge == .left { detailCard }
                }
            }
        }
        .frame(width: width, height: EdgeRailPlacement.height)
        .contentShape(Rectangle())
        .onHover(perform: onHover)
        .contextMenu {
            Button(model.localization.text("bubble.openMainWindow")) { model.openMainWindowFromWidget() }
            Divider()
            Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
        }
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private var width: CGFloat {
        switch mode {
        case .collapsed: EdgeRailPlacement.collapsedWidth
        case .dock: EdgeRailPlacement.dockWidth
        case .detail: EdgeRailPlacement.detailWidth
        }
    }

    private var collapsedHandle: some View {
        VStack(spacing: 8) {
            codexIcon.frame(width: 16, height: 16)
            quotaBar(.fiveHour)
            quotaBar(.sevenDay)
        }
        .frame(width: 24, height: 150)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(red: 0.10, green: 0.12, blue: 0.15)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(isHandleHovered ? 0.42 : 0.24), lineWidth: 0.8))
        .frame(maxWidth: .infinity, alignment: edge == .left ? .leading : .trailing)
        .accessibilityLabel(model.localization.text("edgeRail.accessibility"))
        .help(model.localization.text("edgeRail.hoverHint"))
        .onHover { isHandleHovered = $0 }
        .animation(.easeOut(duration: 0.16), value: isHandleHovered)
        .onTapGesture(perform: onExpand)
        .simultaneousGesture(dragGesture)
    }

    private func quotaBar(_ selection: NotchQuotaSelection) -> some View {
        let value = ratio(for: selection)
        return ZStack(alignment: .bottom) {
            Capsule().fill(Color.white.opacity(0.16))
            if let value {
                Capsule().fill(color(for: value))
                    .frame(height: 42 * max(0, min(value, 1)))
            }
        }
        .frame(width: 7, height: 42)
        .animation(.easeOut(duration: 0.25), value: value)
    }

    private var dock: some View {
        Button(action: onToggleDetail) {
            VStack(spacing: 5) {
                codexIcon.frame(width: 20, height: 20)
                    .padding(.bottom, 1)
                quotaRing(.fiveHour, shortLabel: "5h")
                quotaRing(.sevenDay, shortLabel: "7d")
            }
            .frame(width: EdgeRailPlacement.dockWidth, height: EdgeRailPlacement.height)
            .contentShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 25, style: .continuous).fill(Color(red: 0.10, green: 0.12, blue: 0.15)))
            .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.white.opacity(0.24), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.localization.text(mode == .detail ? "edgeRail.hideDetail" : "edgeRail.showDetail"))
        .simultaneousGesture(dragGesture)
        .help(model.localization.text("edgeRail.dragHint"))
    }

    private func quotaRing(_ selection: NotchQuotaSelection, shortLabel: String) -> some View {
        let value = ratio(for: selection)
        return VStack(spacing: 1) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.17), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0, min(value ?? 0, 1)))
                    .stroke(color(for: value), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(QuotaFormatters.percentageText(for: value))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 49, height: 49)
            Text(shortLabel)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(width: 72, height: 66)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(shortLabel) \(QuotaFormatters.percentageText(for: value))")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { onDragChanged($0.translation) }
            .onEnded { _ in onDragEnded() }
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text("Codex")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(model.localization.text("edgeRail.detail"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            detailRow(.fiveHour, window: fiveHourWindow)
            detailRow(.sevenDay, window: sevenDayWindow)
            Spacer(minLength: 0)
            HStack {
                Button {
                    model.openMainWindowFromWidget()
                } label: {
                    Text(model.localization.text("bubble.openMainWindow"))
                        .foregroundStyle(Color(red: 0.62, green: 0.80, blue: 1))
                }
                .buttonStyle(.link)
                Spacer()
                if snapshot?.isStale(now: now) == true {
                    Text(model.localization.text("bubble.dataStale"))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .font(.caption2)
        }
        .foregroundStyle(.white)
        .tint(Color(red: 0.62, green: 0.80, blue: 1))
        .padding(14)
        .frame(width: 260, height: EdgeRailPlacement.height)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(red: 0.10, green: 0.12, blue: 0.15)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.24), lineWidth: 0.8))
    }

    private func detailRow(_ selection: NotchQuotaSelection, window: QuotaWindow?) -> some View {
        let value = ratio(for: selection)
        let title = selection == .fiveHour
            ? model.localization.text("quota.window.codex.5h")
            : model.localization.text("quota.window.codex.7d")
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption.weight(.semibold))
                Spacer()
                Text(QuotaFormatters.percentageText(for: value))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            GeometryReader { geometry in
                Capsule().fill(Color.white.opacity(0.18))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color(for: value))
                            .frame(width: geometry.size.width * max(0, min(value ?? 0, 1)))
                    }
            }
            .frame(height: 5)
            if let resetAt = window?.resetAt {
                Text("\(model.localization.text("quota.resetAt")) \(DateFormatter.localizedString(from: resetAt, dateStyle: .short, timeStyle: .short))")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
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
}

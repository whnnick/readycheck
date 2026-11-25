import AppKit
import Observation
import ReadyCheckCore
import SwiftUI

struct AggregateServiceSummary: Identifiable {
    let id: ServiceSettingsTarget
    let title: String
    let value: String
    let primaryPeriod: String?
    let caption: String
    let rings: [Double?]

    @MainActor static func readings(model: ReadyCheckAppModel, now: Date) -> [Self] {
        let quota = model.snapshots.first { $0.providerId == "codex-oauth" }
        let windows = quota?.windows.filter(QuotaWindowPresentation.shouldShow) ?? []
        let primary = windows.first { $0.durationMinutes == 300 }
        let weekly = windows.first { $0.durationMinutes == 10_080 }
        let ratio: (QuotaWindow?) -> Double? = { NotchStatusView.ratio(for: $0, snapshot: quota, now: now) }
        let balance = DeepSeekDisplay.readings(connection: model.deepSeek, now: now).first
        let zh = model.language == .zhCN
        let balanceValid = balance != nil && balance?.isStale == false && model.deepSeek.error == nil && !model.deepSeek.credentialError
        let balanceCaption = model.deepSeek.credentialError ? (zh ? "需授权" : "Allow access")
            : model.deepSeek.error != nil ? (zh ? "读取失败" : "Read failed")
            : balanceValid ? balance!.currency : (zh ? "待连接/刷新" : "Connect / refresh")
        let codexCaption: String
        if primary != nil, weekly != nil {
            codexCaption = zh ? "内环为 7 天额度" : "Inner ring shows 7-day allowance"
        } else if primary != nil || weekly != nil {
            codexCaption = zh ? "剩余额度" : "Remaining"
        } else {
            codexCaption = zh ? "暂无读数" : "No reading"
        }
        return model.quickDisplayServices.map { service in
            switch service {
            case .codex:
                return Self(id: service, title: service.title, value: QuotaFormatters.percentageText(for: ratio(primary ?? weekly)),
                    primaryPeriod: primary != nil ? "5h" : weekly.map { _ in "7d" }, caption: codexCaption,
                    rings: primary != nil ? [ratio(primary), ratio(weekly)] : [ratio(weekly)])
            case .muse:
                let remaining = model.muse.remainingRatio(now: now)
                return Self(id: service, title: service.title, value: QuotaFormatters.percentageText(for: remaining),
                    primaryPeriod: nil, caption: remaining != nil ? (zh ? "7d 周额度" : "7d weekly")
                        : model.muse.isBusy ? (zh ? "读取中" : "Reading") : (zh ? "待连接/刷新" : "Connect / refresh"),
                    rings: [remaining])
            case .deepSeek:
                return Self(id: service, title: service.title, value: balanceValid ? (balance.map { BalanceSurfaceReading.amount($0.total) } ?? "—") : "—",
                    primaryPeriod: nil, caption: balanceCaption, rings: [])
            }
        }
    }
}

@MainActor @Observable
final class AggregateCapsuleRailSelection {
    var service: ServiceSettingsTarget?
    var isPinned: Bool

    init(service: ServiceSettingsTarget? = nil, isPinned: Bool = false) {
        self.service = service
        self.isPinned = isPinned
    }
}

struct AggregateCapsuleView: View {
    static let cornerRadius = AggregateCapsulePlacement.size.width / 2
    static let headerHeight: CGFloat = 12
    static let bottomGripHeight: CGFloat = 10

    let model: ReadyCheckAppModel
    var selection = AggregateCapsuleRailSelection()
    let onSelect: (ServiceSettingsTarget) -> Void
    let onHover: (ServiceSettingsTarget, Bool) -> Void
    var onLeaveRail: () -> Void = {}
    var onServicesChanged: () -> Void = {}
    @State private var now = Date()

    private var moreActionsLabel: String { model.language == .zhCN ? "胶囊更多操作" : "More capsule actions" }
    private var dragHelp: String { model.language == .zhCN ? "拖动以移动聚合胶囊" : "Drag to move the aggregate capsule" }

    var body: some View {
        let shell = Capsule()
        VStack(spacing: 0) {
            grip.frame(maxWidth: .infinity).frame(height: Self.headerHeight)
                .contentShape(Rectangle()).help(dragHelp)
            ScrollView(.vertical) {
                VStack(spacing: AggregateCapsulePlacement.rowSpacing) {
                    let readings = AggregateServiceSummary.readings(model: model, now: now)
                    if readings.isEmpty {
                        Button(action: model.showQuickDisplaySettings) {
                            Image(systemName: "slider.horizontal.3").frame(width: 44, height: AggregateCapsulePlacement.rowHeight)
                        }
                        .buttonStyle(.plain)
                        .help(model.localization.text("settings.quickDisplay"))
                        .accessibilityLabel(model.localization.text("settings.quickDisplay"))
                    }
                    ForEach(readings) { item in
                        AggregateCapsuleItem(item: item, language: model.language,
                            selected: selection.service == item.id,
                            pinned: selection.isPinned && selection.service == item.id,
                            onSelect: { onSelect(item.id) }, onHover: { onHover(item.id, $0) })
                            .glassCapsuleItem(item.id)
                    }
                }
                .glassCapsuleSelection(selection.service, axis: .vertical, kind: .insetSelection)
                .frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden)
            Menu { actions } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 26, height: 12)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden)
            .frame(width: 30, height: 12)
            .help(moreActionsLabel).accessibilityLabel(moreActionsLabel)
            .accessibilityIdentifier("aggregate.moreActions")
            grip.frame(maxWidth: .infinity).frame(height: Self.bottomGripHeight)
                .contentShape(Rectangle()).help(dragHelp)
        }
        .background { GlassCapsuleSurface(kind: .rail) }
        .clipShape(shell)
        .contentShape(shell)
        .onHover { if !$0 { onLeaveRail() } }
        .contextMenu { actions }
        .task { while !Task.isCancelled { now = Date(); try? await Task.sleep(for: .seconds(1)) } }
        .onChange(of: model.quickDisplayServices) { onServicesChanged() }
        .onChange(of: model.muse.observedAt) { _, _ in now = Date() }
    }

    private var grip: some View {
        Capsule().fill(.secondary.opacity(0.38)).frame(width: 12, height: 2)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var actions: some View {
        Button(model.localization.text("bubble.openMainWindow")) { model.openMainWindowFromWidget() }
        Button(model.localization.text("settings.quickDisplay"), action: model.showQuickDisplaySettings)
        Button(model.localization.text("action.resetWidgetPosition")) { model.resetFloatingWidgetPosition() }
        Button(model.language == .zhCN ? "稍后显示（15 分钟）" : "Snooze for 15 minutes") { model.snoozeFloatingWidget(minutes: 15) }
        Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
    }
}

private struct AggregateCapsuleItem: View {
    let item: AggregateServiceSummary
    let language: AppLanguage
    let selected: Bool
    let pinned: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) { content }
            .buttonStyle(.plain)
            .onHover { inside in
                isHovered = inside
                onHover(inside)
            }
            .help(accessibilityText)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var accessibilityText: String {
        [item.title, item.primaryPeriod, item.value, item.caption].compactMap { $0 }.joined(separator: ", ")
    }

    private var compactCaption: String {
        if let period = item.primaryPeriod { return period }
        if item.value == "—" { return language == .zhCN ? "暂无" : "No data" }
        return item.id == .muse ? "7d" : item.caption
    }

    private var content: some View {
        let shape = RoundedRectangle(cornerRadius: 12)
        let tint = AggregateServiceMark.tint(item.id)
        let hoverAnimation: Animation? = reduceMotion ? nil : .timingCurve(0.23, 1, 0.32, 1, duration: 0.15)
        return VStack(spacing: 0) {
            AggregateServiceMark(service: item.id, rings: item.rings, compact: true)
                .frame(width: 28, height: 28)
                .scaleEffect(isHovered && !reduceMotion ? 1.08 : 1)
            Text(item.value)
                .font(.system(size: 16, weight: .semibold, design: .rounded)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.62)
                .padding(.horizontal, 2)
                .frame(height: 18)
            Text(compactCaption)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.75)
                .frame(height: 8)
        }
        .frame(width: 44, height: AggregateCapsulePlacement.rowHeight)
        .background(tint.opacity(isHovered && !selected ? 0.08 : 0), in: shape)
        .overlay(alignment: .topTrailing) {
            if pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(tint)
                    .padding(3)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .animation(hoverAnimation, value: isHovered)
        .contentShape(shape)
    }
}

struct AggregateServiceMark: View {
    let service: ServiceSettingsTarget
    var rings: [Double?] = []
    var compact = false
    @Environment(\.colorScheme) private var colorScheme
    static func tint(_ service: ServiceSettingsTarget) -> Color {
        switch service { case .codex: .cyan; case .deepSeek: Color(red: 0.47, green: 0.45, blue: 1); case .muse: Color(red: 0.15, green: 0.62, blue: 1) }
    }
    static func ringColor(_ ratio: Double?, normal: Color) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: normal
        case .warning: .orange
        case .critical, .exhausted: .red
        case .unknown: .gray
        }
    }
    var body: some View {
        let iconSize: CGFloat = compact ? 20 : 22
        let ringWidth: CGFloat = compact ? 1.25 : 2.5
        let ringInset: CGFloat = compact ? 1.2 : 2
        let ringSpacing: CGFloat = compact ? 2.4 : 5
        let ringTrack = compact ? Color.primary.opacity(0.15) : .white.opacity(0.12)
        ZStack {
            Circle().fill(compact
                ? (colorScheme == .dark ? Color.white.opacity(0.08) : .white.opacity(0.80))
                : .white.opacity(0.035))
                .padding(compact ? 2 : 5)
            if rings.isEmpty {
                Circle().stroke(Self.tint(service).opacity(0.46), lineWidth: compact ? 1.2 : 2).padding(ringInset)
            } else {
                ForEach(rings.indices, id: \.self) { index in
                    let ratio = rings[index]
                    let inset = ringInset + CGFloat(index) * ringSpacing
                    let tint = index == 0 ? Self.tint(service) : (compact ? .primary.opacity(0.68) : .white.opacity(0.7))
                    Circle().stroke(ringTrack, lineWidth: ringWidth).padding(inset)
                    Circle().trim(from: 0, to: min(1, max(0, ratio ?? 0)))
                        .stroke(Self.ringColor(ratio, normal: tint),
                                style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90)).padding(inset)
                }
            }
            if service == .muse {
                MuseMonogram().stroke(Self.tint(service), style: StrokeStyle(lineWidth: compact ? 1.9 : 3.3, lineCap: .round, lineJoin: .round))
                    .frame(width: iconSize, height: iconSize)
            } else if let image = ServiceSwitcherIcon.image(name: service == .codex ? "readycheck" : "deepseek", extension: service == .codex ? "png" : "svg") {
                if compact, service == .codex {
                    // The source badge has its own dark margin. Bring the C closer to the inner ring.
                    Image(nsImage: image).resizable().scaledToFit()
                        .frame(width: 23, height: 23)
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(Circle())
                } else {
                    Image(nsImage: image).resizable().scaledToFit().frame(width: iconSize, height: iconSize)
                }
            }
        }.accessibilityHidden(true)
    }
}

private struct MuseMonogram: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.width * 0.08, y: r.height * 0.64))
        p.addCurve(to: CGPoint(x: r.width * 0.42, y: r.height * 0.13), control1: CGPoint(x: r.width * 0.4, y: -r.height * 0.1), control2: CGPoint(x: r.width * 0.52, y: -r.height * 0.04))
        p.addCurve(to: CGPoint(x: r.width * 0.33, y: r.height * 0.84), control1: CGPoint(x: r.width * 0.38, y: r.height * 0.3), control2: CGPoint(x: r.width * 0.13, y: r.height * 1.23))
        p.addCurve(to: CGPoint(x: r.width * 0.72, y: r.height * 0.2), control1: CGPoint(x: r.width * 0.65, y: r.height * 0.1), control2: CGPoint(x: r.width * 0.8, y: r.height * 0.03))
        p.addCurve(to: CGPoint(x: r.width * 0.87, y: r.height * 0.59), control1: CGPoint(x: r.width * 0.5, y: r.height * 1.2), control2: CGPoint(x: r.width * 0.64, y: r.height * 1.02))
        return p
    }
}

struct AggregateCapsuleSurface: View {
    var cornerRadius: CGFloat = 24
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius).fill(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).fill(Color(red: 0.035, green: 0.045, blue: 0.065).opacity(0.86)))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(.white.opacity(0.17), lineWidth: 0.8))
    }
}

import AppKit
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
            codexCaption = "7d " + QuotaFormatters.percentageText(for: ratio(weekly))
        } else if primary != nil || weekly != nil {
            codexCaption = zh ? "剩余额度" : "Remaining"
        } else {
            codexCaption = zh ? "暂无读数" : "No reading"
        }
        return [
            Self(id: .codex, title: "Codex", value: QuotaFormatters.percentageText(for: ratio(primary ?? weekly)),
                 primaryPeriod: primary != nil ? "5h" : weekly.map { _ in "7d" }, caption: codexCaption,
                 rings: primary != nil ? [ratio(primary), ratio(weekly)] : [ratio(weekly)]),
            Self(id: .deepSeek, title: "DeepSeek", value: balanceValid ? (balance.flatMap { $0.total }.map(BalanceSurfaceReading.amount) ?? "—") : "—",
                 primaryPeriod: nil, caption: balanceCaption, rings: []),
            Self(id: .muse, title: "Muse", value: QuotaFormatters.percentageText(for: model.muse.remainingRatio(now: now)),
                 primaryPeriod: nil, caption: model.muse.remainingRatio(now: now) != nil ? (zh ? "7d 周额度" : "7d weekly")
                    : model.muse.isBusy ? (zh ? "读取中" : "Reading") : (zh ? "待连接/刷新" : "Connect / refresh"),
                 rings: [model.muse.remainingRatio(now: now)])
        ]
    }
}

struct AggregateCapsuleView: View {
    static let cornerRadius: CGFloat = 42
    static let headerHeight: CGFloat = 38
    static let bottomGripHeight: CGFloat = 12

    let model: ReadyCheckAppModel
    var selected: ServiceSettingsTarget?
    var isPinned = false
    let onSelect: (ServiceSettingsTarget) -> Void
    let onHover: (ServiceSettingsTarget, Bool) -> Void
    var onLeaveRail: () -> Void = {}
    @State private var now = Date()

    private var moreActionsLabel: String { model.language == .zhCN ? "胶囊更多操作" : "More capsule actions" }
    private var dragHelp: String { model.language == .zhCN ? "拖动以移动聚合胶囊" : "Drag to move the aggregate capsule" }

    var body: some View {
        let shell = RoundedRectangle(cornerRadius: Self.cornerRadius)
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                grip
                Text("ReadyCheck").font(.system(size: 8, weight: .medium)).foregroundStyle(.white.opacity(0.58))
            }
            .frame(maxWidth: .infinity).frame(height: Self.headerHeight)
            .contentShape(Rectangle()).help(dragHelp)
            ScrollView(.vertical) {
                VStack(spacing: 3) {
                    ForEach(AggregateServiceSummary.readings(model: model, now: now)) { item in
                        AggregateCapsuleItem(item: item, selected: selected == item.id, pinned: isPinned && selected == item.id,
                            onSelect: { onSelect(item.id) }, onHover: { onHover(item.id, $0) })
                    }
                }.frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden)
            Menu { actions } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 18)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden)
            .frame(width: 34, height: 20)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
            .help(moreActionsLabel).accessibilityLabel(moreActionsLabel)
            .accessibilityIdentifier("aggregate.moreActions")
            grip.frame(maxWidth: .infinity).frame(height: Self.bottomGripHeight)
                .contentShape(Rectangle()).help(dragHelp)
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .background(AggregateCapsuleSurface(cornerRadius: Self.cornerRadius))
        .clipShape(shell)
        .contentShape(shell)
        .onHover { inside in
            if !inside { onLeaveRail() }
        }
        .contextMenu { actions }
        .task { while !Task.isCancelled { now = Date(); try? await Task.sleep(for: .seconds(1)) } }
        .onChange(of: model.muse.observedAt) { _, _ in now = Date() }
    }

    private var grip: some View {
        Capsule().fill(.white.opacity(0.30)).frame(width: 18, height: 3)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var actions: some View {
        Button(model.localization.text("bubble.openMainWindow")) { model.openMainWindowFromWidget() }
        Button(model.localization.text("action.resetWidgetPosition")) { model.resetFloatingWidgetPosition() }
        Button(model.language == .zhCN ? "稍后显示（15 分钟）" : "Snooze for 15 minutes") { model.snoozeFloatingWidget(minutes: 15) }
        Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
    }
}

private struct AggregateCapsuleItem: View {
    let item: AggregateServiceSummary
    let selected: Bool
    let pinned: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        Button(action: onSelect) { content }
            .buttonStyle(.plain)
            .onHover(perform: onHover)
            .help(accessibilityText)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var accessibilityText: String {
        [item.title, item.primaryPeriod, item.value, item.caption].compactMap { $0 }.joined(separator: ", ")
    }

    private var content: some View {
        let shape = RoundedRectangle(cornerRadius: 20)
        let tint = AggregateServiceMark.tint(item.id)
        return VStack(spacing: 2) {
            AggregateServiceMark(service: item.id, rings: item.rings).frame(width: 44, height: 44)
            Text(item.title)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(item.value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                if let period = item.primaryPeriod {
                    Text(period)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.horizontal, 3).padding(.vertical, 1)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.horizontal, 4)
            Text(item.caption)
                .font(.system(size: 9, weight: .medium)).monospacedDigit()
                .foregroundStyle(.white.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(width: 72, height: 102)
        .background(selected ? tint.opacity(0.10) : .clear, in: shape)
        .overlay {
            if selected {
                shape.strokeBorder(tint.opacity(0.33), lineWidth: 1).allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            if pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(tint)
                    .padding(7)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .contentShape(shape)
    }
}

struct AggregateServiceMark: View {
    let service: ServiceSettingsTarget
    var rings: [Double?] = []
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
        ZStack {
            Circle().fill(.white.opacity(0.035)).padding(5)
            if rings.isEmpty {
                Circle().stroke(Self.tint(service).opacity(0.45), lineWidth: 2).padding(2)
            } else {
                ForEach(rings.indices, id: \.self) { index in
                    let ratio = rings[index]
                    let tint = index == 0 ? Self.tint(service) : .white.opacity(0.7)
                    Circle().stroke(.white.opacity(0.12), lineWidth: 2.5).padding(2 + CGFloat(index) * 5)
                    Circle().trim(from: 0, to: min(1, max(0, ratio ?? 0)))
                        .stroke(Self.ringColor(ratio, normal: tint),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90)).padding(2 + CGFloat(index) * 5)
                }
            }
            if service == .muse {
                MuseMonogram().stroke(Self.tint(service), style: StrokeStyle(lineWidth: 3.3, lineCap: .round, lineJoin: .round))
                    .frame(width: 23, height: 23)
            } else if let image = ServiceSwitcherIcon.image(name: service == .codex ? "readycheck" : "deepseek", extension: service == .codex ? "png" : "svg") {
                Image(nsImage: image).resizable().scaledToFit().frame(width: 22, height: 22)
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

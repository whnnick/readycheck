import AppKit
import ReadyCheckCore
import SwiftUI

struct AggregateServiceSummary: Identifiable {
    let id: ServiceSettingsTarget
    let title: String
    let value: String
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
        return [
            Self(id: .codex, title: "Codex", value: QuotaFormatters.percentageText(for: ratio(primary ?? weekly)),
                 caption: primary != nil ? "5h · 7d " + QuotaFormatters.percentageText(for: ratio(weekly)) : (zh ? "7d 周额度" : "7d weekly"),
                 rings: primary != nil ? [ratio(primary), ratio(weekly)] : [ratio(weekly)]),
            Self(id: .deepSeek, title: "DeepSeek", value: balanceValid ? (balance.flatMap { $0.total }.map(BalanceSurfaceReading.amount) ?? "—") : "—",
                 caption: balanceCaption, rings: []),
            Self(id: .muse, title: "Muse", value: QuotaFormatters.percentageText(for: model.muse.remainingRatio(now: now)),
                 caption: model.muse.remainingRatio(now: now) != nil ? (zh ? "7d 周额度" : "7d weekly")
                    : model.muse.isBusy ? (zh ? "读取中" : "Reading") : (zh ? "待连接/刷新" : "Connect / refresh"),
                 rings: [model.muse.remainingRatio(now: now)])
        ]
    }
}

struct AggregateCapsuleView: View {
    let model: ReadyCheckAppModel
    var selected: ServiceSettingsTarget?
    let onSelect: (ServiceSettingsTarget) -> Void
    let onHover: (ServiceSettingsTarget, Bool) -> Void
    @State private var now = Date()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                Capsule().fill(.white.opacity(0.25)).frame(width: 18, height: 3)
                Text("ReadyCheck").font(.system(size: 8, weight: .medium)).foregroundStyle(.white.opacity(0.5))
            }.frame(height: 38).help(model.language == .zhCN ? "拖动以移动聚合胶囊" : "Drag to move the aggregate capsule")
            ScrollView(.vertical) {
                VStack(spacing: 3) {
                    ForEach(AggregateServiceSummary.readings(model: model, now: now)) { item in
                        AggregateCapsuleItem(item: item, selected: selected == item.id,
                            onSelect: { onSelect(item.id) }, onHover: { onHover(item.id, $0) })
                    }
                }.frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden)
            Image(systemName: "ellipsis").font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.4))
                .frame(height: 32).frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .background(AggregateCapsuleSurface(cornerRadius: 42))
        .clipShape(RoundedRectangle(cornerRadius: 42))
        .contextMenu {
            Button(model.localization.text("bubble.openMainWindow")) { model.openMainWindowFromWidget() }
            Button(model.localization.text("action.resetWidgetPosition")) { model.resetFloatingWidgetPosition() }
            Button(model.language == .zhCN ? "稍后显示（15 分钟）" : "Snooze for 15 minutes") { model.snoozeFloatingWidget(minutes: 15) }
            Button(model.localization.text("action.hideWidget")) { model.hideFloatingWidget() }
        }
        .task { while !Task.isCancelled { now = Date(); try? await Task.sleep(for: .seconds(1)) } }
        .onChange(of: model.muse.observedAt) { _, _ in now = Date() }
    }
}

private struct AggregateCapsuleItem: View {
    let item: AggregateServiceSummary
    let selected: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    var body: some View {
        Button(action: { onSelect() }, label: { self.content })
            .buttonStyle(.plain).onHover(perform: onHover)
            .help(accessibilityText)
            .accessibilityLabel(accessibilityText)
    }
    private var accessibilityText: String { "\(item.title) \(item.value), \(item.caption)" }
    private var content: some View {
        VStack(spacing: 3) {
            AggregateServiceMark(service: item.id, rings: item.rings).frame(width: 48, height: 48)
            Text(item.title).font(.system(size: 9, weight: .medium)).foregroundStyle(Color.white.opacity(0.7))
            valueText
            captionText
        }
        .frame(width: 72, height: 102)
        .background(highlight, in: RoundedRectangle(cornerRadius: 22))
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
    private var highlight: Color { selected ? Color.white.opacity(0.07) : Color.clear }
    private var valueText: some View {
        Text(item.value).font(.system(size: 15, weight: .semibold, design: .rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
    }
    private var captionText: some View {
        Text(item.caption).font(.system(size: 8.5, weight: .medium)).monospacedDigit()
            .foregroundStyle(Color.white.opacity(0.55)).lineLimit(1).minimumScaleFactor(0.75)
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

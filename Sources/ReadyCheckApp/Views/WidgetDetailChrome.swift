import AppKit
import ReadyCheckCore
import SwiftUI

struct WidgetDetailHeader: View {
    let model: ReadyCheckAppModel
    let now: Date
    var isPinned = false
    var onTogglePin: (() -> Void)?
    var service: ServiceSettingsTarget?

    var body: some View {
        HStack(spacing: 8) {
            if let service {
                AggregateServiceMark(service: service).frame(width: 32, height: 32)
            } else {
                Image(nsImage: ServiceSwitcherIcon.image(name: "readycheck", extension: "png")
                      ?? NSApplication.shared.applicationIconImage)
                    .resizable().scaledToFit().frame(width: 24, height: 24).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(service?.title ?? "ReadyCheck").font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
            }
            Spacer(minLength: 6)
            if let onTogglePin {
                Button(action: onTogglePin) {
                    Label(model.localization.text(isPinned ? "widget.pinStateOn" : "widget.pinStateOff"),
                          systemImage: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isPinned ? Color.cyan : .white.opacity(0.75))
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(isPinned ? Color.blue.opacity(0.15) : .white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 9))
                }.buttonStyle(.plain)
                    .help(model.localization.text(isPinned ? "bubble.unpinHelp" : "bubble.pinHelp"))
                    .accessibilityLabel(model.localization.text(isPinned ? "widget.unpinDetails" : "widget.pinDetails"))
                    .accessibilityValue(model.localization.text(isPinned ? "widget.pinStateOn" : "widget.pinStateOff"))
            }
        }.foregroundStyle(.white)
    }

    private var subtitle: String {
        let target = service ?? model.selectedService
        if target == .muse {
            return (service == nil ? "Muse · " : "") + model.muse.statusText(language: model.language, now: now)
        }
        if target == .deepSeek {
            return service == nil ? "DeepSeek" : (model.language == .zhCN ? "API 余额" : "API balance")
        }
        let snapshot = model.snapshots.first { $0.providerId == "codex-oauth" }
        return (service == nil ? "Codex · " : "") + model.localization.text(snapshot?.availabilityTextKey(now: now) ?? "status.unavailable")
    }
}

struct WidgetDetailFooter: View {
    let model: ReadyCheckAppModel
    let openMainWindow: () -> Void
    var service: ServiceSettingsTarget?

    private var target: ServiceSettingsTarget { service ?? model.selectedService }
    private var isBalance: Bool { target == .deepSeek }
    private var actionSize: CGSize { service == nil ? CGSize(width: 16, height: 18) : CGSize(width: 24, height: 24) }
    private var isBusy: Bool {
        switch target { case .codex: model.isRefreshing; case .deepSeek: model.deepSeek.isBusy; case .muse: model.muse.isBusy }
    }
    private var snapshot: ProviderQuotaSnapshot? { model.snapshots.first { $0.providerId == "codex-oauth" } }
    private func text(_ zh: String, _ en: String) -> String { model.language == .zhCN ? zh : en }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        Divider().overlay(.white.opacity(0.08))
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(status)
                if isBalance, model.deepSeek.refreshOutcome == .unchanged {
                    Text(text("余额未变化", "Balance unchanged"))
                } else if target == .codex, snapshot?.ordinaryUsageAllowed == false {
                    Text(model.localization.text("status.ordinaryUsageBlocked")).foregroundStyle(.orange)
                }
            }
            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.55))
            .lineLimit(2).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Button { Task { await model.refreshService(target) } } label: {
                Group {
                    if isBusy { ProgressView().controlSize(.mini) }
                    else { Image(systemName: "arrow.clockwise") }
                }.frame(width: actionSize.width, height: actionSize.height).contentShape(Rectangle())
            }.disabled(isBusy)
                .help(model.localization.text("action.refresh"))
                .accessibilityLabel(model.localization.text("action.refresh"))
            Button {
                model.openServiceSettings(target)
                model.openMainWindowFromWidget()
            } label: {
                Image(systemName: "bell")
                    .frame(width: actionSize.width, height: actionSize.height).contentShape(Rectangle())
            }
                .help(model.localization.text("navigation.reminders"))
                .accessibilityLabel(model.localization.text("navigation.reminders"))
            Button(action: openMainWindow) {
                Text(model.localization.text("bubble.openMainWindow"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(red: 0.10, green: 0.65, blue: 1))
            }
        }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.white)
        }
    }

    private var status: String {
        if target == .muse { return model.muse.statusText(language: model.language, now: Date()) }
        if isBusy { return text("正在更新", "Updating") }
        if isBalance, model.deepSeek.refreshOutcome == .failed { return text("更新失败", "Update failed") }
        let date = isBalance ? model.deepSeek.observedAt : snapshot?.refreshedAt
        return date?.formatted(date: .omitted, time: .standard) ?? text("尚未更新", "Not updated")
    }
}

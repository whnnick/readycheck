import ReadyCheckCore
import AppKit
import SwiftUI

struct MenuBarQuotaView: View {
    @Bindable var model: ReadyCheckAppModel
    let openSettings: @MainActor () -> Void

    @State private var now = Date()
    @State private var quotaContentHeight: CGFloat = 0

    private var localization: LocalizationService {
        model.localization
    }

    private var service: ServiceSettingsTarget? { model.quickDisplayService }
    private var codexSnapshots: [ProviderQuotaSnapshot] { model.snapshots.filter { $0.providerId == "codex-oauth" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            if model.quickDisplayServices.count > 1 {
                Picker(localization.text("settings.quickDisplay"), selection: Binding(
                    get: { service }, set: { if let target = $0 { model.selectedService = target } }
                )) {
                    ForEach(model.quickDisplayServices, id: \.self) { target in
                        Text(target.title).tag(Optional(target))
                    }
                }.pickerStyle(.segmented).labelsHidden()
            }
            if service == nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.text("settings.quickDisplayEmpty")).foregroundStyle(.secondary)
                    Button(localization.text("settings.quickDisplay")) { openDisplaySettings() }
                }
            } else if service == .muse {
                ScrollView { MuseUsageView(connection: model.muse, language: model.language, now: now, detailed: false) }
                    .frame(maxHeight: 220)
            } else if service == .deepSeek {
                ScrollView {
                    DeepSeekBalancePanel(connection: model.deepSeek, language: model.language, now: now) {
                        model.selectedService = .deepSeek
                        model.navigateToMainPage(.overview)
                        openSettings()
                    }
                }.frame(maxHeight: 280)
            } else if codexSnapshots.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(codexSnapshots) { snapshot in
                            ForEach(displayWindows(snapshot)) { window in
                                CompactQuotaRow(window: window, snapshot: snapshot, localization: localization, now: now)
                            }
                            if snapshot.isCached == true {
                                Label(localization.text("status.stale"), systemImage: "clock.badge.exclamationmark")
                                    .font(.caption).foregroundStyle(.orange)
                            } else if !snapshot.errors.isEmpty {
                                Text(localization.text(snapshot.errors[0])).font(.caption).foregroundStyle(.secondary)
                            } else if snapshot.availabilityTextKey(now: now) != "status.available" {
                                Text(localization.text(snapshot.availabilityTextKey(now: now))).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        NextEventsView(model: model, now: now, compact: true, openMain: openSettings)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: MenuQuotaContentHeight.self, value: geometry.size.height)
                    })
                }
                .frame(height: min(280, quotaContentHeight))
                .onPreferenceChange(MenuQuotaContentHeight.self) { quotaContentHeight = $0 }
            }
            if let service {
                Divider()
                Button {
                    model.openServiceSettings(service)
                    openSettings()
                } label: {
                    HStack {
                        Label(localization.text("navigation.reminders"), systemImage: "bell")
                        Spacer()
                        if service == .codex {
                            Text(model.lowQuotaThreshold == 0 ? localization.text("lowQuota.off") : "\(model.lowQuotaThreshold)%")
                        }
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                }.buttonStyle(.plain)
            }
            Toggle(isOn: $model.widgetVisible) {
                Label(localization.text("settings.desktopWidget"), systemImage: "macwindow.on.rectangle")
            }.toggleStyle(.switch).controlSize(.small)
            WidgetSnoozeStatusView(model: model)
            footer
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(width: 340)
        .task { await refreshOnOpenIfNeeded() }
        .task { await updateNowWhileVisible() }
        .onChange(of: model.muse.observedAt) { _, _ in now = Date() }
    }

    private func displayWindows(_ snapshot: ProviderQuotaSnapshot) -> [QuotaWindow] {
        snapshot.providerId == "codex-oauth"
            ? model.notchQuotaSelection.displayWindows(in: snapshot.windows, primaryFirst: false) : snapshot.windows
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.text("app.name"))
                    .font(.headline)

                if service != nil {
                    Text(refreshSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(accountSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            if model.quickDisplayServiceBusy {
                ProgressView()
                    .controlSize(.small)
            } else if service == .codex {
                DataStatusButton(model: model).labelStyle(.iconOnly).controlSize(.small)
                    .help(localization.text("dataStatus.title"))
            }
        }
    }

    private var emptyState: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: 6) {
                Text(localization.text("empty.quota.title"))
                    .font(.subheadline.weight(.medium))

                Text(model.isRefreshing ? localization.text("status.refreshing") : emptyStateMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(localization.text("status.safeRefresh"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if model.codexOAuthStatus != .connected {
                    Button {
                        openSettings()
                    } label: {
                        Label(localization.text("action.connectCodex"), systemImage: "key.horizontal")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Divider()
            HStack {
                Button {
                    if let service { model.selectedService = service }
                    model.navigateToMainPage(.overview)
                    openSettings()
                } label: {
                    Label(localization.text("bubble.openMainWindow"), systemImage: "arrow.up.forward.square")
                }
                Spacer()
                Button {
                    guard let service else { return }
                    Task { await model.refreshService(service); now = Date() }
                } label: { Image(systemName: "arrow.clockwise") }
                .disabled(service == nil || model.quickDisplayServiceBusy)
                .help(localization.text("action.refresh"))
                .accessibilityLabel(localization.text("action.refresh"))
                Menu {
                    Button(localization.text("settings.quickDisplay")) { openDisplaySettings() }
                    Button(localization.text("navigation.connection")) {
                        model.openServiceSettings(service ?? model.selectedService, section: .connection); openSettings()
                    }
                    Button(localization.text("navigation.general")) {
                        model.mainWindowPage = .settings; model.mainSettingsSection = .general; openSettings()
                    }
                    Divider()
                    Button(localization.text("about.menuItem")) { model.showAboutWindow() }
                    Button(localization.text("action.quit"), role: .destructive) { NSApp.terminate(nil) }
                } label: { Image(systemName: "ellipsis") }
                .menuStyle(.borderlessButton).fixedSize()
                .help(localization.text("navigation.settings"))
                .accessibilityLabel(localization.text("navigation.settings"))
            }
        }
        .buttonStyle(.bordered).controlSize(.small)
    }

    private func openDisplaySettings() {
        model.navigateToMainPage(.settings)
        model.mainSettingsSection = .display
        openSettings()
    }

    @MainActor
    private func refreshOnOpenIfNeeded() async {
        let currentNow = Date()
        now = currentNow
        await model.reloadCodexOAuthConnectionStatus()

        guard model.codexOAuthStatus == .connected || !model.snapshots.isEmpty else {
            return
        }

        guard model.snapshots.isEmpty || model.hasStaleSnapshots(now: currentNow) else {
            return
        }

        await model.refresh(reason: .openedPanel)
        now = Date()
    }

    @MainActor
    private func updateNowWhileVisible() async {
        while !Task.isCancelled {
            now = Date()

            try? await Task.sleep(for: .seconds(1))
        }
    }

    private var refreshSummary: String {
        if service == .muse { return model.muse.statusText(language: model.language, now: now) }
        if service == .deepSeek {
            return model.deepSeek.observedAt.map {
                (model.language == .zhCN ? "DeepSeek 更新于 " : "DeepSeek updated ") + $0.formatted(date: .omitted, time: .standard)
            } ?? (model.language == .zhCN ? "DeepSeek 尚未更新" : "DeepSeek has not updated yet")
        }
        guard let lastRefreshAt = model.lastSuccessfulRefreshAt else {
            return localization.text("status.notUpdatedYet")
        }

        let time = DateFormatter.localizedString(from: lastRefreshAt, dateStyle: .none, timeStyle: .short)
        return "\(localization.text("dataStatus.lastSuccess")) \(time)"
    }

    private var emptyStateMessage: String {
        if model.codexOAuthStatus == .connected {
            return localization.text("empty.quota.connectedMessage")
        }

        return localization.text("empty.quota.codexMessage")
    }

    private var accountSummary: String {
        if service == .muse { return "Muse · " + (model.muse.snapshot?.plan ?? "muse.ai") }
        if service == .deepSeek { return model.language == .zhCN ? "DeepSeek API 余额" : "DeepSeek API balance" }
        if let email = model.codexOAuthLoginEmail, !email.isEmpty {
            return "\(localization.text("oauth.account.connectedAs")) \(email)"
        }

        return localization.text(model.codexOAuthStatus == .connected ? "oauth.status.connected" : "oauth.status.notConnected")
    }
}

private struct MenuQuotaContentHeight: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

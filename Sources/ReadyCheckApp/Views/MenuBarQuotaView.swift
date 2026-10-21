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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            if model.snapshots.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.snapshots) { snapshot in
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
            Divider()
            Button {
                model.mainWindowPage = .settings
                model.mainSettingsSection = .reminders
                openSettings()
            } label: {
                HStack {
                    Label(localization.text("navigation.reminders"), systemImage: "bell")
                    Spacer()
                    Text(model.lowQuotaThreshold == 0 ? localization.text("lowQuota.off") : "\(model.lowQuotaThreshold)%")
                    Image(systemName: "chevron.right").font(.caption2)
                }
            }.buttonStyle(.plain)
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

                Text(refreshSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(accountSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if model.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
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
                    model.mainWindowPage = .overview
                    openSettings()
                } label: {
                    Label(localization.text("bubble.openMainWindow"), systemImage: "arrow.up.forward.square")
                }
                Spacer()
                Button {
                    Task { await model.refresh(reason: .manual); now = Date() }
                } label: { Image(systemName: "arrow.clockwise") }
                .disabled(model.isRefreshing)
                .help(localization.text("action.refresh"))
                .accessibilityLabel(localization.text("action.refresh"))
                Menu {
                    Button(localization.text("navigation.display")) {
                        model.mainWindowPage = .settings; model.mainSettingsSection = .display; openSettings()
                    }
                    Button(localization.text("navigation.connection")) {
                        model.mainWindowPage = .settings; model.mainSettingsSection = .connection; openSettings()
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
            let currentNow = Date()
            now = currentNow

            if model.shouldAutomaticallyRefresh(now: currentNow) {
                await model.refresh(reason: .automatic)
                now = Date()
            }

            try? await Task.sleep(for: .seconds(1))
        }
    }

    private var refreshSummary: String {
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

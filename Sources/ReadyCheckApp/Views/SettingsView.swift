import AppKit
import ReadyCheckCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: ReadyCheckAppModel

    @State private var now = Date()

    private let refreshIntervalOptions: [TimeInterval] = [60, 180, 300]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            hero

            GlassSurface(cornerRadius: 24) {
                quotaControls
            }

            HStack(alignment: .top, spacing: 14) {
                GlassSurface(cornerRadius: 20) {
                    codexOAuthProviderControls
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                GlassSurface(cornerRadius: 20) {
                    generalControls
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(18)
        .frame(width: 720, height: 700, alignment: .topLeading)
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor),
                        Color.accentColor.opacity(0.12),
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.accentColor.opacity(0.18))
                    .blur(radius: 44)
                    .frame(width: 220, height: 220)
                    .offset(x: 190, y: -220)
            }
            .ignoresSafeArea()
        }
        .task {
            await model.reloadCodexOAuthConnectionStatus()
            await refreshQuotaIfConnected()
        }
        .task {
            await updateNowWhileVisible()
        }
    }

    private var hero: some View {
        GlassSurface(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.localization.text("app.name"))
                            .font(.title2.weight(.semibold))

                        Text(model.localization.text("dashboard.subtitle"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Label(codexOAuthStatusText, systemImage: codexOAuthStatusIcon)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(codexOAuthStatusColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(codexOAuthStatusColor.opacity(0.12), in: Capsule())
                }

                HStack(spacing: 10) {
                    refreshStatusView

                    Spacer()

                    Button {
                        Task {
                            await model.refresh(reason: .manual)
                            now = Date()
                        }
                    } label: {
                        Label(model.localization.text("action.refresh"), systemImage: "arrow.clockwise")
                    }
                    .disabled(model.isRefreshing || model.codexOAuthStatus != .connected)

                    Button {
                        model.showAboutWindow()
                    } label: {
                        Label(model.localization.text("about.title"), systemImage: "info.circle")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                widgetControls

                Divider()

                productSummary
            }
        }
    }

    private var productSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.localization.text("productBrief.summary"))
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                briefItem("productBrief.safeRefresh", systemImage: "checkmark.shield")
                briefItem("productBrief.keychain", systemImage: "key.fill")
                briefItem("productBrief.surfaces", systemImage: "macwindow.on.rectangle")
            }
        }
    }

    private var refreshStatusView: some View {
        HStack(spacing: 8) {
            if model.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(model.isRefreshing ? model.localization.text("status.refreshing") : refreshSummary)
                    .font(.footnote.weight(.medium))

                Text(model.localization.text("dashboard.refreshCadence"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func briefItem(_ textKey: String, systemImage: String) -> some View {
        Label(model.localization.text(textKey), systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.primary.opacity(0.78))
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var widgetControls: some View {
        HStack(spacing: 12) {
            Toggle(isOn: $model.widgetVisible) {
                Label(model.localization.text("action.pinWidget"), systemImage: "macwindow.on.rectangle")
            }

            Toggle(isOn: $model.widgetAlwaysOnTop) {
                Label(model.localization.text("settings.widgetAlwaysOnTop"), systemImage: "rectangle.on.rectangle")
            }

            Button {
                model.resetFloatingWidgetPosition()
            } label: {
                Label(model.localization.text("action.resetWidgetPosition"), systemImage: "arrow.down.forward.and.arrow.up.backward")
            }

            Spacer(minLength: 0)
        }
        .toggleStyle(.switch)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var generalControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(model.localization.text("settings.preferences"), systemImage: "slider.horizontal.3")
                .font(.headline)

            Picker(model.localization.text("settings.language"), selection: $model.language) {
                Text("中文").tag(AppLanguage.zhCN)
                Text("English").tag(AppLanguage.enUS)
            }
            .pickerStyle(.segmented)

            Picker(model.localization.text("settings.refreshInterval"), selection: $model.refreshInterval) {
                ForEach(refreshIntervalOptions, id: \.self) { interval in
                    Text(refreshIntervalLabel(for: interval)).tag(interval)
                }
            }

            Text(model.localization.text("settings.refreshHelp"))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text(model.localization.text("settings.widgetAlwaysOnTopHelp"))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text(model.localization.text("status.safeRefresh"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func refreshIntervalLabel(for interval: TimeInterval) -> String {
        switch interval {
        case 60:
            model.localization.text("refreshInterval.1m")
        case 180:
            model.localization.text("refreshInterval.3m")
        case 300:
            model.localization.text("refreshInterval.5m")
        default:
            "\(Int(interval))s"
        }
    }

    private var codexOAuthProviderControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "key.horizontal")
                    .foregroundStyle(.tint)

                Text(model.localization.text("settings.account"))
                    .font(.headline)
            }

            HStack(spacing: 8) {
                if model.codexOAuthStatus != .connected {
                    Label(codexOAuthStatusText, systemImage: codexOAuthStatusIcon)
                        .font(.footnote)
                        .foregroundStyle(codexOAuthStatusColor)
                } else if let loginEmail = model.codexOAuthLoginEmail {
                    Label {
                        Text(loginEmail)
                            .fontWeight(.medium)
                            .textSelection(.enabled)
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(loginEmail)
                }

                Spacer(minLength: 8)

                if shouldShowConnectButton {
                    Button(model.localization.text("action.connect")) {
                        if let url = model.beginCodexOAuthConnection() {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if model.codexOAuthStatus == .connected {
                    Button(model.localization.text("action.disconnect")) {
                        Task {
                            await model.disconnectCodexOAuth()
                        }
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Text(accountDetailText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if model.codexOAuthStatus != .connected {
                VStack(alignment: .leading, spacing: 5) {
                    Label(model.localization.text("oauth.step.openBrowser"), systemImage: "1.circle")
                    Label(model.localization.text("oauth.step.waitForCallback"), systemImage: "2.circle")
                    Label(model.localization.text("oauth.step.refreshAfterConnect"), systemImage: "3.circle")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if model.isCodexOAuthCallbackInputVisible {
                TextField(
                    model.localization.text("oauth.callback.placeholder"),
                    text: $model.codexOAuthCallbackURL,
                    axis: .vertical
                )
                .lineLimit(2...4)

                HStack {
                    Text(model.localization.text("oauth.callback.help"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(model.localization.text("action.completeAuthorization")) {
                        Task {
                            await model.completeCodexOAuthConnection()
                        }
                    }
                    .disabled(model.codexOAuthCallbackURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .controlSize(.small)
            }

            if let message = model.codexOAuthStatusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
    }

    private var quotaControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(model.localization.text("settings.quota"), systemImage: "chart.bar.fill")
                    .font(.headline)

                Spacer()

                Text(refreshSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if model.snapshots.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.isRefreshing ? model.localization.text("status.refreshing") : quotaEmptyMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    if model.codexOAuthStatus != .connected {
                        Button {
                            if let url = model.beginCodexOAuthConnection() {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label(model.localization.text("action.connectCodex"), systemImage: "key.horizontal")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                ForEach(model.snapshots) { snapshot in
                    QuotaCardView(
                        snapshot: snapshot,
                        localization: model.localization,
                        now: now
                    )
                }
            }
        }
    }

    private var codexOAuthStatusText: String {
        switch model.codexOAuthStatus {
        case .notConnected:
            model.localization.text("oauth.status.notConnected")
        case .waitingForCallback:
            model.localization.text("oauth.status.waitingForCallback")
        case .exchanging:
            model.localization.text("oauth.status.exchanging")
        case .connected:
            model.localization.text("oauth.status.connected")
        case .failed:
            model.localization.text("oauth.status.failed")
        }
    }

    private var codexOAuthStatusIcon: String {
        switch model.codexOAuthStatus {
        case .connected:
            "checkmark.circle.fill"
        case .waitingForCallback, .exchanging:
            "clock.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        case .notConnected:
            "circle"
        }
    }

    private var codexOAuthStatusColor: Color {
        switch model.codexOAuthStatus {
        case .connected:
            .green
        case .waitingForCallback, .exchanging:
            .orange
        case .failed:
            .red
        case .notConnected:
            .secondary
        }
    }

    private var shouldShowConnectButton: Bool {
        model.codexOAuthStatus == .notConnected || model.codexOAuthStatus == .failed
    }

    private var accountDetailText: String {
        if model.codexOAuthStatus == .connected {
            return model.localization.text("provider.codexOAuth.connectedDetail")
        }

        return model.localization.text("provider.codexOAuth.detail")
    }

    @MainActor
    private func refreshQuotaIfConnected() async {
        now = Date()
        guard model.codexOAuthStatus == .connected else { return }
        guard model.snapshots.isEmpty || model.hasStaleSnapshots(now: now) else { return }

        await model.refresh(reason: .openedPanel)
        now = Date()
    }

    private var refreshSummary: String {
        guard let lastRefreshAt = model.lastRefreshAt else {
            return model.localization.text("status.notUpdatedYet")
        }

        let time = DateFormatter.localizedString(from: lastRefreshAt, dateStyle: .none, timeStyle: .short)
        return "\(model.localization.text("status.lastUpdated")) \(time)"
    }

    private var quotaEmptyMessage: String {
        if model.codexOAuthStatus == .connected {
            return model.localization.text("empty.quota.connectedMessage")
        }

        return model.localization.text("empty.quota.codexMessage")
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
}

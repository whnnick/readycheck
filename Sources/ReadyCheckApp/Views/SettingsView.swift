import AppKit
import ReadyCheckCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: ReadyCheckAppModel

    @State private var now = Date()
    @State private var isReminderHistoryPresented = false

    private let refreshIntervalOptions: [TimeInterval] = [60, 180, 300]

    var body: some View {
        HStack(spacing: 0) {
            MainWindowSidebar(model: model)
            Divider()
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    pageHeader
                    updateBanner
                    switch model.mainWindowPage {
                    case .overview: overviewContent
                    case .usage: usageContent
                    case .settings: settingsContent
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(minWidth: 740, idealWidth: 900, minHeight: 620, idealHeight: 760)
        .task { await updateNowWhileVisible() }
        .sheet(isPresented: $isReminderHistoryPresented) {
            ReminderHistoryListView(records: model.reminderHistoryRecords, localization: model.localization)
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.localization.text(model.mainWindowPage.titleKey)).font(.title2.weight(.semibold))
                    Text(model.localization.text(model.mainWindowPage == .usage ? "usage.pageSubtitle" : "dashboard.subtitle"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                DataStatusButton(model: model).controlSize(.small)
                Button {
                    Task { await model.reloadCodexOAuthConnectionStatus(); await model.refresh(reason: .manual) }
                } label: { Image(systemName: "arrow.clockwise") }
                .disabled(model.isRefreshing)
                .help(model.localization.text("action.refresh"))
                .accessibilityLabel(model.localization.text("action.refresh"))
            }
            refreshStatusView
        }
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            OverviewQuotaView(model: model, now: now)
            if model.snapshots.isEmpty {
                Text(quotaEmptyMessage).font(.callout).foregroundStyle(.secondary)
                Button(model.localization.text("navigation.connection")) {
                    model.mainWindowPage = .settings; model.mainSettingsSection = .connection
                }
            }
            if let pace = model.quotaPace(now: now) {
                QuotaPaceView(pace: pace, localization: model.localization, now: now)
            }
            ForEach(model.snapshots.filter { $0.providerId == "codex-oauth" }) { snapshot in
                quotaRecoveryActions(for: snapshot)
                QuotaCardView(snapshot: snapshot, localization: model.localization, now: now, displayMode: .accountDetails)
            }
            GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                RecentUsageView(samples: model.quotaHistorySamples,
                    localization: model.localization, now: now)
            }
            legacyHistoryNotice
            Button {
                model.mainWindowPage = .settings; model.mainSettingsSection = .reminders
            } label: {
                HStack {
                    Label(model.localization.text("navigation.reminders"), systemImage: "bell")
                    Spacer()
                    Text(model.lowQuotaThreshold == 0 ? model.localization.text("lowQuota.off") : "\(model.lowQuotaThreshold)%")
                    Image(systemName: "chevron.right").font(.caption)
                }.padding(14)
            }
            .buttonStyle(.plain)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder private var legacyHistoryNotice: some View {
        if model.hasUnassignedLegacyHistory {
            Label(model.localization.text("usage.legacyPreserved"), systemImage: "archivebox")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var usageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                TokenUsageView(usage: model.snapshots.first { $0.providerId == "codex-oauth" }?.details?.accountTokenUsage,
                    localization: model.localization, now: now)
            }
            legacyHistoryNotice
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker(model.localization.text("navigation.settings"), selection: $model.mainSettingsSection) {
                ForEach(MainSettingsSection.allCases) { section in
                    Text(model.localization.text(section.titleKey)).tag(section)
                }
            }.pickerStyle(.segmented)
            switch model.mainSettingsSection {
            case .reminders:
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                    VStack(alignment: .leading, spacing: 18) {
                        QuotaRecoveryReminderView(model: model, now: now)
                        Divider()
                        notificationControls
                    }
                }
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                    VStack(alignment: .leading, spacing: 16) {
                        ResetExpiryReminderView(model: model)
                        Divider()
                        ResetCreditAutomationView(model: model)
                    }
                }
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                    ReminderHistorySummaryView(records: model.reminderHistoryRecords,
                        localization: model.localization, showAll: { isReminderHistoryPresented = true })
                }
            case .display:
                quotaWindowControls
                widgetControls
                notchControls
                Toggle(model.localization.text("settings.hideInFullscreen"), isOn: $model.widgetHideInFullscreen)
                    .toggleStyle(.switch).controlSize(.small)
                Text(model.localization.text("settings.hideInFullscreenHelp")).font(.caption).foregroundStyle(.secondary)
            case .connection:
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { codexOAuthProviderControls }
                productSummary
            case .general:
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { generalControls }
                Button(model.localization.text("about.title")) { model.showAboutWindow() }
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
                Image(systemName: "arrow.clockwise")
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

    private var quotaWindowControls: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(model.localization.text("settings.quotaWindow"), systemImage: "chart.bar.fill")
                        .font(.subheadline.weight(.semibold))

                    Text(model.localization.text("settings.quotaWindowHelp"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Picker(model.localization.text("settings.quotaWindow"), selection: quotaWindowSelection) {
                    Text(model.localization.text("settings.quotaWindowAutomatic"))
                        .tag(NotchQuotaSelection.automatic)
                    if !model.notchQuotaSelection.hasPreferredWindow(in: availableQuotaWindows) {
                        Text(model.localization.text("settings.quotaWindowMissing"))
                            .tag(model.notchQuotaSelection)
                    }
                    ForEach(availableQuotaWindows) { window in
                        Text(QuotaWindowDisplay.title(for: window, localization: model.localization))
                            .tag(NotchQuotaSelection.window(window.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 250)
            }
            if !model.notchQuotaSelection.hasPreferredWindow(in: availableQuotaWindows) {
                Text(model.localization.text("settings.quotaWindowMissingHelp"))
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.10), lineWidth: 0.7))
        .controlSize(.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.localization.text("settings.quotaWindow"))
    }

    private var availableQuotaWindows: [QuotaWindow] {
        model.snapshots.first(where: { $0.providerId == "codex-oauth" })?
            .windows.filter(QuotaWindowPresentation.shouldShow) ?? []
    }

    private var quotaWindowSelection: Binding<NotchQuotaSelection> {
        Binding(
            get: { model.notchQuotaSelection.pickerSelection(in: availableQuotaWindows) },
            set: { model.notchQuotaSelection = $0 }
        )
    }

    private var widgetControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label(model.localization.text("settings.desktopWidget"), systemImage: "macwindow.on.rectangle")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)

                Button {
                    model.resetFloatingWidgetPosition()
                } label: {
                    Label(model.localization.text("action.resetWidgetPosition"), systemImage: "arrow.down.forward.and.arrow.up.backward")
                }
            }

            widgetToggleControl(
                title: model.localization.text("action.pinWidget"),
                systemImage: "eye",
                isOn: $model.widgetVisible
            )

            widgetToggleControl(
                title: model.localization.text("settings.widgetAlwaysOnTop"),
                systemImage: "rectangle.on.rectangle",
                isOn: $model.widgetAlwaysOnTop
            )

            Divider()

            Text(model.localization.text("settings.widgetStyle")).font(.caption.weight(.medium))
            WidgetPresentationPicker(selection: $model.widgetPresentation, localization: model.localization)
            WidgetSnoozeMenu(model: model)
            WidgetSnoozeStatusView(model: model)

            Text(model.localization.text("widgetPresentation.modeHint"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            if model.widgetPresentation == .card {
                WidgetStyleSwitcherView(selection: $model.widgetDisplayMode, localization: model.localization)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.10), lineWidth: 0.7))
        .toggleStyle(.switch)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.localization.text("settings.desktopWidget"))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var notchControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(model.localization.text("settings.notchDisplay"), systemImage: "macbook")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                Text(model.localization.text("settings.notchStatus"))
                Spacer(minLength: 0)
                Toggle("", isOn: $model.notchStatusVisible)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(!model.notchStatusAvailable)
            }

            Text(
                model.localization.text(
                    model.notchStatusAvailable
                        ? "settings.notchStatusHelp"
                        : "settings.notchStatusUnavailable"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.10), lineWidth: 0.7))
        .controlSize(.small)
        .help(model.localization.text("settings.notchStatusHelp"))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.localization.text("settings.notchDisplay"))
    }

    private func widgetToggleControl(title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .imageScale(.medium)

            Text(title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .help(title)
    }

    private var generalControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(model.localization.text("settings.preferences"), systemImage: "slider.horizontal.3")
                .font(.headline)

            preferenceSection(titleKey: "settings.language", systemImage: "globe") {
                Picker(model.localization.text("settings.language"), selection: $model.language) {
                    Text("中文").tag(AppLanguage.zhCN)
                    Text("English").tag(AppLanguage.enUS)
                }
                .pickerStyle(.segmented)
            }

            Divider()

            preferenceSection(titleKey: "settings.launchAtLogin", systemImage: "power") {
                Toggle(model.localization.text("settings.launchAtLogin"), isOn: Binding(
                    get: { model.launchAtLoginStatus == .enabled },
                    set: { model.setLaunchAtLoginEnabled($0) }
                ))
                .toggleStyle(.switch)

                Text(launchAtLoginStatusText)
                    .font(.footnote)
                    .foregroundStyle(model.launchAtLoginStatus == .failed || model.launchAtLoginStatus == .incompleteInstallation ? Color.red : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if model.launchAtLoginStatus == .requiresApproval || model.launchAtLoginStatus == .failed || model.launchAtLoginStatus == .unavailable {
                    Button(model.localization.text("settings.launchAtLogin.open")) {
                        model.openLoginItemSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Divider()

            preferenceSection(titleKey: "settings.refresh", systemImage: "arrow.clockwise") {
                Picker(model.localization.text("settings.refreshInterval"), selection: $model.refreshInterval) {
                    ForEach(refreshIntervalOptions, id: \.self) { interval in
                        Text(refreshIntervalLabel(for: interval)).tag(interval)
                    }
                }

                Text(model.localization.text("settings.refreshHelp"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(model.localization.text("status.safeRefresh"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            updateControls
        }
    }

    private var notificationControls: some View {
        preferenceSection(titleKey: "settings.notifications", systemImage: "bell.badge") {
            Label(notificationReadinessText, systemImage: notificationReadinessIcon)
                .font(.footnote.weight(.medium))
                .foregroundStyle(notificationReadinessColor)

            HStack(spacing: 8) {
                Button {
                    Task { await model.sendTestNotification() }
                } label: {
                    Label(model.localization.text(model.testNotificationResult == .sending ? "notification.test.sending" : "notification.test.action"), systemImage: "bell.and.waves.left.and.right")
                        .lineLimit(1)
                }
                .disabled(model.testNotificationResult == .sending)

                Button(model.localization.text("notification.settings.open")) {
                    model.openNotificationSettings()
                }
                .lineLimit(1)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if model.testNotificationResult == .delivered || model.testNotificationResult == .failed {
                Text(testNotificationButtonText)
                    .font(.caption)
                    .foregroundStyle(model.testNotificationResult == .failed ? Color.orange : Color.secondary)
            }

            Text(model.localization.text("notification.settings.help"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var launchAtLoginStatusText: String {
        switch model.launchAtLoginStatus {
        case .disabled: model.localization.text("settings.launchAtLogin.disabled")
        case .enabled: model.localization.text("settings.launchAtLogin.enabled")
        case .requiresApproval: model.localization.text("settings.launchAtLogin.approval")
        case .unavailable: model.localization.text("settings.launchAtLogin.unavailable")
        case .incompleteInstallation: model.localization.text("settings.launchAtLogin.incomplete")
        case .failed: model.localization.text("settings.launchAtLogin.failed")
        }
    }

    private var notificationReadinessText: String {
        switch model.notificationReadiness {
        case .checking: model.localization.text("notification.settings.checking")
        case .ready: model.localization.text("notification.settings.ready")
        case .temporary: model.localization.text("notification.settings.temporary")
        case .alertsDisabled: model.localization.text("notification.settings.alertsDisabled")
        case .denied: model.localization.text("notification.settings.denied")
        }
    }

    private var notificationReadinessIcon: String {
        switch model.notificationReadiness {
        case .checking: "clock"
        case .ready: "checkmark.circle.fill"
        case .temporary, .alertsDisabled, .denied: "exclamationmark.triangle.fill"
        }
    }

    private var notificationReadinessColor: Color {
        switch model.notificationReadiness {
        case .checking: .secondary
        case .ready: .green
        case .temporary, .alertsDisabled, .denied: .orange
        }
    }

    private var testNotificationButtonText: String {
        switch model.testNotificationResult {
        case .idle: model.localization.text("notification.test.action")
        case .sending: model.localization.text("notification.test.sending")
        case .delivered: model.localization.text("notification.test.delivered")
        case .failed: model.localization.text("notification.test.failed")
        }
    }

    private func preferenceSection<Content: View>(
        titleKey: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.localization.text(titleKey), systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.86))

            content()
        }
    }

    @ViewBuilder
    private var updateBanner: some View {
        if let update = model.visibleUpdate {
            GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(model.localization.text("update.available")) \(update.version)")
                            .font(.subheadline.weight(.semibold))

                        Text(model.localization.text("update.bannerMessage"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        model.dismissVisibleUpdate()
                    } label: {
                        Text(model.localization.text("action.remindLater"))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        model.openUpdateReleasePage()
                    } label: {
                        Label(model.localization.text("action.viewUpdate"), systemImage: "arrow.up.forward.circle.fill")
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }

    private var updateControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.localization.text("settings.updates"), systemImage: "arrow.down.circle")
                .font(.subheadline.weight(.semibold))

            Text(updateStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    Task {
                        await model.checkForUpdates(isManual: true)
                    }
                } label: {
                    if model.updateStatus == .checking {
                        Label(model.localization.text("update.checking"), systemImage: "arrow.triangle.2.circlepath")
                    } else {
                        Label(model.localization.text("action.checkForUpdates"), systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(model.updateStatus == .checking)

                if case .updateAvailable = model.updateStatus {
                    Button {
                        model.openUpdateReleasePage()
                    } label: {
                        Label(model.localization.text("action.downloadUpdate"), systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var updateStatusText: String {
        switch model.updateStatus {
        case .idle:
            "\(model.localization.text("about.version")) \(ReadyCheckCore.version)"
        case .checking:
            model.localization.text("update.checking")
        case .upToDate:
            model.localization.text("update.upToDate")
        case .failed:
            model.localization.text("update.failed")
        case .updateAvailable(let update):
            "\(model.localization.text("update.available")) \(update.version)"
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

            Text(model.localization.text("codex.connectionMode"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(model.localization.text("codex.connectionMode"), selection: Binding(
                get: { model.codexConnectionMode },
                set: { mode in Task { await model.setCodexConnectionMode(mode) } }
            )) {
                Text(model.localization.text("codex.connectionMode.local")).tag(CodexConnectionMode.localCodex)
                Text(model.localization.text("codex.connectionMode.oauth")).tag(CodexConnectionMode.standaloneOAuth)
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            Text(model.localization.text(
                model.codexConnectionMode == .localCodex
                    ? "codex.connectionMode.localHelp"
                    : "codex.connectionMode.oauthHelp"
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)

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

                if model.codexConnectionMode == .standaloneOAuth && shouldShowConnectButton {
                    Button(connectButtonTitle) {
                        if oauthCredentialReadNeedsRetry {
                            Task { await model.retryCredentialRead() }
                        } else if let url = model.beginCodexOAuthConnection() {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .disabled(model.isRetryingCredentialRead)
                }

                if shouldShowCancelAuthorizationButton {
                    Button(model.localization.text("action.cancelAuthorization")) {
                        model.cancelCodexOAuthConnection()
                    }
                }

                if model.codexConnectionMode == .standaloneOAuth && model.codexOAuthStatus == .connected {
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

            if model.codexConnectionMode == .localCodex {
                Text(localCodexMonitorStatusText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(model.codexEventMonitorStatus == .connected ? .green : .secondary)
                    .textSelection(.enabled)
            }

            if model.codexConnectionMode == .standaloneOAuth && model.codexOAuthStatus != .connected {
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

    @ViewBuilder
    private func quotaRecoveryActions(for snapshot: ProviderQuotaSnapshot) -> some View {
        switch snapshot.recoveryAction {
        case .retry:
            Button {
                Task { await model.refresh(reason: .manual) }
            } label: {
                Label(model.localization.text("action.tryAgain"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .reconnect:
            Button {
                if model.codexConnectionMode == .localCodex {
                    Task { await model.retryLocalCodexConnection() }
                } else if let url = model.beginCodexOAuthConnection(replacingExistingAuthorization: true) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label(
                    model.localization.text(
                        model.codexConnectionMode == .localCodex
                            ? "action.retryLocalCodex"
                            : "action.reconnect"
                    ),
                    systemImage: model.codexConnectionMode == .localCodex
                        ? "arrow.clockwise"
                        : "person.badge.key.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .connect:
            Button {
                if model.codexConnectionMode == .localCodex {
                    Task { await model.retryLocalCodexConnection() }
                } else if let url = model.beginCodexOAuthConnection() {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label(
                    model.localization.text(
                        model.codexConnectionMode == .localCodex
                            ? "action.retryLocalCodex"
                            : "action.connectCodex"
                    ),
                    systemImage: model.codexConnectionMode == .localCodex
                        ? "arrow.clockwise"
                        : "key.horizontal"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .checkForUpdates:
            HStack(spacing: 8) {
                Button {
                    Task { await model.checkForUpdates(isManual: true) }
                } label: {
                    Label(model.localization.text("action.checkForUpdates"), systemImage: "arrow.triangle.2.circlepath")
                }

                Button {
                    Task { await model.refresh(reason: .manual) }
                } label: {
                    Text(model.localization.text("action.tryAgain"))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case .none:
            EmptyView()
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
        case .credentialStorageFailed:
            model.localization.text("oauth.status.credentialStorageFailed")
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
        case .credentialStorageFailed, .failed:
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
        case .credentialStorageFailed, .failed:
            .red
        case .notConnected:
            .secondary
        }
    }

    private var shouldShowConnectButton: Bool {
        model.codexOAuthStatus == .notConnected
            || model.codexOAuthStatus == .credentialStorageFailed
            || model.codexOAuthStatus == .failed
            || oauthCredentialReadNeedsRetry
    }

    private var oauthCredentialReadNeedsRetry: Bool {
        model.codexOAuthStatus == .credentialStorageFailed
            || model.snapshots.first(where: { $0.providerId == "codex-oauth" })?
                .errors.contains("oauth.error.keychainUnavailable") == true
    }

    private var shouldShowCancelAuthorizationButton: Bool {
        model.codexOAuthStatus == .waitingForCallback || model.codexOAuthStatus == .exchanging
    }

    private var connectButtonTitle: String {
        if oauthCredentialReadNeedsRetry {
            return model.localization.text("oauth.retryCredentialRead")
        }
        return model.codexOAuthStatus == .failed
            ? model.localization.text("action.retryAuthorization")
            : model.localization.text("action.connect")
    }

    private var accountDetailText: String {
        if model.codexConnectionMode == .localCodex {
            return model.localization.text(
                model.codexOAuthStatus == .connected
                    ? "codex.local.connectedDetail"
                    : "codex.local.detail"
            )
        }
        if model.codexOAuthStatus == .connected {
            return model.localization.text("provider.codexOAuth.connectedDetail")
        }

        return model.localization.text("provider.codexOAuth.detail")
    }

    private var localCodexMonitorStatusText: String {
        switch model.codexEventMonitorStatus {
        case .stopped:
            return model.localization.text("codex.monitor.stopped")
        case .connecting:
            return model.localization.text("codex.monitor.connecting")
        case .connected:
            return model.localization.text("codex.monitor.connected")
        case let .retrying(failure, attempt):
            return String(
                format: model.localization.text("codex.monitor.retrying"),
                failure.rawValue,
                attempt
            )
        }
    }

    private var refreshSummary: String {
        guard let lastRefreshAt = model.lastSuccessfulRefreshAt else {
            return model.localization.text("status.notUpdatedYet")
        }

        let time = DateFormatter.localizedString(from: lastRefreshAt, dateStyle: .none, timeStyle: .short)
        return "\(model.localization.text("dataStatus.lastSuccess")) \(time)"
    }

    private var quotaEmptyMessage: String {
        if model.codexOAuthStatus == .connected {
            return model.localization.text("empty.quota.connectedMessage")
        }

        if model.codexConnectionMode == .localCodex {
            return model.localization.text("empty.quota.localMessage")
        }

        return model.localization.text("empty.quota.codexMessage")
    }

    @MainActor
    private func updateNowWhileVisible() async {
        while !Task.isCancelled {
            let currentNow = Date()

            if model.lastRefreshAt != nil, model.shouldAutomaticallyRefresh(now: currentNow) {
                await model.refresh(reason: .automatic)
                now = Date()
            } else if currentNow.timeIntervalSince(now) >= 30 {
                now = currentNow
            }

            try? await Task.sleep(for: .seconds(1))
        }
    }
}

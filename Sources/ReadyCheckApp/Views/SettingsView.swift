import AppKit
import ReadyCheckCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: ReadyCheckAppModel

    @State private var now = Date()
    @State private var accountDetailsExpanded = false
    @State private var showDeepSeekKey = false
    @FocusState private var deepSeekConnectFocused: Bool
    @FocusState private var settingsPlatformFocus: ServiceSettingsTarget?
    @State private var restoreSettingsPlatformFocus = false
    @State private var catalogQuery = ""
    @State private var catalogBatch = 0
    @State private var scrollOffsets: [String: CGFloat] = [:]
    @State private var deepSeekOverviewDays = 1
    @State private var deepSeekUsageDays = 1
    private var deepSeek: DeepSeekConnection { model.deepSeek }
    private var showsDeepSeek: Bool { model.selectedDeepSeek }
    private var deepSeekContext: Bool {
        (model.mainWindowPage == .overview || model.mainWindowPage == .usage) && showsDeepSeek
    }
    private var scrollIdentity: String {
        model.mainNavigationRequest.uuidString + model.mainWindowPage.rawValue + (model.mainWindowPage == .settings
            ? "-\(model.mainSettingsSection.rawValue)-\(model.serviceSettingsTarget.rawValue)"
            : "-\(showsDeepSeek)")
    }
    private func scrollOffset(_ identity: String) -> Binding<CGFloat> {
        Binding(get: { scrollOffsets[identity] ?? 0 }, set: { scrollOffsets[identity] = $0 })
    }

    private let refreshIntervalOptions: [TimeInterval] = [60, 180, 300]
    private static let resetCreditRulesID = "reset-credit-rules"

    var body: some View {
        HStack(spacing: 0) {
            MainWindowSidebar(model: model)
            Divider()
            VStack(spacing: 0) {
                if model.mainWindowPage == .settings {
                    VStack(alignment: .leading, spacing: 14) {
                        pageHeader
                        settingsToolbar
                    }.padding(20)
                    Divider()
                }
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 18) {
                            if model.mainWindowPage != .settings { pageHeader }
                            updateBanner
                            switch model.mainWindowPage {
                            case .overview: overviewContent
                            case .usage: usageContent
                            case .notifications:
                                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                                    ReminderHistoryPageView(records: model.reminderHistoryRecords, localization: model.localization, deepSeekRules: model.deepSeekAlertRules) { target in
                                        model.openServiceSettings(target)
                                    }
                                }
                            case .settings: settingsContent
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(MainScrollPosition(identity: scrollIdentity, offset: scrollOffset(scrollIdentity)))
                    }
                    .id(scrollIdentity)
                    .task(id: model.resetCreditRulesNavigationRequest) {
                        guard let request = model.resetCreditRulesNavigationRequest,
                              model.mainWindowPage == .settings, model.mainSettingsSection == .reminders,
                              model.serviceSettingsTarget == .codex else { return }
                        try? await Task.sleep(for: .milliseconds(70))
                        guard !Task.isCancelled, model.resetCreditRulesNavigationRequest == request else { return }
                        scrollProxy.scrollTo(Self.resetCreditRulesID, anchor: .top)
                        model.resetCreditRulesNavigationRequest = nil
                    }
                }
            }
        }
        .frame(minWidth: 740, idealWidth: 900, minHeight: 620, idealHeight: 760)
        .task { await updateNowWhileVisible() }
        .task(id: deepSeek.connectionID) { await model.loadDeepSeekAlertRules() }
        .sheet(item: $model.resetCreditDetailSelection) { selection in
            ResetCreditDetailView(model: model, selection: selection, now: now)
        }
        .sheet(isPresented: $model.showServiceCatalog) {
            ServiceCatalogView(language: model.language, query: $catalogQuery, batch: $catalogBatch, scrollOffset: scrollOffset("catalog")) { target in
                model.openServiceSettings(target, section: .connection, fromCatalog: true)
            }
        }
        .sheet(isPresented: $showDeepSeekKey, onDismiss: { deepSeekConnectFocused = true }) {
            DeepSeekKeySheet(connection: deepSeek, language: model.language)
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.localization.text(model.mainWindowPage.titleKey)).font(.title2.weight(.semibold))
                    if model.mainWindowPage == .usage {
                        Text(showsDeepSeek ? (model.language == .zhCN ? "查看 DeepSeek 的本机余额记录。" : "View local DeepSeek balance readings.") : model.localization.text("usage.pageSubtitle"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                if model.mainWindowPage == .overview || model.mainWindowPage == .usage {
                    Button(model.language == .zhCN ? "连接设置" : "Connections") {
                        model.openServiceSettings(showsDeepSeek ? .deepSeek : .codex, section: .connection)
                    }.controlSize(.small)
                    Button(model.language == .zhCN ? "提醒设置" : "Alerts") {
                        model.openServiceSettings(showsDeepSeek ? .deepSeek : .codex)
                    }.controlSize(.small)
                    Button(model.language == .zhCN ? "更多平台" : "More platforms") {
                        model.showServiceCatalog = true
                    }
                    .controlSize(.small)
                }
                if model.mainWindowPage == .notifications {
                    Button {
                        Task { await model.reloadReminderHistory() }
                    } label: { Image(systemName: "arrow.clockwise") }
                    .help(model.localization.text("notification.history.refresh"))
                    .accessibilityLabel(model.localization.text("notification.history.refresh"))
                } else if (model.mainWindowPage == .overview || model.mainWindowPage == .usage) && deepSeekContext {
                    Button { Task { await deepSeek.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(deepSeek.isBusy)
                        .help(model.localization.text("action.refresh"))
                        .accessibilityLabel(model.localization.text("action.refresh"))
                } else if model.mainWindowPage == .overview || model.mainWindowPage == .usage {
                    DataStatusButton(model: model).controlSize(.small)
                    Button {
                        Task { await model.reloadCodexOAuthConnectionStatus(); await model.refresh(reason: .manual) }
                    } label: { Image(systemName: "arrow.clockwise") }
                    .disabled(model.isRefreshing)
                    .help(model.localization.text("action.refresh"))
                    .accessibilityLabel(model.localization.text("action.refresh"))
                }
            }
            if (model.mainWindowPage == .overview || model.mainWindowPage == .usage) && !deepSeekContext { refreshStatusView }
        }
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            serviceSwitcher
            if showsDeepSeek {
                deepSeekReadout(usage: false)
                Button(model.language == .zhCN ? "前往余额提醒设置" : "Balance alert settings") {
                    model.openServiceSettings(.deepSeek)
                }.buttonStyle(.link)
            } else {
                codexOverviewContent
            }
        }
    }

    private var serviceSwitcher: some View {
        HStack(spacing: 3) {
            serviceSwitcherButton("Codex", icon: "readycheck", fileExtension: "png", selected: false)
            serviceSwitcherButton("DeepSeek", icon: "deepseek", fileExtension: "svg", selected: true)
        }
        .padding(3)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
        .onMoveCommand { direction in
            if direction == .left { model.selectedDeepSeek = false }
            if direction == .right { model.selectedDeepSeek = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func serviceSwitcherButton(_ title: String, icon: String, fileExtension: String, selected: Bool) -> some View {
        Button { model.selectedDeepSeek = selected } label: {
            HStack(spacing: 6) {
                ServiceSwitcherIcon(name: icon, extension: fileExtension)
                Text(title)
                Text(selected ? deepSeekConnectionLabel : model.localization.text(model.codexOAuthStatus == .connected ? "oauth.status.connected" : "oauth.status.notConnected"))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(showsDeepSeek == selected ? Color.accentColor.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(selected ? deepSeekConnectionLabel : model.localization.text(model.codexOAuthStatus == .connected ? "oauth.status.connected" : "oauth.status.notConnected"))
        .accessibilityAddTraits(showsDeepSeek == selected ? .isSelected : [])
    }

    private var deepSeekConnectionLabel: String {
        if deepSeek.credentialError { return model.language == .zhCN ? "需系统授权" : "Needs access" }
        if deepSeek.error != nil { return model.language == .zhCN ? "刷新失败" : "Refresh failed" }
        return model.language == .zhCN ? (deepSeek.isConnected ? "已连接" : "未连接") : (deepSeek.isConnected ? "Connected" : "Not connected")
    }

    @ViewBuilder private func deepSeekReadout(usage: Bool) -> some View {
        if deepSeek.isConnected && !deepSeek.credentialError {
            DeepSeekOverview(connection: deepSeek, language: model.language, now: now, days: usage ? $deepSeekUsageDays : $deepSeekOverviewDays)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("DeepSeek").font(.title2.weight(.semibold))
                Text(deepSeekConnectionLabel).font(.headline)
                Text(model.language == .zhCN ? "通过 API Key 连接，查看 API 账户余额、赠送与充值分项及本机余额记录。" : "Connect with an API key to view API account balances, granted and topped-up funds, and local readings.")
                    .foregroundStyle(.secondary)
                if deepSeek.credentialError {
                    Text(model.language == .zhCN ? "已有凭据暂时无法访问，不代表账号已退出。请重试读取并在系统提示中授权。" : "Saved credentials are temporarily inaccessible; this does not mean you signed out. Retry and allow access in the system prompt.")
                        .font(.callout).foregroundStyle(.orange)
                    Button(model.language == .zhCN ? "重试读取凭据" : "Retry credential access") { Task { await deepSeek.retryCredentialRead() } }
                        .buttonStyle(.borderedProminent).disabled(deepSeek.isBusy)
                } else {
                    Button(model.language == .zhCN ? "连接 DeepSeek API" : "Connect DeepSeek API") { showDeepSeekKey = true }
                        .focusable().focused($deepSeekConnectFocused)
                        .buttonStyle(.borderedProminent).disabled(deepSeek.isBusy)
                }
            }.padding(.vertical, 12)
        }
    }

    private var codexOverviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            OverviewQuotaView(model: model, now: now)
            if model.snapshots.isEmpty {
                Text(quotaEmptyMessage).font(.callout).foregroundStyle(.secondary)
                Button(model.localization.text("navigation.connection")) {
                    model.openServiceSettings(.codex, section: .connection)
                }
            }
            Divider()
            NextEventsView(model: model, now: now)
            ForEach(model.snapshots.filter { $0.providerId == "codex-oauth" }) { snapshot in
                quotaRecoveryActions(for: snapshot)
            }
            Divider()
            RecentUsageView(samples: model.quotaHistorySamples,
                localization: model.localization, now: now)
            ForEach(model.snapshots.filter { $0.providerId == "codex-oauth" }) { snapshot in
                Divider()
                DisclosureGroup(isExpanded: $accountDetailsExpanded) {
                    QuotaCardView(snapshot: snapshot, localization: model.localization, now: now, displayMode: .accountDetails,
                        onResetCreditDetails: { model.resetCreditDetailSelection = .available($0) })
                    if !model.currentResetCreditRecords.isEmpty || !model.resetCreditChecks.isEmpty || model.resetCreditHistoryUnavailable || model.resetCreditChecksUnavailable {
                        ResetCreditHistoryView(model: model)
                    }
                } label: {
                    accountCardSummary(snapshot)
                }
            }
            legacyHistoryNotice
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
            serviceSwitcher
            if showsDeepSeek {
                Text(model.language == .zhCN ? "此连接仅提供余额，不提供 Token 或费用统计。" : "This connection provides balances, not token or expense statistics.")
                    .font(.caption).foregroundStyle(.secondary)
                deepSeekReadout(usage: true)
            } else {
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                    TokenUsageView(usage: model.snapshots.first { $0.providerId == "codex-oauth" }?.details?.accountTokenUsage,
                        localization: model.localization, now: now)
                }
                legacyHistoryNotice
            }
        }
    }

    private var settingsToolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.settingsHasReturn {
                Button { model.closeServiceSettings() } label: {
                    Label(model.settingsReturnTitle, systemImage: "arrow.left")
                }.buttonStyle(.link)
            }
            Picker(model.localization.text("navigation.settings"), selection: $model.mainSettingsSection) {
                ForEach(MainSettingsSection.allCases) { section in
                    Text(model.localization.text(section.titleKey)).tag(section)
                }
            }.pickerStyle(.segmented).labelsHidden()
            Text(model.localization.text("navigation.settings") + " / " + model.localization.text(model.mainSettingsSection.titleKey)
                + ([MainSettingsSection.reminders, .connection].contains(model.mainSettingsSection) ? " / " + (model.serviceSettingsTarget == .deepSeek ? "DeepSeek" : "Codex") : ""))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var settingsPlatformPicker: some View {
        HStack(spacing: 3) {
            settingsPlatformButton(.codex)
            settingsPlatformButton(.deepSeek)
        }
        .padding(3)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.language == .zhCN ? "平台" : "Platform")
        .onMoveCommand { direction in
            if direction == .left { selectSettingsPlatform(.codex) }
            if direction == .right { selectSettingsPlatform(.deepSeek) }
        }
        .task(id: model.serviceSettingsTarget) {
            guard restoreSettingsPlatformFocus else { return }
            await Task.yield()
            guard !Task.isCancelled else { return }
            settingsPlatformFocus = model.serviceSettingsTarget
            restoreSettingsPlatformFocus = false
        }
    }

    private func selectSettingsPlatform(_ target: ServiceSettingsTarget) {
        restoreSettingsPlatformFocus = model.serviceSettingsTarget != target
        model.serviceSettingsTarget = target
        settingsPlatformFocus = target
    }

    private func settingsPlatformButton(_ target: ServiceSettingsTarget) -> some View {
        let isCodex = target == .codex
        let selected = model.serviceSettingsTarget == target
        let title = isCodex ? "Codex" : "DeepSeek"
        return Button { selectSettingsPlatform(target) } label: {
            HStack(spacing: 6) {
                ServiceSwitcherIcon(name: isCodex ? "readycheck" : "deepseek", extension: isCodex ? "png" : "svg")
                Text(title)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(selected ? Color.accentColor.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable()
        .focused($settingsPlatformFocus, equals: target)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if model.mainSettingsSection == .connection || model.mainSettingsSection == .reminders { settingsPlatformPicker }
            switch model.mainSettingsSection {
            case .reminders:
                if model.serviceSettingsTarget == .deepSeek {
                    GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { DeepSeekAlertControls(model: model) }
                } else {
                    GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(model.localization.text("settings.quotaReminders")).font(.headline)
                            QuotaRecoveryReminderView(model: model, now: now)
                        }
                    }
                    GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(model.localization.text("settings.cardReminders")).font(.headline)
                            ResetExpiryReminderView(model: model)
                        }
                    }
                    GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { ResetCreditAutomationView(model: model) }
                        .id(Self.resetCreditRulesID)
                }
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { notificationControls }
            case .display:
                quotaWindowControls
                widgetControls
                notchControls
                Toggle(model.localization.text("settings.hideInFullscreen"), isOn: $model.widgetHideInFullscreen)
                    .toggleStyle(.switch).controlSize(.small)
                Text(model.localization.text("settings.hideInFullscreenHelp")).font(.caption).foregroundStyle(.secondary)
            case .connection:
                if model.serviceSettingsTarget == .deepSeek {
                    GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { DeepSeekConnectionControls(connection: deepSeek, language: model.language) }
                } else {
                    GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { codexOAuthProviderControls }
                }
                productSummary
            case .general:
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { generalControls }
                GlassSurface(cornerRadius: 18, renderingMode: .staticSurface) { notificationControls }
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
        CurrentReadoutView(model: model, now: now)
    }

    private func accountCardSummary(_ snapshot: ProviderQuotaSnapshot) -> some View {
        let details = snapshot.details
        let dates = details?.manualResetExpirations ?? []
        let count = details?.manualResetCount ?? (dates.isEmpty ? nil : dates.count)
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "ticket").foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(count.map { String(format: model.localization.text("overview.cardCount"), $0) }
                    ?? model.localization.text("overview.cardCountUnknown"))
                    .font(.subheadline.weight(.medium))
                if let nearest = dates.filter({ $0 > now }).min() {
                    Text(model.localization.text("overview.nearestExpiry") + " " + nearest.formatted(.dateTime
                        .locale(Locale(identifier: model.language.rawValue)).month().day().hour().minute()))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
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

                    Text(model.localization.text(model.notchShowsBothQuotas
                        ? "settings.quotaWindowHelp.dual" : "settings.quotaWindowHelp"))
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

            HStack {
                Text(model.localization.text("settings.notchQuotaLayout"))
                Spacer(minLength: 8)
                Picker(model.localization.text("settings.notchQuotaLayout"), selection: $model.notchShowsBothQuotas) {
                    Text(model.localization.text("settings.notchQuotaLayout.dual")).tag(true)
                    Text(model.localization.text("settings.notchQuotaLayout.single")).tag(false)
                }
                .labelsHidden().pickerStyle(.segmented).frame(width: 220)
            }
            Text(model.localization.text("settings.notchQuotaLayout.help"))
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
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

            Text(model.localization.text("oauth.singleConnectionHelp")).font(.footnote).foregroundStyle(.secondary)

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
                if let url = model.beginCodexOAuthConnection(replacingExistingAuthorization: true) { NSWorkspace.shared.open(url) }
            } label: {
                Label(model.localization.text("action.reconnect"), systemImage: "person.badge.key.fill")
            }.buttonStyle(.borderedProminent).controlSize(.small)

        case .connect:
            Button {
                if let url = model.beginCodexOAuthConnection() { NSWorkspace.shared.open(url) }
            } label: {
                Label(model.localization.text("oauth.signIn"), systemImage: "key.horizontal")
            }.buttonStyle(.borderedProminent).controlSize(.small)

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
            : model.localization.text("oauth.signIn")
    }

    private var accountDetailText: String {
        if model.codexOAuthStatus == .connected {
            return model.localization.text("provider.codexOAuth.connectedDetail")
        }

        return model.localization.text("provider.codexOAuth.detail")
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

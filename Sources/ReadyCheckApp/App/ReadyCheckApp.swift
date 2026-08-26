import AppKit
import Observation
import OSLog
import ReadyCheckCore
import Security
import SwiftUI

enum CodexOAuthConnectionStatus: Equatable {
    case notConnected
    case waitingForCallback
    case exchanging
    case connected
    case credentialStorageFailed
    case failed
}

enum AppUpdateStatus: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable(AppUpdate)
    case failed
}

@MainActor private var readyCheckApplicationDelegate: ReadyCheckApplication?

@main
@MainActor
final class ReadyCheckApplication: NSObject, NSApplicationDelegate {
    private let appModel = ReadyCheckAppModel()
    private var mainWindow: NSWindow?
    private var statusBarController: StatusBarController?

    override init() {
        super.init()
        appModel.openMainWindow = { [weak self] in
            self?.showMainWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    static func main() {
        let application = NSApplication.shared
        let delegate = ReadyCheckApplication()
        readyCheckApplicationDelegate = delegate
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.finishLaunching()
        delegate.showMainWindow()
        application.activate(ignoringOtherApps: true)
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        configureStatusBarItem()
        showMainWindow()
        Task {
            await appModel.requestNotificationAuthorizationIfNeeded()
            await appModel.reloadCodexOAuthConnectionStatus()
            await appModel.reloadQuotaHistory()
            await appModel.reloadReminderHistory()
            await appModel.refresh(reason: .openedPanel)
            await appModel.checkForUpdates(isManual: false)
            appModel.restoreFloatingWidgetIfNeeded()
            appModel.restoreNotchStatusIfNeeded()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        sender.activate(ignoringOtherApps: true)
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        Task { await appModel.reloadNotificationReadiness() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureStatusBarItem() {
        guard statusBarController == nil else { return }

        statusBarController = StatusBarController(model: appModel) { [weak self] in
            self?.showMainWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")

        appMenu.addItem(
            withTitle: appModel.localization.text("about.menuItem"),
            action: #selector(showAboutWindow),
            keyEquivalent: ""
        ).target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Quit ReadyCheck",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        fileMenu.addItem(
            withTitle: appModel.localization.text("action.closeWindow"),
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc
    private func showAboutWindow() {
        appModel.showAboutWindow()
    }

    fileprivate func showMainWindow() {
        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.orderFrontRegardless()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 760),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ReadyCheck"
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .managed]
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView(model: appModel))
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        mainWindow = window
    }
}

@MainActor
@Observable
final class ReadyCheckAppModel {
    private static let widgetAlwaysOnTopDefaultsKey = "ReadyCheck.widgetAlwaysOnTop.v1"
    private static let notchStatusVisibleDefaultsKey = "ReadyCheck.notchStatusVisible.v1"
    private static let oauthLogger = Logger(subsystem: "com.readycheck.app", category: "oauth")

    var language: AppLanguage = .zhCN
    var refreshInterval: TimeInterval = 60
    var widgetVisible: Bool = WidgetVisibilityPreference.value() {
        didSet {
            guard widgetVisible != oldValue else { return }

            guard !isSyncingWidgetVisibilityFromWindow else { return }

            if widgetVisible {
                floatingWindowController.showAtDefaultPosition(model: self)
            } else {
                floatingWindowController.close()
            }
        }
    }
    var widgetAlwaysOnTop: Bool = UserDefaults.standard.object(forKey: widgetAlwaysOnTopDefaultsKey) as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(widgetAlwaysOnTop, forKey: Self.widgetAlwaysOnTopDefaultsKey)
            floatingWindowController.updateLevel(alwaysOnTop: widgetAlwaysOnTop)
        }
    }
    var widgetDisplayMode: WidgetDisplayMode = WidgetDisplayModePreference.value() {
        didSet {
            WidgetDisplayModePreference.set(widgetDisplayMode)
        }
    }
    var notchStatusVisible: Bool = UserDefaults.standard.bool(forKey: notchStatusVisibleDefaultsKey) {
        didSet {
            guard notchStatusVisible != oldValue else { return }
            UserDefaults.standard.set(notchStatusVisible, forKey: Self.notchStatusVisibleDefaultsKey)
            if notchStatusVisible {
                notchWindowController.show(model: self)
            } else {
                notchWindowController.close()
            }
        }
    }
    var mockProviderEnabled = false {
        didSet {
            rebuildStoreIfConfigurationChanged(oldValue: oldValue, newValue: mockProviderEnabled)
        }
    }
    var localCodexProviderEnabled = false {
        didSet {
            rebuildStoreIfConfigurationChanged(oldValue: oldValue, newValue: localCodexProviderEnabled)
        }
    }
    var codexOAuthProviderEnabled = true {
        didSet {
            rebuildStoreIfConfigurationChanged(oldValue: oldValue, newValue: codexOAuthProviderEnabled)
        }
    }
    var snapshots: [ProviderQuotaSnapshot] = []
    var quotaHistorySamples: [QuotaHistorySample] = []
    var reminderHistoryRecords: [QuotaReminderHistoryRecord] = []
    var notificationReadiness: NotificationReadiness = .checking
    var testNotificationResult: TestNotificationResult = .idle
    var isRefreshing = false
    var lastRefreshAt: Date?
    var codexOAuthStatus: CodexOAuthConnectionStatus = .notConnected
    var codexOAuthCallbackURL = ""
    var codexOAuthStatusMessage: String?
    var codexOAuthLoginEmail: String?
    var updateStatus: AppUpdateStatus = .idle
    var updatePromptState = UpdatePromptState()

    @ObservationIgnored
    private let credentialStore: any CredentialStore

    @ObservationIgnored
    private let codexOAuthClient: CodexOAuthClient

    @ObservationIgnored
    private let updateChecker: GitHubReleaseUpdateChecker

    @ObservationIgnored
    private let quotaHistoryStore: QuotaHistoryStore

    @ObservationIgnored
    private let quotaReminderStore: QuotaReminderStore

    @ObservationIgnored
    private let quotaNotificationService: QuotaNotificationService

    @ObservationIgnored
    private let codexAppServerClient: any CodexAppServerReading

    @ObservationIgnored
    private var store: QuotaStore

    @ObservationIgnored
    private var storeGeneration = 0

    @ObservationIgnored
    private let floatingWindowController = FloatingWindowController()

    @ObservationIgnored
    private let notchWindowController = NotchWindowController()

    @ObservationIgnored
    private let aboutWindowController = AboutWindowController()

    @ObservationIgnored
    var openMainWindow: (() -> Void)?

    @ObservationIgnored
    private var pendingCodexOAuthSession: CodexOAuthSession?

    @ObservationIgnored
    private var wasConnectedBeforePendingAuthorization = false

    @ObservationIgnored
    private var oauthCallbackServer: OAuthLoopbackCallbackServer?

    @ObservationIgnored
    private var isSyncingWidgetVisibilityFromWindow = false

    init(
        credentialStore: any CredentialStore = KeychainCredentialStore(),
        codexOAuthClient: CodexOAuthClient = CodexOAuthClient(),
        updateChecker: GitHubReleaseUpdateChecker = GitHubReleaseUpdateChecker(),
        quotaHistoryStore: QuotaHistoryStore? = nil,
        codexAppServerClient: any CodexAppServerReading = CodexAppServerClient()
    ) {
        self.credentialStore = credentialStore
        self.codexOAuthClient = codexOAuthClient
        self.updateChecker = updateChecker
        self.codexAppServerClient = codexAppServerClient
        self.quotaHistoryStore = quotaHistoryStore ?? QuotaHistoryStore(fileURL: Self.defaultQuotaHistoryURL)
        self.quotaReminderStore = QuotaReminderStore(fileURL: Self.defaultQuotaReminderURL)
        self.quotaNotificationService = QuotaNotificationService()
        self.store = QuotaStore(
            registry: ProviderRegistry(
                configurations: ProviderConfiguration.defaults,
                credentialStore: credentialStore,
                codexAppServerClient: codexAppServerClient
            )
        )
        self.floatingWindowController.onVisibilityChanged = { [weak self] isVisible in
            self?.syncWidgetVisibilityFromWindow(isVisible)
        }
    }

    var localization: LocalizationService {
        LocalizationService(language: language)
    }

    var providerConfigurations: [ProviderConfiguration] {
        [
            ProviderConfiguration(provider: .mock, isEnabled: mockProviderEnabled),
            ProviderConfiguration(provider: .localCodex, isEnabled: localCodexProviderEnabled),
            ProviderConfiguration(provider: .codexOAuth, isEnabled: codexOAuthProviderEnabled)
        ]
    }

    func hasStaleSnapshots(now: Date) -> Bool {
        snapshots.contains { $0.isStale(now: now) }
    }

    func restoreFloatingWidgetIfNeeded() {
        guard widgetVisible else { return }
        floatingWindowController.showAtDefaultPosition(model: self)
    }

    var notchStatusAvailable: Bool {
        notchWindowController.isAvailable
    }

    func restoreNotchStatusIfNeeded() {
        guard notchStatusVisible else { return }
        notchWindowController.show(model: self)
    }

    func requestNotificationAuthorizationIfNeeded() async {
        await quotaNotificationService.requestAuthorizationIfNeeded()
        notificationReadiness = await quotaNotificationService.readiness()
    }

    func reloadNotificationReadiness() async {
        notificationReadiness = await quotaNotificationService.readiness()
    }

    func sendTestNotification() async {
        testNotificationResult = .sending
        let delivered = await quotaNotificationService.sendTestNotification(localization: localization)
        notificationReadiness = await quotaNotificationService.readiness()
        testNotificationResult = delivered ? .delivered : .failed
    }

    func openNotificationSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension?bundleId=com.readycheck.app",
            "x-apple.systempreferences:com.apple.preference.notifications"
        ]
        for value in urls {
            guard let url = URL(string: value), NSWorkspace.shared.open(url) else { continue }
            return
        }
    }

    func showFloatingWidget() {
        if widgetVisible {
            floatingWindowController.showAtDefaultPosition(model: self)
        } else {
            widgetVisible = true
        }
    }

    func hideFloatingWidget() {
        widgetVisible = false
    }

    func resetFloatingWidgetPosition() {
        if widgetVisible {
            floatingWindowController.resetPosition(model: self)
        } else {
            widgetVisible = true
        }
    }

    func openMainWindowFromWidget() {
        openMainWindow?()
    }

    func showAboutWindow() {
        aboutWindowController.show(localization: localization)
    }

    func checkForUpdates(isManual: Bool) async {
        updateStatus = .checking

        do {
            switch try await updateChecker.check(currentVersion: ReadyCheckCore.version) {
            case .upToDate:
                updateStatus = isManual ? .upToDate : .idle
            case .updateAvailable(let update):
                updateStatus = .updateAvailable(update)
            }
        } catch {
            updateStatus = isManual ? .failed : .idle
        }
    }

    func openUpdateReleasePage() {
        guard case .updateAvailable(let update) = updateStatus else { return }
        NSWorkspace.shared.open(update.releaseURL)
    }

    var visibleUpdate: AppUpdate? {
        guard case .updateAvailable(let update) = updateStatus else { return nil }
        guard updatePromptState.shouldShowBanner(for: update) else { return nil }
        return update
    }

    func dismissVisibleUpdate() {
        guard case .updateAvailable(let update) = updateStatus else { return }
        updatePromptState.dismiss(update)
    }

    var isCodexOAuthCallbackInputVisible: Bool {
        codexOAuthStatus == .waitingForCallback || codexOAuthStatus == .exchanging
    }

    private func syncWidgetVisibilityFromWindow(_ isVisible: Bool) {
        guard widgetVisible != isVisible else { return }

        isSyncingWidgetVisibilityFromWindow = true
        widgetVisible = isVisible
        isSyncingWidgetVisibilityFromWindow = false
    }

    func reloadCodexOAuthConnectionStatus() async {
        do {
            let tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
            if let token = try await tokenStore.loadToken() {
                codexOAuthStatus = .connected
                codexOAuthStatusMessage = nil
                codexOAuthLoginEmail = token.loginEmail
            } else if !isCodexOAuthCallbackInputVisible {
                codexOAuthStatus = .notConnected
                codexOAuthStatusMessage = nil
                codexOAuthLoginEmail = nil
            }
        } catch {
            codexOAuthStatus = isCredentialStorageError(error) ? .credentialStorageFailed : .failed
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
            codexOAuthLoginEmail = nil
        }
    }

    func beginCodexOAuthConnection(replacingExistingAuthorization: Bool = false) -> URL? {
        do {
            let authorizer = CodexOAuthAuthorizer(
                client: codexOAuthClient,
                tokenStore: CodexOAuthTokenStore(credentialStore: credentialStore)
            )
            let session = try authorizer.begin()
            pendingCodexOAuthSession = session
            wasConnectedBeforePendingAuthorization = replacingExistingAuthorization && codexOAuthStatus == .connected
            codexOAuthProviderEnabled = true
            codexOAuthStatus = .waitingForCallback
            codexOAuthStatusMessage = nil
            if !wasConnectedBeforePendingAuthorization {
                codexOAuthLoginEmail = nil
            }
            startCodexOAuthCallbackServer()
            return session.authorizationURL
        } catch {
            codexOAuthStatus = .failed
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
            return nil
        }
    }

    func completeCodexOAuthConnection(callbackURL: String? = nil) async {
        guard let session = pendingCodexOAuthSession else {
            codexOAuthStatus = .failed
            codexOAuthStatusMessage = localization.text("oauth.error.missingSession")
            return
        }

        let callback = callbackURL ?? codexOAuthCallbackURL

        codexOAuthStatus = .exchanging
        codexOAuthStatusMessage = nil

        do {
            let authorizer = CodexOAuthAuthorizer(
                client: codexOAuthClient,
                tokenStore: CodexOAuthTokenStore(credentialStore: credentialStore)
            )
            let token = try await authorizer.complete(callbackURL: callback, session: session)
            if normalizedEmail(codexOAuthLoginEmail) != normalizedEmail(token.loginEmail) {
                await quotaReminderStore.clearKnownManualResetExpirations()
            }
            pendingCodexOAuthSession = nil
            codexOAuthCallbackURL = ""
            stopCodexOAuthCallbackServer()
            codexOAuthProviderEnabled = true
            codexOAuthStatus = .connected
            codexOAuthLoginEmail = token.loginEmail
            wasConnectedBeforePendingAuthorization = false
            await refresh(reason: .manual)
        } catch {
            Self.oauthLogger.error("OAuth authorization failed: \(self.oauthLogSummary(for: error), privacy: .public)")
            pendingCodexOAuthSession = nil
            codexOAuthCallbackURL = ""
            stopCodexOAuthCallbackServer()
            codexOAuthStatus = wasConnectedBeforePendingAuthorization
                ? .connected
                : (isCredentialStorageError(error) ? .credentialStorageFailed : .failed)
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
            if !wasConnectedBeforePendingAuthorization {
                codexOAuthLoginEmail = nil
            }
            wasConnectedBeforePendingAuthorization = false
        }
    }

    func cancelCodexOAuthConnection() {
        pendingCodexOAuthSession = nil
        codexOAuthCallbackURL = ""
        stopCodexOAuthCallbackServer()
        codexOAuthStatus = wasConnectedBeforePendingAuthorization ? .connected : .notConnected
        codexOAuthStatusMessage = nil
        if !wasConnectedBeforePendingAuthorization {
            codexOAuthLoginEmail = nil
        }
        wasConnectedBeforePendingAuthorization = false
    }

    func disconnectCodexOAuth() async {
        do {
            let authorizer = CodexOAuthAuthorizer(
                client: codexOAuthClient,
                tokenStore: CodexOAuthTokenStore(credentialStore: credentialStore)
            )
            try await authorizer.disconnect()
            await quotaReminderStore.clearKnownManualResetExpirations()
            pendingCodexOAuthSession = nil
            codexOAuthCallbackURL = ""
            stopCodexOAuthCallbackServer()
            codexOAuthStatus = .notConnected
            codexOAuthStatusMessage = nil
            codexOAuthLoginEmail = nil
            codexOAuthProviderEnabled = false
            wasConnectedBeforePendingAuthorization = false
        } catch {
            codexOAuthStatus = isCredentialStorageError(error) ? .credentialStorageFailed : .failed
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
        }
    }

    private func startCodexOAuthCallbackServer() {
        stopCodexOAuthCallbackServer()

        let server = OAuthLoopbackCallbackServer()
        do {
            try server.start(
                onReady: { [weak self] in
                    Task { @MainActor in
                        guard self?.codexOAuthStatus == .waitingForCallback else { return }
                        self?.codexOAuthStatusMessage = self?.localization.text("oauth.callback.listening")
                    }
                },
                onCallback: { [weak self] callbackURL in
                    Task { @MainActor in
                        await self?.completeCodexOAuthConnection(callbackURL: callbackURL)
                    }
                },
                onFailure: { [weak self] error in
                    Task { @MainActor in
                        guard self?.codexOAuthStatus == .waitingForCallback else { return }
                        Self.oauthLogger.error("OAuth callback listener failed: \(String(describing: error), privacy: .public)")
                        self?.codexOAuthStatusMessage = self?.localization.text("oauth.callback.manualFallback")
                    }
                }
            )
            oauthCallbackServer = server
            codexOAuthStatusMessage = localization.text("oauth.callback.starting")
        } catch {
            Self.oauthLogger.error("OAuth callback listener could not start: \(String(describing: error), privacy: .public)")
            codexOAuthStatusMessage = localization.text("oauth.callback.manualFallback")
        }
    }

    private func stopCodexOAuthCallbackServer() {
        oauthCallbackServer?.stop()
        oauthCallbackServer = nil
    }

    private func codexOAuthMessage(for error: Error) -> String {
        if error is URLError {
            return localization.text("oauth.error.network")
        }

        if let keychainError = error as? KeychainCredentialStoreError {
            switch keychainError {
            case let .unexpectedStatus(status) where isLockedKeychainStatus(Int(status)):
                return localization.text("oauth.error.keychainUnavailable")
            case .unexpectedStatus, .invalidCredentialData:
                return localization.text("oauth.error.credentialStorageFailed")
            }
        }

        guard let oauthError = error as? CodexOAuthError else {
            return localization.text("oauth.error.authorizationFailed")
        }

        switch oauthError {
        case .stateMismatch:
            return localization.text("oauth.error.stateMismatch")
        case .missingAuthorizationCode, .invalidCallbackURL:
            return localization.text("oauth.error.invalidCallback")
        case let .callbackFailed(error, description):
            guard let reason = oauthReason(error: error, description: description) else {
                return localization.text("oauth.error.callbackFailed")
            }
            return String(format: localization.text("oauth.error.callbackFailedDetail"), reason)
        case let .tokenRequestFailed(statusCode, error, description):
            guard let reason = oauthReason(error: error, description: description) else {
                return String(format: localization.text("oauth.error.tokenExchangeFailedStatus"), statusCode)
            }
            return String(format: localization.text("oauth.error.tokenExchangeFailedDetail"), statusCode, reason)
        case .unsafeOAuthEndpoint:
            return localization.text("oauth.error.unsafeEndpoint")
        case .invalidTokenResponse:
            return localization.text("oauth.error.invalidTokenResponse")
        case let .credentialStorageFailed(statusCode):
            if let statusCode, isLockedKeychainStatus(statusCode) {
                return localization.text("oauth.error.keychainUnavailable")
            }
            guard let statusCode else {
                return localization.text("oauth.error.credentialStorageFailed")
            }
            return String(format: localization.text("oauth.error.credentialStorageFailedStatus"), statusCode)
        case .pkceGenerationFailed, .stateGenerationFailed, .invalidAuthorizationURL, .invalidStoredToken:
            return localization.text("oauth.error.authorizationFailed")
        }
    }

    private func oauthReason(error: String?, description: String?) -> String? {
        let preferred = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = error?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = [preferred, fallback].compactMap({ $0 }).first(where: { !$0.isEmpty }) else {
            return nil
        }
        let singleLine = value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return String(singleLine.prefix(240))
    }

    private func isLockedKeychainStatus(_ status: Int) -> Bool {
        status == Int(errSecAuthFailed)
            || status == Int(errSecInteractionNotAllowed)
            || status == Int(errSecNotAvailable)
    }

    private func isCredentialStorageError(_ error: Error) -> Bool {
        if error is KeychainCredentialStoreError {
            return true
        }
        guard let oauthError = error as? CodexOAuthError else {
            return false
        }
        if case .credentialStorageFailed = oauthError {
            return true
        }
        return false
    }

    private func oauthLogSummary(for error: Error) -> String {
        guard let oauthError = error as? CodexOAuthError else {
            return error is URLError ? "network_error" : "unexpected_error"
        }

        switch oauthError {
        case .callbackFailed:
            return "callback_failed"
        case let .tokenRequestFailed(statusCode, _, _):
            return "token_request_failed:http_\(statusCode)"
        case .stateMismatch:
            return "state_mismatch"
        case .missingAuthorizationCode:
            return "missing_authorization_code"
        case .invalidCallbackURL:
            return "invalid_callback_url"
        case .invalidTokenResponse:
            return "invalid_token_response"
        case let .credentialStorageFailed(statusCode):
            return "credential_storage_failed:osstatus_\(statusCode.map(String.init) ?? "unknown")"
        case .unsafeOAuthEndpoint:
            return "unsafe_oauth_endpoint"
        case .pkceGenerationFailed:
            return "pkce_generation_failed"
        case .stateGenerationFailed:
            return "state_generation_failed"
        case .invalidAuthorizationURL:
            return "invalid_authorization_url"
        case .invalidStoredToken:
            return "invalid_stored_token"
        }
    }

    func shouldAutomaticallyRefresh(now: Date) -> Bool {
        guard !isRefreshing else { return false }

        let scheduler = RefreshScheduler(policy: RefreshPolicy(interval: refreshInterval))
        return scheduler.shouldRefresh(lastRefresh: lastRefreshAt, now: now, reason: .automatic)
    }

    func refresh(reason: RefreshReason) async {
        guard !isRefreshing else { return }

        let activeStore = store
        let activeStoreGeneration = storeGeneration

        isRefreshing = true
        defer { isRefreshing = false }

        await activeStore.refreshAll(reason: reason)
        guard activeStoreGeneration == storeGeneration else { return }

        let refreshCompletedAt = Date()
        let knownManualResetExpirations = await quotaReminderStore.knownManualResetExpirations(
            now: refreshCompletedAt
        )
        let refreshedSnapshots = await activeStore.snapshots
        snapshots = refreshedSnapshots.map {
            $0.providerId == "codex-oauth"
                ? $0.preservingKnownManualResetExpirations(
                    knownManualResetExpirations,
                    now: refreshCompletedAt
                )
                : $0
        }
        lastRefreshAt = refreshCompletedAt
        for snapshot in snapshots where snapshot.providerId == "codex-oauth" && snapshot.status == .available {
            quotaHistorySamples = await quotaHistoryStore.record(snapshot)
            let reminderBatch = await quotaReminderStore.prepare(snapshot)
            let deliveredEvents = await quotaNotificationService.deliver(
                reminderBatch.events,
                localization: localization
            )
            await quotaReminderStore.commit(reminderBatch, deliveredEvents: deliveredEvents)
            reminderHistoryRecords = await quotaReminderStore.history()
        }
    }

    func reloadQuotaHistory() async {
        quotaHistorySamples = await quotaHistoryStore.load()
    }

    func reloadReminderHistory() async {
        reminderHistoryRecords = await quotaReminderStore.history()
    }

    private func normalizedEmail(_ email: String?) -> String? {
        let normalized = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized?.isEmpty == false ? normalized : nil
    }

    private func rebuildStoreIfConfigurationChanged(oldValue: Bool, newValue: Bool) {
        guard oldValue != newValue else { return }

        store = QuotaStore(
            registry: ProviderRegistry(
                configurations: providerConfigurations,
                credentialStore: credentialStore,
                codexAppServerClient: codexAppServerClient
            )
        )
        storeGeneration += 1
        snapshots = []
        lastRefreshAt = nil
    }

    private static var defaultQuotaHistoryURL: URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return applicationSupport
            .appendingPathComponent("ReadyCheck", isDirectory: true)
            .appendingPathComponent("quota-history.json")
    }

    private static var defaultQuotaReminderURL: URL {
        defaultQuotaHistoryURL
            .deletingLastPathComponent()
            .appendingPathComponent("quota-reminders.json")
    }
}

import AppKit
import Observation
import ReadyCheckCore
import SwiftUI

enum CodexOAuthConnectionStatus: Equatable {
    case notConnected
    case waitingForCallback
    case exchanging
    case connected
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
            await appModel.reloadCodexOAuthConnectionStatus()
            await appModel.refresh(reason: .openedPanel)
            await appModel.checkForUpdates(isManual: false)
            appModel.restoreFloatingWidgetIfNeeded()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        sender.activate(ignoringOtherApps: true)
        return true
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
    var isRefreshing = false
    var lastRefreshAt: Date?
    var codexOAuthStatus: CodexOAuthConnectionStatus = .notConnected
    var codexOAuthCallbackURL = ""
    var codexOAuthStatusMessage: String?
    var codexOAuthLoginEmail: String?
    var updateStatus: AppUpdateStatus = .idle

    @ObservationIgnored
    private let credentialStore: any CredentialStore

    @ObservationIgnored
    private let codexOAuthClient: CodexOAuthClient

    @ObservationIgnored
    private let updateChecker: GitHubReleaseUpdateChecker

    @ObservationIgnored
    private var store: QuotaStore

    @ObservationIgnored
    private var storeGeneration = 0

    @ObservationIgnored
    private let floatingWindowController = FloatingWindowController()

    @ObservationIgnored
    private let aboutWindowController = AboutWindowController()

    @ObservationIgnored
    var openMainWindow: (() -> Void)?

    @ObservationIgnored
    private var pendingCodexOAuthSession: CodexOAuthSession?

    @ObservationIgnored
    private var oauthCallbackServer: OAuthLoopbackCallbackServer?

    @ObservationIgnored
    private var isSyncingWidgetVisibilityFromWindow = false

    init(
        credentialStore: any CredentialStore = KeychainCredentialStore(),
        codexOAuthClient: CodexOAuthClient = CodexOAuthClient(),
        updateChecker: GitHubReleaseUpdateChecker = GitHubReleaseUpdateChecker()
    ) {
        self.credentialStore = credentialStore
        self.codexOAuthClient = codexOAuthClient
        self.updateChecker = updateChecker
        self.store = QuotaStore(
            registry: ProviderRegistry(
                configurations: ProviderConfiguration.defaults,
                credentialStore: credentialStore
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
            codexOAuthStatus = .failed
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
            codexOAuthLoginEmail = nil
        }
    }

    func beginCodexOAuthConnection() -> URL? {
        do {
            let authorizer = CodexOAuthAuthorizer(
                client: codexOAuthClient,
                tokenStore: CodexOAuthTokenStore(credentialStore: credentialStore)
            )
            let session = try authorizer.begin()
            pendingCodexOAuthSession = session
            codexOAuthProviderEnabled = true
            codexOAuthStatus = .waitingForCallback
            codexOAuthStatusMessage = nil
            codexOAuthLoginEmail = nil
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
            pendingCodexOAuthSession = nil
            codexOAuthCallbackURL = ""
            stopCodexOAuthCallbackServer()
            codexOAuthProviderEnabled = true
            codexOAuthStatus = .connected
            codexOAuthLoginEmail = token.loginEmail
            await refresh(reason: .manual)
        } catch {
            stopCodexOAuthCallbackServer()
            codexOAuthStatus = .failed
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
            codexOAuthLoginEmail = nil
        }
    }

    func disconnectCodexOAuth() async {
        do {
            let authorizer = CodexOAuthAuthorizer(
                client: codexOAuthClient,
                tokenStore: CodexOAuthTokenStore(credentialStore: credentialStore)
            )
            try await authorizer.disconnect()
            pendingCodexOAuthSession = nil
            codexOAuthCallbackURL = ""
            stopCodexOAuthCallbackServer()
            codexOAuthStatus = .notConnected
            codexOAuthStatusMessage = nil
            codexOAuthLoginEmail = nil
            codexOAuthProviderEnabled = false
        } catch {
            codexOAuthStatus = .failed
            codexOAuthStatusMessage = codexOAuthMessage(for: error)
        }
    }

    private func startCodexOAuthCallbackServer() {
        stopCodexOAuthCallbackServer()

        let server = OAuthLoopbackCallbackServer()
        do {
            try server.start(
                onCallback: { [weak self] callbackURL in
                    Task { @MainActor in
                        await self?.completeCodexOAuthConnection(callbackURL: callbackURL)
                    }
                },
                onFailure: { [weak self] _ in
                    Task { @MainActor in
                        guard self?.codexOAuthStatus == .waitingForCallback else { return }
                        self?.codexOAuthStatusMessage = self?.localization.text("oauth.callback.manualFallback")
                    }
                }
            )
            oauthCallbackServer = server
            codexOAuthStatusMessage = localization.text("oauth.callback.listening")
        } catch {
            codexOAuthStatusMessage = localization.text("oauth.callback.manualFallback")
        }
    }

    private func stopCodexOAuthCallbackServer() {
        oauthCallbackServer?.stop()
        oauthCallbackServer = nil
    }

    private func codexOAuthMessage(for error: Error) -> String {
        guard let oauthError = error as? CodexOAuthError else {
            return localization.text("oauth.error.authorizationFailed")
        }

        switch oauthError {
        case .stateMismatch:
            return localization.text("oauth.error.stateMismatch")
        case .missingAuthorizationCode, .invalidCallbackURL:
            return localization.text("oauth.error.invalidCallback")
        case .callbackFailed:
            return localization.text("oauth.error.callbackFailed")
        case .tokenRequestFailed:
            return localization.text("oauth.error.tokenExchangeFailed")
        case .unsafeOAuthEndpoint:
            return localization.text("oauth.error.unsafeEndpoint")
        case .pkceGenerationFailed, .stateGenerationFailed, .invalidAuthorizationURL, .invalidStoredToken:
            return localization.text("oauth.error.authorizationFailed")
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

        snapshots = await activeStore.snapshots
        lastRefreshAt = Date()
    }

    private func rebuildStoreIfConfigurationChanged(oldValue: Bool, newValue: Bool) {
        guard oldValue != newValue else { return }

        store = QuotaStore(
            registry: ProviderRegistry(
                configurations: providerConfigurations,
                credentialStore: credentialStore
            )
        )
        storeGeneration += 1
        snapshots = []
        lastRefreshAt = nil
    }
}

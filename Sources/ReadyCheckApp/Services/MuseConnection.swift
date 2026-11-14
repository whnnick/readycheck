import AppKit
import Observation
import OSLog
import ReadyCheckCore
import SwiftUI
import WebKit

@MainActor
protocol MuseUsageReading: AnyObject {
    func read() async throws -> MuseUsageSnapshot
    func clearSession() async
}

@MainActor @Observable
final class MuseConnection {
    private let reader: any MuseUsageReading
    private let defaults: UserDefaults
    private let enabledKey = "ReadyCheck.muse.enabled.v1"
    private var generation = 0
    @ObservationIgnored private var monitoring: Task<Void, Never>?
    private(set) var isEnabled: Bool
    private(set) var isBusy = false
    private(set) var snapshot: MuseUsageSnapshot?
    private(set) var observedAt: Date?
    private(set) var error: MuseUsageError?

    init(reader: (any MuseUsageReading)? = nil, defaults: UserDefaults = .standard) {
        self.reader = reader ?? MuseWebSession()
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: enabledKey)
    }

    var isConnected: Bool { isEnabled && snapshot != nil && error != .loginRequired }
    func remainingRatio(now: Date) -> Double? {
        guard error == nil, let snapshot, let observedAt, snapshot.isCurrent(observedAt: observedAt, now: now) else { return nil }
        return snapshot.remainingRatio
    }

    func connect(language: AppLanguage) {
        guard !isBusy else { return }
        generation += 1
        monitoring?.cancel(); monitoring = nil
        isEnabled = true
        defaults.set(true, forKey: enabledKey)
        snapshot = nil; observedAt = nil; error = nil
        if let web = reader as? MuseWebSession {
            web.showLogin(language: language) { [weak self] in
                guard let self else { return false }
                await self.refresh()
                return self.error == nil && self.snapshot != nil
            }
        }
        startMonitoring()
    }

    func refresh() async {
        guard isEnabled, !isBusy else { return }
        let request = generation
        isBusy = true
        defer { if request == generation { isBusy = false } }
        do {
            let result = try await reader.read()
            guard request == generation, isEnabled else { return }
            snapshot = result; observedAt = Date(); error = nil
        } catch {
            guard request == generation, isEnabled else { return }
            self.error = (error as? MuseUsageError) ?? .network
            if self.error == .loginRequired { snapshot = nil; observedAt = nil }
        }
    }

    func disconnect() async {
        generation += 1
        isEnabled = false; isBusy = true; snapshot = nil; observedAt = nil; error = nil
        defaults.set(false, forKey: enabledKey)
        monitoring?.cancel(); monitoring = nil
        await reader.clearSession()
        isBusy = false
    }

    func startMonitoring() {
        guard isEnabled, monitoring == nil else { return }
        monitoring = Task { [weak self] in
            await self?.refresh()
            if !Task.isCancelled, self?.snapshot == nil,
               self?.error == .network || self?.error == .timedOut {
                await self?.refresh()
            }
            while !Task.isCancelled {
                guard self != nil else { return }
                do { try await Task.sleep(for: .seconds(300)) } catch { return }
                await self?.refresh()
            }
        }
    }
}

@MainActor
final class MuseWebSession: NSObject, MuseUsageReading, WKNavigationDelegate, WKUIDelegate {
    private static let logger = Logger(subsystem: "com.readycheck.app", category: "Muse")
    private static let origin = URL(string: "https://muse.ai/")!
    private let dataStore: WKWebsiteDataStore
    private(set) lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = dataStore
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self; view.uiDelegate = self
        return view
    }()
    private var window: NSWindow?
    private var actionID = ""
    private var navigation: CheckedContinuation<Void, Error>?
    private var navigationDeadline: Task<Void, Never>?

    init(dataStore: WKWebsiteDataStore? = nil) {
        self.dataStore = dataStore ?? WKWebsiteDataStore(forIdentifier: UUID(uuidString: "690CBDA8-BB0F-4B58-B690-417E061601D8")!)
        super.init()
    }

    func read() async throws -> MuseUsageSnapshot {
        if webView.url?.host != "muse.ai" || webView.isLoading {
            if window?.isVisible == true { throw MuseUsageError.loginRequired }
            try await loadHome()
        }
        guard let url = Bundle.module.url(forResource: "MuseSubscription", withExtension: "js"),
              let script = try? String(contentsOf: url, encoding: .utf8) else { throw MuseUsageError.responseChanged }
        let cachedActionID = actionID
        actionID = ""
        let value: Any?
        do { value = try await Self.runReaderScript(script, actionID: cachedActionID, in: webView) }
        catch { throw MuseUsageError.network }
        guard let text = value as? String, let data = text.data(using: .utf8), data.count <= 524_288,
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            Self.logger.error("Muse usage read failed at envelope")
            throw MuseUsageError.responseChanged
        }
        if let error = envelope.error {
            // Fixed categories only: never log page text, account fields or server payloads.
            let stage = ReadStage(rawValue: envelope.stage ?? "") ?? .unknown
            Self.logger.error("Muse usage read failed at \(stage.rawValue, privacy: .public)")
            switch error {
            case "loginRequired": throw MuseUsageError.loginRequired
            case "timedOut": throw MuseUsageError.timedOut
            case "network": throw MuseUsageError.network
            default: throw MuseUsageError.responseChanged
            }
        }
        guard let flight = envelope.flight else {
            Self.logger.error("Muse usage read failed at missingSubscription")
            throw MuseUsageError.responseChanged
        }
        let result: MuseUsageSnapshot
        do { result = try MuseUsageParser.parse(Data(flight.utf8)) }
        catch {
            Self.logger.error("Muse usage read failed at decode")
            throw error
        }
        actionID = envelope.actionID ?? ""
        return result
    }

    static func runReaderScript(_ script: String, actionID: String, in webView: WKWebView) async throws -> Any? {
        return try await webView.callAsyncJavaScript(script, arguments: ["cachedActionID": actionID], in: nil, contentWorld: .page)
    }

    func clearSession() async {
        navigationDeadline?.cancel()
        navigation?.resume(throwing: MuseUsageError.loginRequired); navigation = nil
        webView.stopLoading(); window?.close(); window = nil; actionID = ""
        await dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
        webView.loadHTMLString("", baseURL: nil)
    }

    func showLogin(language: AppLanguage, readUsage: @escaping @MainActor () async -> Bool) {
        if let window { reloadLogin(); window.makeKeyAndOrderFront(nil); return }
        let panel = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 900, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        panel.title = "ReadyCheck · Muse"
        panel.isReleasedWhenClosed = false
        panel.contentViewController = NSHostingController(rootView: MuseLoginView(webView: webView, language: language, reload: { [weak self] in self?.reloadLogin() }) { [weak self] in
            if await readUsage() { self?.window?.close(); self?.window = nil; return true }
            return false
        })
        panel.center(); panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        window = panel
        reloadLogin()
    }

    private func reloadLogin() {
        webView.load(URLRequest(url: Self.origin, cachePolicy: .reloadIgnoringLocalCacheData))
    }

    private func loadHome() async throws {
        guard navigation == nil else { throw MuseUsageError.network }
        try await withCheckedThrowingContinuation { continuation in
            navigation = continuation
            navigationDeadline = Task { [weak self] in
                try? await Task.sleep(for: .seconds(20))
                guard !Task.isCancelled else { return }
                self?.finishNavigation(MuseUsageError.timedOut)
            }
            webView.load(URLRequest(url: Self.origin))
        }
    }

    private func finishNavigation(_ error: Error? = nil) {
        navigationDeadline?.cancel(); navigationDeadline = nil
        let pending = navigation; navigation = nil
        if let error { pending?.resume(throwing: error) } else { pending?.resume() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishNavigation(webView.url?.host == "muse.ai" ? nil : MuseUsageError.loginRequired)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finishNavigation(MuseUsageError.network) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finishNavigation(MuseUsageError.network) }

    static func allowsNavigation(_ url: URL) -> Bool {
        guard url.scheme == "https", let host = url.host?.lowercased() else { return false }
        return ["muse.ai", "meta.com", "facebook.com", "instagram.com"].contains { host == $0 || host.hasSuffix("." + $0) }
            || ["accounts.google.com", "appleid.apple.com"].contains(host)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.request.url.map(Self.allowsNavigation) == true ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, Self.allowsNavigation(url) { webView.load(URLRequest(url: url)) }
        return nil
    }
    private enum ReadStage: String { case home, discovery, subscription, response, unknown }
    private struct Envelope: Decodable { let error: String?; let stage: String?; let actionID: String?; let flight: String? }
}

private struct MuseLoginView: View {
    let webView: WKWebView
    let language: AppLanguage
    let reload: @MainActor () -> Void
    let readUsage: @MainActor () async -> Bool
    @State private var busy = false
    @State private var failed = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language == .zhCN ? "登录 Muse 后读取周额度" : "Sign in to Muse to read weekly usage").font(.headline)
                    Text(language == .zhCN ? "独立登录会话，仅查询用量；无需发送密码或 Cookie。" : "Separate sign-in session, usage reads only. Never send passwords or cookies.").font(.caption).foregroundStyle(.secondary)
                    if failed { Text(language == .zhCN ? "尚未读到额度，可重试读取或重新加载页面。" : "Usage unavailable. Retry the read or reload the page.").font(.caption).foregroundStyle(.orange) }
                }
                Spacer()
                Button(language == .zhCN ? "重新加载页面" : "Reload page") { failed = false; reload() }.disabled(busy)
                Button(language == .zhCN ? "完成并读取额度" : "Read usage and finish") {
                    busy = true
                    Task { failed = !(await readUsage()); busy = false }
                }.disabled(busy)
                if busy { ProgressView().controlSize(.small) }
            }.padding(16)
            Divider()
            MuseWebView(webView: webView)
        }.frame(minWidth: 740, minHeight: 600)
    }
}
private struct MuseWebView: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

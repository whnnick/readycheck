import AppKit
import SwiftUI
import XCTest
import WebKit
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class MuseConnectionTests: XCTestCase {
    func testWebKitReaderWaitsForThePromiseAndReturnsItsValue() async throws {
        let session = MuseWebSession(dataStore: .nonPersistent())
        session.webView.loadHTMLString("<html><body>Local reader fixture</body></html>", baseURL: nil)
        let deadline = Date().addingTimeInterval(10)
        while session.webView.isLoading && Date() < deadline { try await Task.sleep(for: .milliseconds(20)) }
        XCTAssertFalse(session.webView.isLoading)
        let value = try await MuseWebSession.runReaderScript(
            "await new Promise(resolve => setTimeout(resolve, 20)); return JSON.stringify({action: cachedActionID});",
            actionID: "fixture", in: session.webView)
        XCTAssertEqual(value as? String, #"{"action":"fixture"}"#)
        do {
            _ = try await MuseWebSession.runReaderScript("throw Error('Local fixture rejection');", actionID: "", in: session.webView)
            XCTFail("Rejected JavaScript must propagate its failure")
        } catch { }
    }

    func testDisabledConnectionDoesNotReadOrStartNetworkWork() async throws {
        try await withConnection(enabled: false) { connection, reader, _ in
            await connection.refresh()
            connection.startMonitoring()
            await Task.yield()
            XCTAssertEqual(reader.reads, 0)
            XCTAssertNil(connection.snapshot)
            XCTAssertFalse(connection.isConnected)
        }
    }

    func testFailureNeverPublishesAnOldReadingAsFreshAndSuccessfulRetryRecovers() async throws {
        try await withConnection { connection, reader, _ in
            await connection.refresh()
            XCTAssertEqual(connection.remainingRatio(now: Date())!, 0.73, accuracy: 0.0001)
            let observed = connection.observedAt
            reader.failure = .network
            await connection.refresh()
            XCTAssertNotNil(connection.snapshot)
            XCTAssertEqual(connection.observedAt, observed)
            XCTAssertNil(connection.remainingRatio(now: Date()))
            reader.failure = nil
            await connection.refresh()
            XCTAssertNotNil(connection.remainingRatio(now: Date()))
            reader.failure = .loginRequired
            await connection.refresh()
            XCTAssertNil(connection.snapshot)
            XCTAssertNil(connection.observedAt)
        }
    }

    func testDisconnectRejectsAnInFlightReadingAndClearsOnlyItsOwnSession() async throws {
        try await withConnection { connection, reader, defaults in
            reader.hold = true
            let task = Task { await connection.refresh() }
            for _ in 0..<30 { if reader.pending != nil { break }; await Task.yield() }
            XCTAssertTrue(connection.isBusy)
            await connection.disconnect()
            reader.pending?.resume(returning: try Self.snapshot()); reader.pending = nil
            await task.value
            XCTAssertNil(connection.snapshot)
            XCTAssertFalse(connection.isEnabled)
            XCTAssertFalse(connection.isBusy)
            XCTAssertEqual(reader.clears, 1)
            XCTAssertFalse(defaults.bool(forKey: "ReadyCheck.muse.enabled.v1"))
            XCTAssertEqual(defaults.string(forKey: "unrelated-provider"), "retained")
        }
    }

    func testThirdServiceSelectionAndSettingsReturnPreserveExistingLayouts() async throws {
        try await withConnection { connection, _, _ in
            let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(), museConnection: connection, quotaNotificationService: QuotaNotificationService(client: ClaritySilentNotifications(), verificationDelays: []))
            let original = model.selectedService
            defer { model.selectedService = original }
            model.selectedDeepSeek = false
            XCTAssertEqual(model.selectedService, .codex)
            XCTAssertEqual(model.bubbleRestingSize, CGSize(width: 92, height: 92))
            model.selectedDeepSeek = true
            XCTAssertEqual(model.bubbleRestingSize, CGSize(width: 180, height: 48))
            model.selectedService = .muse
            XCTAssertFalse(model.selectedDeepSeek)
            XCTAssertEqual(model.bubbleRestingSize, CGSize(width: 180, height: 48))
            model.openServiceSettings(.codex, section: .connection)
            model.closeServiceSettings()
            XCTAssertEqual(model.selectedService, .muse)
            model.selectedDeepSeek = false
            XCTAssertEqual(model.selectedService, .codex)
        }
    }

    func testLoginNavigationRejectsNonHTTPSAndUnrelatedHosts() {
        for url in ["https://muse.ai/", "https://auth.muse.ai/login", "https://auth.meta.com/", "https://accounts.google.com/"] {
            XCTAssertTrue(MuseWebSession.allowsNavigation(URL(string: url)!))
        }
        for url in ["http://muse.ai/", "https://muse.ai.evil.example/", "https://evil.example/", "file:///tmp/login.html"] {
            XCTAssertFalse(MuseWebSession.allowsNavigation(URL(string: url)!))
        }
    }

    func testMuseNativeSurfacesAndSettingsRenderWithoutCodexCardActions() async throws {
        _ = NSApplication.shared
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let image = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = image }
        defer { NSApp.applicationIconImage = oldIcon }
        try await withConnection { connection, _, _ in
            await connection.refresh()
            let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(), museConnection: connection, quotaNotificationService: QuotaNotificationService(client: ClaritySilentNotifications(), verificationDelays: []))
            let originalService = model.selectedService, originalLanguage = model.language
            defer { model.selectedService = originalService; model.language = originalLanguage }
            model.selectedService = .muse
            for language in [AppLanguage.zhCN, .enUS] {
                model.language = language
                let surfaces: [(String, AnyView, CGSize)] = [
                    ("capsule", AnyView(BubbleWidgetView(model: model, isExpanded: false, tabEdge: nil, onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})), .init(width: 180, height: 48)),
                    ("expanded", AnyView(BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil, onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})), .init(width: 380, height: 344)),
                    ("notch", AnyView(NotchStatusView(model: model)), .init(width: 185, height: 60)),
                    ("notch-details", AnyView(NotchDetailsView(model: model, now: Date())), .init(width: 360, height: 264)),
                    ("card", AnyView(FloatingWidgetView(model: model)), .init(width: 352, height: 440)),
                    ("menu", AnyView(MenuBarQuotaView(model: model, openSettings: {})), .init(width: 340, height: 470))]
                for (name, view, size) in surfaces { try capture(view, name: "\(name)-\(language.rawValue)", size: size) }
                for page in [MainWindowPage.overview, .usage, .settings] {
                    model.mainWindowPage = page
                    model.serviceSettingsTarget = .muse; model.mainSettingsSection = .connection
                    try capture(AnyView(SettingsView(model: model)), name: "\(page.rawValue)-\(language.rawValue)", size: .init(width: 900, height: 800))
                }
            }
        }
    }

    private func capture(_ view: AnyView, name: String, size: CGSize) throws {
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        defer { window.close() }
        let host = NSHostingView(rootView: view.environment(\.colorScheme, .dark)
            .background(Color(red: 0.10, green: 0.12, blue: 0.15)))
        window.contentView = host
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        XCTAssertLessThanOrEqual(host.fittingSize.width, size.width + 1, name)
        guard let output = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else { return }
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            .write(to: URL(fileURLWithPath: output).appendingPathComponent("muse-\(name).png"))
    }

    private func withConnection(enabled: Bool = true, body: @MainActor (MuseConnection, MuseTestReader, UserDefaults) async throws -> Void) async throws {
        let suite = "muse-fixture-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(enabled, forKey: "ReadyCheck.muse.enabled.v1")
        defaults.set("retained", forKey: "unrelated-provider")
        let reader = MuseTestReader()
        try await body(MuseConnection(reader: reader, defaults: defaults), reader, defaults)
    }

    static func snapshot() throws -> MuseUsageSnapshot {
        try MuseUsageParser.parse(Data(#"1:{"success":true,"subscription":{"tier":{"name":"Power"},"usage":{"percentUsed":27,"resetsAt":2000000000},"usageRowValueLabel":"27% used (400M tokens left)","topupRowValueLabel":"1M tokens left"}}"#.utf8))
    }
}

@MainActor
private final class MuseTestReader: MuseUsageReading {
    var failure: MuseUsageError?
    var reads = 0
    var clears = 0
    var hold = false
    var pending: CheckedContinuation<MuseUsageSnapshot, Error>?
    func read() async throws -> MuseUsageSnapshot {
        reads += 1
        if hold { return try await withCheckedThrowingContinuation { pending = $0 } }
        if let failure { throw failure }
        return try MuseConnectionTests.snapshot()
    }
    func clearSession() async { clears += 1 }
}

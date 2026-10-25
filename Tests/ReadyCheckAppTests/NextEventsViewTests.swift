import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class NextEventsViewTests: XCTestCase {
    func testRulesNavigationClosesCardDetailWithoutChangingConsent() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: NextFixtureReader(now: Date()),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: NextSilentNotifications(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json")))
        model.resetCreditStatus = .init(enabled: true, status: .waiting, updatedAt: nil)
        model.mainWindowPage = .usage
        model.mainSettingsSection = .connection
        model.resetCreditDetailSelection = .record("synthetic-card")
        let event = ReadyCheckNextEvent(kind: .automationOff, date: nil, expiration: nil, action: .rules)
        model.openNextEvent(event)
        XCTAssertNil(model.resetCreditDetailSelection, "Rules must not stay hidden behind card details")
        XCTAssertEqual(model.mainWindowPage, .settings)
        XCTAssertEqual(model.mainSettingsSection, .reminders)
        XCTAssertTrue(model.resetCreditStatus.enabled, "Navigation must not change authorization")
        let firstRequest = try XCTUnwrap(model.resetCreditRulesNavigationRequest)
        model.openResetCreditRules()
        XCTAssertNotEqual(model.resetCreditRulesNavigationRequest, firstRequest, "Repeated clicks on the same page must navigate again")
    }

    func testRulesNavigationScrollsToCardControlsOnSameAndDifferentPages() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: NextFixtureReader(now: Date()),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: NextSilentNotifications(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json")))
        let originalLanguage = model.language
        defer { model.language = originalLanguage }
        let size = CGSize(width: 740, height: 620)
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let host = NSHostingView(rootView: SettingsView(model: model))
        window.contentView = host; host.frame = CGRect(origin: .zero, size: size)
        func scrollViews(_ view: NSView) -> [NSScrollView] {
            (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap(scrollViews)
        }
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for page in [MainWindowPage.overview, .notifications, .settings] {
                model.mainWindowPage = page; model.mainSettingsSection = .reminders
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(150))
                let scroll = try XCTUnwrap(scrollViews(host).first)
                scroll.contentView.scroll(to: .zero)
                scroll.reflectScrolledClipView(scroll.contentView)
                model.openResetCreditRules()
                try await Task.sleep(for: .milliseconds(300))
                let destinationScroll = try XCTUnwrap(scrollViews(host).first)
                XCTAssertGreaterThan(destinationScroll.contentView.bounds.minY, 50, "Current card controls must be reached instead of the reminder-page header")
                XCTAssertNil(model.resetCreditRulesNavigationRequest, "Navigation request must be consumed after scrolling")
            }
        }
        model.reminderHistoryRecords = (0..<40).map { index in
            QuotaReminderHistoryRecord(id: "synthetic-scroll-\(index)", kind: .quotaRecovered,
                status: .automaticallyWithdrawn, lastAttemptAt: Date().addingTimeInterval(Double(-index * 60)))
        }
        model.mainWindowPage = .notifications
        try await Task.sleep(for: .milliseconds(150))
        let historyScroll = try XCTUnwrap(scrollViews(host).first)
        historyScroll.contentView.scroll(to: NSPoint(x: 0, y: 200))
        historyScroll.reflectScrolledClipView(historyScroll.contentView)
        XCTAssertGreaterThan(historyScroll.contentView.bounds.minY, 50)
        model.mainWindowPage = .settings
        try await Task.sleep(for: .milliseconds(150))
        model.mainWindowPage = .notifications
        try await Task.sleep(for: .milliseconds(150))
        let returnedScroll = try XCTUnwrap(scrollViews(host).first)
        XCTAssertEqual(returnedScroll.contentView.bounds.minY, 0, accuracy: 1, "Re-entering history must show its heading and refresh control")
    }

    func testNativeScenariosKeepSharedRoutingAndBilingualSurfaces() async throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let ownedKeys = ["ReadyCheck.codexConnectionMode.v1", "ReadyCheck.language.v1", "ReadyCheck.quotaWindowLabel.v1", "ReadyCheck.quotaWindowSelection.v2", "ReadyCheck.notchQuotaSelection.v1"]
        let saved = ownedKeys.map { defaults.object(forKey: $0) }
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let icon = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = icon }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defaults.set("localCodex", forKey: "ReadyCheck.codexConnectionMode.v1")
        defer {
            NSApp.applicationIconImage = oldIcon
            for (index, key) in ownedKeys.enumerated() {
                if let value = saved[index] { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
            try? FileManager.default.removeItem(at: directory)
        }
        let now = Date()
        let automation = ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json"))
        let model = ReadyCheckAppModel(credentialStore: OAuthTestCredentials(account: "synthetic-account"), codexQuotaClient: CodexQuotaHTTPClient(loader: OAuthTestHTTP()),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: NextFixtureReader(now: now), rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: NextSilentNotifications(), verificationDelays: []), resetCreditAutomation: automation)
        await model.reloadCodexOAuthConnectionStatus()
        model.lastRefreshAt = now; model.lastSuccessfulRefreshAt = now
        model.lowQuotaThreshold = 10
        let fixtureHistory = (0...12).compactMap { index in
            QuotaHistorySample(snapshot: fixtureSnapshot(now: now,
                sampledAt: now.addingTimeInterval(Double(index - 12) * 300), remaining: 34 + Double(12 - index) * 2))
        }
        model.quotaHistorySamples = fixtureHistory
        model.notchQuotaSelection = .sevenDay
        let historyRecord = ResetCreditExecutionRecord(id: "synthetic-request", expiresAt: now.addingTimeInterval(-60), status: .reset, updatedAt: now.addingTimeInterval(-120), successNotificationPending: true)
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for scenario in ["normal", "off", "authorized", "unknown", "notificationPending", "ledgerUnavailable", "cardCheckUnavailable"] {
                let distant = scenario == "normal"
                model.quotaHistorySamples = fixtureHistory
                model.snapshots = [fixtureSnapshot(now: now, cached: scenario == "unknown", distant: distant)]
                model.resetCreditStatus = .init(enabled: scenario != "off" && scenario != "ledgerUnavailable", status: scenario == "ledgerUnavailable" ? .storageFailed : scenario == "cardCheckUnavailable" ? .unavailable : scenario == "off" ? .off : .waiting, updatedAt: nil)
                model.resetCreditRecords = scenario == "notificationPending" ? [historyRecord] : []
                let events = model.nextEvents(now: now)
                XCTAssertLessThanOrEqual(events.count, 2)
                let expected: ReadyCheckNextEvent.Kind = switch scenario {
                case "normal": .naturalReset
                case "off": .automationOff
                case "unknown": .conditionsUnknown
                case "ledgerUnavailable": .cardHistoryUnavailable
                case "cardCheckUnavailable": .cardCheckUnavailable
                case "notificationPending": .notificationPending
                default: .cardWindow
                }
                XCTAssertEqual(events.first?.kind, expected)
                if let first = events.first {
                    let enabledBefore = model.resetCreditStatus.enabled
                    model.openNextEvent(first)
                    XCTAssertEqual(model.resetCreditStatus.enabled, enabledBefore, "Navigation cannot change consent")
                    if case .card(let date) = first.action { XCTAssertEqual(model.resetCreditDetailSelection, .available(date)) }
                    if case .record(let id) = first.action { XCTAssertEqual(model.resetCreditDetailSelection, .record(id)) }
                }
                model.resetCreditDetailSelection = nil
                model.mainWindowPage = .overview
                let suffix = "\(scenario)-\(language.rawValue)"
                try await render(SettingsView(model: model), model: model, name: "next-main-\(suffix)", size: CGSize(width: 900, height: 980))
                let fixtureStatus = model.resetCreditStatus
                let fixtureRecords = model.resetCreditRecords
                try await render(MenuBarQuotaView(model: model, openSettings: {}), name: "next-menu-\(suffix)", size: CGSize(width: 340, height: 550))
                // Menu opening reloads its mock account. Restore presentation fixtures for the next surface.
                model.quotaHistorySamples = fixtureHistory
                model.snapshots = [fixtureSnapshot(now: now, cached: scenario == "unknown", distant: distant)]
                model.resetCreditStatus = fixtureStatus
                model.resetCreditRecords = fixtureRecords
                try await render(BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil,
                    onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {}), name: "next-widget-\(suffix)", size: BubbleWidgetPlacement.expandedSize, checkQuotaFit: true)
                if scenario == "notificationPending" {
                    try await render(ResetCreditDetailView(model: model, selection: .record(historyRecord.id), now: now), name: "next-detail-\(suffix)", size: CGSize(width: 540, height: 400))
                }
                if scenario == "ledgerUnavailable" {
                    let expiry = try XCTUnwrap(model.snapshots.first?.details?.manualResetExpirations.first)
                    try await render(ResetCreditDetailView(model: model, selection: .available(expiry), now: now), name: "next-detail-\(suffix)", size: CGSize(width: 540, height: 400))
                    model.mainWindowPage = .settings; model.mainSettingsSection = .reminders
                    try await render(SettingsView(model: model), model: model, name: "next-settings-\(suffix)", size: CGSize(width: 740, height: 900))
                }
            }
            model.snapshots = [fixtureSnapshot(now: now, distant: true)]
            model.resetCreditRecords = []
            model.resetCreditStatus = .init(enabled: true, status: .waiting, updatedAt: nil)
            let originalSamples = model.quotaHistorySamples
            model.quotaHistorySamples = (0...12).compactMap { index in
                let remaining = index <= 6 ? 64.0 : 64.0 - Double(index - 6) * 5
                return QuotaHistorySample(snapshot: fixtureSnapshot(now: now,
                    sampledAt: now.addingTimeInterval(Double(index - 12) * 300), remaining: remaining))
            }
            XCTAssertEqual(model.quotaPace(now: now)?.state, .unstable)
            try await render(NextEventsView(model: model, now: now).padding(16), name: "next-paused-\(language.rawValue)", size: CGSize(width: 680, height: 210))
            model.quotaHistorySamples = originalSamples
            model.snapshots = [fixtureSnapshot(now: now)]
            model.mainWindowPage = .overview
            try await render(SettingsView(model: model), model: model, name: "next-minimum-\(language.rawValue)", size: CGSize(width: 740, height: 760))
            for scheme in [ColorScheme.dark, .light] {
                let appearanceName = scheme == .dark ? "dark" : "light"
                model.mainWindowPage = .overview
                try await render(SettingsView(model: model), model: model, name: "design-overview-\(appearanceName)-\(language.rawValue)", size: CGSize(width: 740, height: 620), scheme: scheme)
                model.mainWindowPage = .usage
                try await render(SettingsView(model: model), model: model, name: "design-token-\(appearanceName)-\(language.rawValue)", size: CGSize(width: 740, height: 620), scheme: scheme)
                model.mainWindowPage = .settings
                for section in MainSettingsSection.allCases {
                    model.mainSettingsSection = section
                    try await render(SettingsView(model: model), model: model, name: "design-\(section.rawValue)-\(appearanceName)-\(language.rawValue)", size: CGSize(width: 740, height: 620), scheme: scheme)
                }
            }

        }
    }
    func testAccountChangeClearsCardSelectionAndReadOnlyRecords() async throws {
        let defaults = UserDefaults.standard
        let oldMode = defaults.object(forKey: "ReadyCheck.codexConnectionMode.v1")
        defaults.set("localCodex", forKey: "ReadyCheck.codexConnectionMode.v1")
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            if let oldMode { defaults.set(oldMode, forKey: "ReadyCheck.codexConnectionMode.v1") }
            else { defaults.removeObject(forKey: "ReadyCheck.codexConnectionMode.v1") }
            try? FileManager.default.removeItem(at: folder)
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("cards.json")
        let now = Date()
        let bytes = try JSONSerialization.data(withJSONObject: ["attempts": [["accountKey": QuotaHistorySample.key(for: "synthetic-account")!, "creditID": "fixture", "expiresAt": now.timeIntervalSinceReferenceDate, "key": "original-request", "status": "reset", "updatedAt": now.timeIntervalSinceReferenceDate, "successNotificationPending": true]]])
        try bytes.write(to: file)
        let reader = NextSwitchingReader(now: now)
        let credentials = OAuthTestCredentials(account: "synthetic-account")
        let model = ReadyCheckAppModel(credentialStore: credentials, codexQuotaClient: CodexQuotaHTTPClient(loader: OAuthTestHTTP()), quotaHistoryStore: QuotaHistoryStore(fileURL: folder.appendingPathComponent("history.json")), quotaReminderStore: QuotaReminderStore(fileURL: folder.appendingPathComponent("reminders.json")), codexAppServerClient: reader, rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []), quotaNotificationService: QuotaNotificationService(client: NextSilentNotifications(), verificationDelays: []), resetCreditAutomation: ResetCreditAutomation(fileURL: file))
        await model.reloadCodexOAuthConnectionStatus()
        XCTAssertEqual(model.currentResetCreditRecords.count, 1)
        model.resetCreditDetailSelection = .record("original-request")
        await reader.switchAccount()
        await credentials.useAccount("other-account")
        await model.reloadCodexOAuthConnectionStatus()
        XCTAssertTrue(model.currentResetCreditRecords.isEmpty)
        XCTAssertNil(model.resetCreditDetailSelection)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    private func fixtureSnapshot(now: Date, cached: Bool = false, distant: Bool = false, sampledAt: Date? = nil, remaining: Double = 34) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available, source: .appServer,
            refreshedAt: sampledAt ?? now, staleAfter: now.addingTimeInterval(300), windows: [
                QuotaWindow(id: "short", labelKey: "quota.window.codex.5h", kind: .rolling, used: 100 - remaining, limit: 100, remaining: remaining, unit: .percent, resetAt: now.addingTimeInterval(7200), confidence: .verified, durationMinutes: 300),
                QuotaWindow(id: "week", labelKey: "quota.window.codex.7d", kind: .rolling, used: 30 - (remaining - 34) * 0.1, limit: 100, remaining: 70 + (remaining - 34) * 0.1, unit: .percent, resetAt: now.addingTimeInterval(172800), confidence: .verified, durationMinutes: 10080)],
            errors: [], details: ProviderQuotaDetails(planName: "Plus", subscriptionRenewalAt: now.addingTimeInterval(2678400), manualResetCount: 2,
                manualResetExpirations: [now.addingTimeInterval(distant ? 604800 : 9600), now.addingTimeInterval(1209600)], creditBalance: "120", manualResetDetailsReadAt: now), ordinaryUsageAllowed: true, accountID: "synthetic-account", isCached: cached)
    }
    private func render<V: View>(_ view: V, model: ReadyCheckAppModel? = nil, name: String, size: CGSize, checkQuotaFit: Bool = false, scheme: ColorScheme = .dark) async throws {
        // Keep declared fixture data stable while the native view settles; this is not a refresh test.
        model?.lastRefreshAt = Date()
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        defer { window.close() }
        let host = NSHostingView(rootView: view.frame(width: size.width).background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, scheme))
        window.contentView = host; host.frame = CGRect(origin: .zero, size: size); host.layoutSubtreeIfNeeded()
        window.orderBack(nil)
        try await Task.sleep(for: .milliseconds(700))
        if checkQuotaFit {
            func scrolls(_ view: NSView) -> [NSScrollView] { (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap(scrolls) }
            let scroll = try XCTUnwrap(scrolls(host).first)
            let document = try XCTUnwrap(scroll.documentView)
            XCTAssertLessThanOrEqual(document.frame.height, scroll.contentSize.height + 1, "Both quota rows must fit above the retained last-hour chart")
        }
        XCTAssertEqual(host.bounds.width, size.width, accuracy: 1)
        if let output = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
            try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds)); host.cacheDisplay(in: host.bounds, to: bitmap)
            try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: output).appendingPathComponent(name + ".png"))
        }
    }
}
private struct NextFixtureReader: CodexAppServerReading {
    let now: Date
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        CodexAppServerAccountSnapshot(accountID: "synthetic-account", email: nil, planName: "Plus", rateLimits: [
            .init(limitID: "codex", limitName: nil, primary: .init(usedPercent: 66, durationMinutes: 300, resetsAt: now.addingTimeInterval(7200)), secondary: nil, creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: "Plus")], resetCredits: [], tokenUsage: nil)
    }
}
@MainActor private final class NextSilentNotifications: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration { .init(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none) }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

private actor NextSwitchingReader: CodexAppServerReading {
    let now: Date
    var account = "synthetic-account"
    init(now: Date) { self.now = now }
    func switchAccount() { account = "second-synthetic-account" }
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        let base = try await NextFixtureReader(now: now).readAccountSnapshot()
        return CodexAppServerAccountSnapshot(accountID: account, email: nil, planName: base.planName,
            rateLimits: base.rateLimits, resetCredits: [], tokenUsage: nil)
    }
}

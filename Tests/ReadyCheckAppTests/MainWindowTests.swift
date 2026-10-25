import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class MainWindowTests: XCTestCase {
    func testSubmittedExpiryReceiptRendersInBothLanguages() throws {
        _ = NSApplication.shared
        var record = QuotaReminderHistoryRecord(id: "synthetic-expiry", kind: .manualResetExpiring, status: .legacyUnknown,
            lastAttemptAt: Date(), expiresAt: Date().addingTimeInterval(172800), leadHours: 48, resetIndex: 1, attemptCount: 1)
        record.submissionAccepted = true
        for language in [AppLanguage.zhCN, .enUS] {
            try renderDesktop(ReminderHistoryPageView(records: [record], localization: LocalizationService(language: language)).padding(16),
                name: "expiry-submitted-\(language.rawValue)", size: CGSize(width: 520, height: 280))
        }
    }

    func testNotificationPageRefreshKeepsCompleteHistoryAndReminderRules() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("reminders.json")
        var state = QuotaReminderState(notificationHistory: notificationRecords(), notificationHistoryMigrationCompleted: true)
        state.lowQuotaThreshold = 20; state.automaticRecoveryEnabled = false
        state.resetExpiryReminderEnabled = true; state.resetExpiryLeadHours = [24, 48]
        try JSONEncoder().encode(state).write(to: url)
        let store = QuotaReminderStore(fileURL: url)
        let expected = await store.history()
        let before = try Data(contentsOf: url)
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: store,
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("ledger.json")))
        model.mainWindowPage = .notifications
        for _ in 0..<2 {
            await model.reloadReminderHistory()
            XCTAssertEqual(model.reminderHistoryRecords, expected)
            XCTAssertEqual(model.reminderHistoryRecords.count, 6, "The page must retain records beyond the old three-row summary")
            XCTAssertEqual(model.lowQuotaThreshold, 20)
            XCTAssertFalse(model.automaticRecoveryEnabled)
            XCTAssertTrue(model.resetExpiryReminderEnabled)
            XCTAssertEqual(Set(model.resetExpiryLeadHours), [24, 48])
        }
        XCTAssertEqual(try Data(contentsOf: url), before, "Viewing and refreshing records must not rewrite normalized history or rules")
        XCTAssertTrue(model.snapshots.isEmpty, "History refresh must not request quota data")
        XCTAssertTrue(model.resetCreditChecks.isEmpty)
    }

    func testNotificationPageEmptyAndDeliveryStatesRenderInBothLanguagesAndAppearances() throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let languageKey = "ReadyCheck.language.v1", saved = UserDefaults.standard.object(forKey: "ReadyCheck.language.v1")
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: languageKey) }
            else { UserDefaults.standard.removeObject(forKey: languageKey) }
        }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("ledger.json")))
        model.mainWindowPage = .notifications
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for dark in [false, true] {
                for populated in [false, true] {
                    model.reminderHistoryRecords = populated ? notificationRecords() : []
                    try render(model: model, name: "notifications-\(populated ? "records" : "empty")-\(language.rawValue)-\(dark ? "dark" : "light")", width: 740, dark: dark)
                }
            }
        }
    }

    private func notificationRecords() -> [QuotaReminderHistoryRecord] {
        let now = Date(timeIntervalSince1970: 1_792_929_600)
        let kinds: [QuotaReminderHistoryKind] = [.quotaLow, .manualResetExpiring, .quotaRecovered, .creditsStarted, .resetCreditUsed, .manualResetExpiring]
        let statuses: [QuotaReminderDeliveryStatus] = [.delivered, .failed, .automaticallyWithdrawn, .withdrawalPending, .legacyUnknown, .legacyUnknown]
        return kinds.indices.map { index in
            var record = QuotaReminderHistoryRecord(id: "synthetic-notice-\(index)", kind: kinds[index], status: statuses[index],
                lastAttemptAt: now.addingTimeInterval(Double(-index * 3600)), expiresAt: kinds[index] == .manualResetExpiring ? now.addingTimeInterval(86400) : nil,
                leadHours: kinds[index] == .manualResetExpiring ? 24 : nil, resetIndex: kinds[index] == .manualResetExpiring ? 1 : nil, attemptCount: index == 1 ? 2 : 1)
            if index == 0 { record.remainingPercent = 10; record.quotaLabelKey = "quota.window.codex.5h" }
            if index == 5 { record.submissionAccepted = true }
            return record
        }
    }

    func testAboutAndReleaseHighlightsRenderInBothLanguages() throws {
        _ = NSApplication.shared
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let icon = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = icon }
        defer { NSApp.applicationIconImage = oldIcon }
        for language in [AppLanguage.zhCN, .enUS] {
            let localization = LocalizationService(language: language)
            try renderDesktop(AboutView(localization: localization), name: "about-\(language.rawValue)", size: CGSize(width: 480, height: 640))
            try renderDesktop(ReleaseHighlightsView(localization: localization).padding(16),
                name: "release-highlights-\(language.rawValue)", size: CGSize(width: 500, height: 420))
        }
    }

    func testAboutWindowReusesVisibleWindowAndUpdatesLanguage() throws {
        _ = NSApplication.shared
        let controller = AboutWindowController()
        controller.show(localization: LocalizationService(language: .zhCN))
        let window = try XCTUnwrap(NSApp.windows.first { $0.title == "关于" })
        defer { window.close() }
        XCTAssertGreaterThanOrEqual(window.contentLayoutRect.height, 600)
        XCTAssertTrue(window.styleMask.contains(.resizable))
        controller.show(localization: LocalizationService(language: .enUS))
        XCTAssertEqual(window.title, "About")
        XCTAssertTrue(window.isVisible)
        XCTAssertEqual(NSApp.windows.filter { $0.title == "About" && $0.isVisible }.count, 1)
    }

    func testLanguageChangeNotifiesNativeMenuOnlyWhenSelectionChanges() {
        let key = "ReadyCheck.language.v1"
        let saved = UserDefaults.standard.object(forKey: key)
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []))
        let original = model.language
        var changes = 0
        model.onLanguageChanged = { changes += 1 }
        model.language = original
        XCTAssertEqual(changes, 0)
        model.language = original == .zhCN ? .enUS : .zhCN
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), model.language.rawValue)
        model.language = original
        XCTAssertEqual(changes, 2)
    }

    func testAccountBenefitsPreserveKnownZeroUnknownAndPartialDetails() throws {
        _ = NSApplication.shared
        let localization = LocalizationService(language: .enUS)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiry = now.addingTimeInterval(86400)
        let scenarios: [(String, ProviderQuotaDetails?)] = [
            ("complete", ProviderQuotaDetails(planName: "plus", subscriptionRenewalAt: expiry,
                manualResetCount: 3, manualResetExpirations: [expiry, expiry.addingTimeInterval(86400), expiry.addingTimeInterval(172800)], creditBalance: "1234.5")),
            ("partial", ProviderQuotaDetails(planName: "plus", manualResetCount: 2, manualResetExpirations: [expiry])),
            ("zero", ProviderQuotaDetails(manualResetCount: 0)),
            ("unknown", nil),
            ("historical", ProviderQuotaDetails(planName: "plus", subscriptionRenewalAt: now.addingTimeInterval(-86400))),
            ("unlimited", ProviderQuotaDetails(manualResetExpirations: [expiry], creditsUnlimited: true))
        ]
        let zero = QuotaCardView(snapshot: makeSnapshot(now: now, details: scenarios[2].1), localization: localization, now: now, displayMode: .accountDetails)
        XCTAssertEqual(zero.manualResetCount, 0)
        let unknown = QuotaCardView(snapshot: makeSnapshot(now: now), localization: localization, now: now, displayMode: .accountDetails)
        XCTAssertNil(unknown.manualResetCount)
        XCTAssertNil(unknown.creditBalanceText)
        XCTAssertEqual(unknown.displayPlanName, localization.text("quota.notProvided"))
        let partial = QuotaCardView(snapshot: makeSnapshot(now: now, details: scenarios[1].1), localization: localization, now: now, displayMode: .accountDetails)
        XCTAssertEqual(partial.manualResetCount, 2)
        XCTAssertTrue(partial.manualResetExpirationText(index: 1).contains(localization.text("quota.manualResetExpirationUnavailable")))
        XCTAssertFalse(partial.manualResetExpirationText(index: 0).contains(localization.text("quota.manualResetExpirationUnavailable")))
        let unlimited = QuotaCardView(snapshot: makeSnapshot(now: now, details: scenarios[5].1), localization: localization, now: now, displayMode: .accountDetails)
        XCTAssertEqual(unlimited.manualResetCount, 1)
        XCTAssertEqual(unlimited.creditBalanceText, localization.text("quota.creditsUnlimited"))
        for language in [AppLanguage.zhCN, .enUS] {
            let localization = LocalizationService(language: language)
            for (name, details) in scenarios {
                try renderDesktop(QuotaCardView(snapshot: makeSnapshot(now: now, details: details),
                    localization: localization, now: now, displayMode: .accountDetails),
                    name: "account-benefits-\(name)-\(language.rawValue)", size: CGSize(width: 500, height: 400))
            }
        }
    }

    func testSparseQuotaChartsAndTokenEmptyStateRenderAtMinimumWidth() throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let languageKey = "ReadyCheck.language.v1"
        let savedLanguage = UserDefaults.standard.object(forKey: languageKey)
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let icon = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = icon }
        defer {
            NSApp.applicationIconImage = oldIcon
            if let savedLanguage { UserDefaults.standard.set(savedLanguage, forKey: languageKey) }
            else { UserDefaults.standard.removeObject(forKey: languageKey) }
        }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []))
        let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970 / 3600) * 3600 + 1800)
        model.snapshots = [makeSnapshot(now: Date())]
        model.lastSuccessfulRefreshAt = Date()
        let dates: [(String, [Date])] = [
            ("two-hours", [-4500.0, -4200, -300, 0].map { now.addingTimeInterval($0) }),
            ("single-hour", [-600.0, 0].map { now.addingTimeInterval($0) }),
            ("dense", (0..<288).map { now.addingTimeInterval(Double($0 - 287) * 300) })
        ]
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            model.snapshots = [makeSnapshot(now: Date())]
            for (name, dates) in dates {
                let samples = dates.enumerated().map { index, date in
                    let ratio = name == "two-hours" ? [0.9, 0.59, 0.59, 0.52][index]
                        : name == "single-hour" ? [0.9, 0.7][index] : 0.9 - Double(index) * 0.002
                    return QuotaHistorySample(providerID: "codex-oauth", recordedAt: date, values: [
                        QuotaHistoryValue(windowID: "codex-primary", labelKey: "quota.window.codex.5h",
                            remainingRatio: ratio, resetAt: now.addingTimeInterval(7200)),
                        QuotaHistoryValue(windowID: "codex-secondary", labelKey: "quota.window.codex.7d",
                            remainingRatio: 0.8 - Double(index) * 0.001, resetAt: now.addingTimeInterval(172800))])
                }
                model.quotaHistorySamples = samples
                try renderDesktop(RecentUsageView(samples: samples, localization: model.localization, now: now)
                    .padding(16), name: "chart-\(name)-\(language.rawValue)", size: CGSize(width: 500, height: 620))
            }
            model.mainWindowPage = .overview
            try render(model: model, name: "chart-overview-\(language.rawValue)", width: 740)
            model.mainWindowPage = .usage
            try render(model: model, name: "tokens-unavailable-\(language.rawValue)", width: 740)
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            let tokens = AccountTokenUsage(summary: AccountTokenUsageSummary(lifetimeTokens: 1_234_567,
                peakDailyTokens: 250_000, currentStreakDays: 5), dailyBuckets: (0..<14).map { index in
                    AccountTokenUsageDailyBucket(startDate: formatter.string(from: Date().addingTimeInterval(Double(index - 13) * 86400)),
                        tokens: Int64(120_000 + index * 5_000))
                })
            model.snapshots = [makeSnapshot(now: Date(), tokenUsage: tokens)]
            try render(model: model, name: "tokens-official-\(language.rawValue)", width: 740)
        }
    }

    func testNativePagesRenderAtMinimumSizeWithSyntheticData() throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []))
        let keys = ["ReadyCheck.language.v1", "ReadyCheck.refreshInterval.v1"]
        let values = keys.map { UserDefaults.standard.object(forKey: $0) }
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let icon = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = icon }
        defer {
            NSApp.applicationIconImage = oldIcon
            for (key, value) in zip(keys, values) {
                if let value { UserDefaults.standard.set(value, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }
        let now = Date()
        model.snapshots = [makeSnapshot(now: now)]
        model.lastSuccessfulRefreshAt = now
        model.codexOAuthStatus = .connected
        model.lowQuotaThreshold = 5
        model.notificationReadiness = .ready
        model.quotaHistorySamples = (0..<288).map { index in
            QuotaHistorySample(providerID: "codex-oauth", recordedAt: now.addingTimeInterval(Double(index - 288) * 300),
                values: [QuotaHistoryValue(windowID: "codex-primary", labelKey: "quota.window.codex.5h",
                    remainingRatio: 1 - Double(index) * 0.0006, resetAt: now.addingTimeInterval(7200))])
        }
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for page in MainWindowPage.allCases {
                model.mainWindowPage = page
                try render(model: model, name: "\(page.rawValue)-\(language.rawValue)", width: 740)
            }
        }
        // Release screenshots are native views using invented account benefits and quota values.
        model.mainWindowPage = .overview
        model.snapshots = [makeSnapshot(now: now, details: ProviderQuotaDetails(planName: "plus",
            subscriptionRenewalAt: now.addingTimeInterval(30 * 86400), manualResetCount: 2,
            manualResetExpirations: [now.addingTimeInterval(7 * 86400), now.addingTimeInterval(14 * 86400)], creditBalance: "120"))]
        for (language, name) in [(AppLanguage.enUS, "release-overview-en"), (.zhCN, "release-overview-zh")] {
            model.language = language
            try render(model: model, name: name, width: 900, dark: true)
        }
        model.language = .zhCN
        model.mainWindowPage = .settings
        for section in MainSettingsSection.allCases {
            model.mainSettingsSection = section
            try render(model: model, name: "settings-\(section.rawValue)", width: 740)
        }
        model.mainWindowPage = .overview
        model.snapshots = [makeSnapshot(now: now.addingTimeInterval(-600), isCached: true)]
        try render(model: model, name: "overview-cached", width: 900)
        try render(model: model, name: "overview-dark", width: 900, dark: true)
        model.snapshots = []
        try render(model: model, name: "overview-empty", width: 740)
    }

    func testExpandedWidgetRetainsSelectedLastHourConsumptionWithoutFallback() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keys = ["ReadyCheck.quotaWindowSelection.v2", "ReadyCheck.notchQuotaSelection.v1", "ReadyCheck.quotaWindowLabel.v1"]
        let previous = keys.map { UserDefaults.standard.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, previous) {
                if let value { UserDefaults.standard.set(value, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []))
        let now = Date()
        model.snapshots = [makeSnapshot(now: now)]
        model.quotaHistorySamples = (0..<10).map { index in
            QuotaHistorySample(providerID: "codex-oauth", recordedAt: now.addingTimeInterval(-3000 + Double(index) * 240),
                values: [QuotaHistoryValue(windowID: "codex-primary", labelKey: "quota.window.codex.5h",
                    remainingRatio: 0.9 - Double(index) * 0.005, resetAt: now.addingTimeInterval(7200))])
        }
        let view = BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        model.notchQuotaSelection = .fiveHour
        XCTAssertEqual(view.lastHourValues.compactMap { $0 }.reduce(0, +), 0.045, accuracy: 0.00001)
        model.notchQuotaSelection = .sevenDay
        XCTAssertTrue(view.lastHourValues.allSatisfy { $0 == nil })
        model.notchQuotaSelection = .window("missing")
        XCTAssertTrue(view.lastHourValues.allSatisfy { $0 == nil })
    }

    func testMenuAndNotchRenderWithSyntheticVerifiedAccount() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keys = ["ReadyCheck.codexConnectionMode.v1", "ReadyCheck.language.v1"]
        let values = keys.map { UserDefaults.standard.object(forKey: $0) }
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let icon = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = icon }
        defer {
            NSApp.applicationIconImage = oldIcon
            for (key, value) in zip(keys, values) {
                if let value { UserDefaults.standard.set(value, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }
        UserDefaults.standard.set("localCodex", forKey: keys[0])
        let model = ReadyCheckAppModel(credentialStore: OAuthTestCredentials(account: "synthetic-dashboard"), codexQuotaClient: CodexQuotaHTTPClient(loader: OAuthTestHTTP()),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: DashboardAccountReader(),
            quotaNotificationService: QuotaNotificationService(client: DashboardNotificationClient(), verificationDelays: []))
        model.language = .zhCN
        await model.reloadCodexOAuthConnectionStatus()
        await model.refresh(reason: .manual)
        let now = Date()
        model.quotaHistorySamples = (0..<12).map { index in
            QuotaHistorySample(providerID: "codex-oauth", recordedAt: now.addingTimeInterval(Double(index - 11) * 300), values: [
                QuotaHistoryValue(windowID: "codex-primary", labelKey: "quota.window.codex.5h", remainingRatio: [0.98, 0.97, 0.95, 0.945, 0.94, 0.92, 0.9, 0.88, 0.86, 0.84, 0.82, 0.8][index], resetAt: now.addingTimeInterval(7200)),
                QuotaHistoryValue(windowID: "codex-secondary", labelKey: "quota.window.codex.7d", remainingRatio: [0.78, 0.775, 0.77, 0.76, 0.75, 0.745, 0.74, 0.73, 0.725, 0.72, 0.715, 0.7][index], resetAt: now.addingTimeInterval(172800))])
        }
        try renderDesktop(MenuBarQuotaView(model: model, openSettings: {}), name: "menu-bar", size: CGSize(width: 340, height: 470), maximumFittingHeight: 400)
        let healthy = model.snapshots
        model.snapshots = [makeSnapshot(now: now.addingTimeInterval(-600), isCached: true)]
        try renderDesktop(MenuBarQuotaView(model: model, openSettings: {}), name: "menu-bar-cached", size: CGSize(width: 340, height: 470), maximumFittingHeight: 420)
        model.snapshots = healthy
        try renderDesktop(NotchStatusView(model: model), name: "notch-collapsed", size: CGSize(width: 185, height: 42))
        try renderDesktop(NotchStatusView(model: model, isExpanded: true), name: "notch-expanded", size: CGSize(width: 360, height: 264))
        let widget = BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        try renderDesktop(widget, name: "widget-last-hour", size: BubbleWidgetPlacement.expandedSize)
        model.language = .enUS
        try renderDesktop(widget, name: "widget-last-hour-en", size: BubbleWidgetPlacement.expandedSize)
    }

    private func renderDesktop<Content: View>(_ content: Content, name: String, size: CGSize, maximumFittingHeight: CGFloat? = nil) throws {
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let host = NSHostingView(rootView: content.frame(width: size.width).background(Color(nsColor: .windowBackgroundColor)))
        window.contentView = host
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.7))
        if let maximumFittingHeight {
            XCTAssertLessThan(host.fittingSize.height, maximumFittingHeight)
            window.setContentSize(CGSize(width: size.width, height: host.fittingSize.height))
            host.layoutSubtreeIfNeeded()
        }
        XCTAssertEqual(host.bounds.width, size.width, accuracy: 1)
        XCTAssertLessThanOrEqual(host.bounds.height, size.height + 1)
        guard let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else { return }
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
    }

    private func render(model: ReadyCheckAppModel, name: String, width: CGFloat, dark: Bool = false) throws {
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: width, height: 760), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let host = NSHostingView(rootView: SettingsView(model: model).background(Color(nsColor: .windowBackgroundColor)))
        window.contentView = host
        host.frame = CGRect(x: 0, y: 0, width: width, height: 760)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.7))
        XCTAssertEqual(host.bounds.width, width, accuracy: 1)
        XCTAssertEqual(host.bounds.height, 760, accuracy: 1)
        guard let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else { return }
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
    }

    private func makeSnapshot(now: Date, isCached: Bool = false, tokenUsage: AccountTokenUsage? = nil, details: ProviderQuotaDetails? = nil) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: isCached ? .unavailable : .available,
            source: .appServer, refreshedAt: now, staleAfter: now.addingTimeInterval(300), windows: [
                QuotaWindow(id: "codex-primary", labelKey: "quota.window.codex.5h", kind: .rolling,
                    used: 20, limit: 100, remaining: 80, unit: .percent, resetAt: now.addingTimeInterval(7200), confidence: .verified, durationMinutes: 300),
                QuotaWindow(id: "codex-secondary", labelKey: "quota.window.codex.7d", kind: .rolling,
                    used: 30, limit: 100, remaining: 70, unit: .percent, resetAt: now.addingTimeInterval(172800), confidence: .verified, durationMinutes: 10080)
            ], errors: isCached ? ["quota.error.requestFailed"] : [],
            details: details ?? tokenUsage.map { ProviderQuotaDetails(accountTokenUsage: $0) }, ordinaryUsageAllowed: isCached ? nil : true,
            accountID: "synthetic-dashboard", isCached: isCached)
    }
}

@MainActor
private final class DashboardNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .authorized, alertSetting: .enabled, alertStyle: .banner)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

private struct DashboardAccountReader: CodexAppServerReading {
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        CodexAppServerAccountSnapshot(accountID: "synthetic-dashboard", email: nil, planName: nil,
            rateLimits: [CodexAppServerRateLimitSnapshot(limitID: "codex", limitName: nil,
                primary: CodexAppServerRateLimitWindow(usedPercent: 20, durationMinutes: 300, resetsAt: Date().addingTimeInterval(7200)),
                secondary: CodexAppServerRateLimitWindow(usedPercent: 30, durationMinutes: 10080, resetsAt: Date().addingTimeInterval(172800)),
                creditBalance: nil, hasCredits: false, creditsUnlimited: nil, planName: nil)], resetCredits: [], tokenUsage: nil, ordinaryUsageAllowed: true)
    }
}

import AppKit
import SwiftUI
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class QuotaPaceViewTests: XCTestCase {
    func testSharedPaceRetainsOffAndBilingualExistingSurfaceFrames() throws {
        _ = NSApplication.shared
        let oldIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let icon = NSImage(contentsOfFile: path) { NSApp.applicationIconImage = icon }
        let oldLanguage = UserDefaults.standard.object(forKey: "ReadyCheck.language.v1")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            NSApp.applicationIconImage = oldIcon
            if let oldLanguage { UserDefaults.standard.set(oldLanguage, forKey: "ReadyCheck.language.v1") }
            else { UserDefaults.standard.removeObject(forKey: "ReadyCheck.language.v1") }
            try? FileManager.default.removeItem(at: directory)
        }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: PaceNoNetworkReader(),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: PaceNotificationClient(), verificationDelays: []))
        let now = Date()
        func snapshot(_ date: Date, _ remaining: Double) -> ProviderQuotaSnapshot {
            ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available,
                source: .appServer, refreshedAt: date, staleAfter: now.addingTimeInterval(300),
                windows: [QuotaWindow(id: "short", labelKey: "quota.window.codex.5h", kind: .rolling,
                    used: 100 - remaining, limit: 100, remaining: remaining, unit: .percent,
                    resetAt: now.addingTimeInterval(7200), confidence: .verified, durationMinutes: 300),
                    QuotaWindow(id: "week", labelKey: "quota.window.codex.7d", kind: .rolling,
                        used: 30, limit: 100, remaining: 70, unit: .percent,
                        resetAt: now.addingTimeInterval(172800), confidence: .verified, durationMinutes: 10080)],
                errors: [], details: ProviderQuotaDetails(planName: "plus", subscriptionRenewalAt: now.addingTimeInterval(86400),
                    manualResetCount: 2, manualResetExpirations: [now.addingTimeInterval(3600), now.addingTimeInterval(7200)], creditBalance: "120"),
                ordinaryUsageAllowed: true, accountID: "synthetic-account")
        }
        model.snapshots = [snapshot(now, 34)]
        model.quotaHistorySamples = (0...12).compactMap { index in
            QuotaHistorySample(snapshot: snapshot(now.addingTimeInterval(Double(index - 12) * 300), 34 + Double(12 - index) * 2))
        }
        model.lastSuccessfulRefreshAt = now
        model.lastRefreshAt = now
        model.codexOAuthStatus = .connected
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for threshold in [0, 10] {
                model.lowQuotaThreshold = threshold
                let pace = try XCTUnwrap(model.quotaPace(now: now))
                XCTAssertEqual(pace.state, .risk)
                XCTAssertEqual(pace.reminderEnabled, threshold != 0)
                XCTAssertEqual(model.lowQuotaThreshold, threshold)
                let expanded = QuotaPaceView(pace: pace, localization: model.localization, now: now)
                let compact = QuotaPaceView(pace: pace, localization: model.localization, now: now, compact: true)
                XCTAssertEqual(expanded.headline, compact.headline)
                XCTAssertEqual(expanded.comparison, compact.comparison)
                let suffix = "\(language.rawValue)-\(threshold)"
                try render(SettingsView(model: model), name: "pace-main-\(suffix)", size: CGSize(width: 900, height: 760))
                try render(MenuBarQuotaView(model: model, openSettings: {}), name: "pace-menu-\(suffix)", size: CGSize(width: 340, height: 500), maxHeight: 440)
                try render(BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil,
                    onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {}),
                    name: "pace-widget-\(suffix)", size: BubbleWidgetPlacement.expandedSize)
            }
        }
    }

    private func render<Content: View>(_ content: Content, name: String, size: CGSize, maxHeight: CGFloat? = nil) throws {
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let host = NSHostingView(rootView: content.frame(width: size.width)
            .background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .dark))
        window.contentView = host
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.7))
        if let maxHeight { XCTAssertLessThan(host.fittingSize.height, maxHeight) }
        if name.hasPrefix("pace-widget") {
            func scrollViews(in view: NSView) -> [NSScrollView] {
                (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap { scrollViews(in: $0) }
            }
            let scroll = try XCTUnwrap(scrollViews(in: host).first)
            let document = try XCTUnwrap(scroll.documentView)
            XCTAssertLessThanOrEqual(document.frame.height, scroll.contentSize.height + 1,
                "Both existing quota rows must remain fully visible with the new pace summary")
        }
        XCTAssertEqual(host.bounds.width, size.width, accuracy: 1)
        XCTAssertLessThanOrEqual(host.bounds.height, size.height + 1)
        if let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: directory).appendingPathComponent(name + ".png"))
        }
    }
}

private struct PaceNoNetworkReader: CodexAppServerReading {
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot { throw URLError(.notConnectedToInternet) }
}

@MainActor
private final class PaceNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

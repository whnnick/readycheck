import AppKit
import SwiftUI

import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class ResetCreditIntegrationTests: XCTestCase {
    func testModelRequiresOptInKeepsReminderSettingsAndRendersBilingualControl() async throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let keys = ["ReadyCheck.codexConnectionMode.v1", "ReadyCheck.language.v1"]
        let old = keys.map { defaults.object(forKey: $0) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defaults.set("localCodex", forKey: keys[0])
        defer {
            for (index, key) in keys.enumerated() {
                if let value = old[index] { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
            try? FileManager.default.removeItem(at: directory)
        }
        let reminders = QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json"))
        _ = await reminders.setLowQuotaThreshold(0)
        _ = await reminders.setAutomaticRecoveryEnabled(true)
        let client = IntegrationResetClient()
        let notifications = ResetSilentNotifications()
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")), quotaReminderStore: reminders,
            codexAppServerClient: IntegrationAccountReader(), rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: notifications, verificationDelays: [.zero]),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json")), resetCreditClient: client)
        await model.reloadCodexOAuthConnectionStatus()
        await model.reloadReminderHistory()
        XCTAssertTrue(model.resetExpiryReminderEnabled)
        await model.setResetExpiryReminderEnabled(false)
        let expiryOff = await reminders.resetExpiryReminderEnabled()
        XCTAssertFalse(expiryOff)
        await model.checkResetCreditAutomation()
        var reads = await client.reads
        XCTAssertEqual(reads, 0)
        await model.setResetCreditAutomationEnabled(true, confirmedAccount: "different-account")
        XCTAssertFalse(model.resetCreditStatus.enabled, "A confirmation for another account must not carry over")
        await model.setResetCreditAutomationEnabled(true, confirmedAccount: "fixture-account")
        XCTAssertTrue(model.resetCreditStatus.enabled)
        reads = await client.reads
        XCTAssertEqual(reads, 0, "Opt-in is saved; the next scheduled check executes it")
        await model.checkResetCreditAutomation()
        XCTAssertEqual(model.resetCreditStatus.status, .reset)
        XCTAssertEqual(notifications.requests.count, 1)
        let receipts = await reminders.history()
        XCTAssertEqual(receipts.first?.kind, .resetCreditUsed)
        XCTAssertEqual(receipts.first?.status, .delivered)
        let threshold = await reminders.lowQuotaThreshold()
        let recovery = await reminders.automaticRecoveryEnabled()
        XCTAssertEqual(threshold, 0)
        XCTAssertTrue(recovery)
        await model.setResetCreditAutomationEnabled(false)
        await model.checkResetCreditAutomation()
        reads = await client.reads
        XCTAssertEqual(reads, 1)
        await model.setResetExpiryReminderEnabled(true)
        XCTAssertTrue(model.resetExpiryReminderEnabled)
        XCTAssertFalse(model.resetCreditStatus.enabled)
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            let host = NSHostingView(rootView: VStack(alignment: .leading, spacing: 16) {
                ResetExpiryReminderView(model: model)
                Divider()
                ResetCreditAutomationView(model: model)
            }.padding(16)
                .frame(width: 430).background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .dark))
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 430, height: 500), styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.contentView = host
            host.frame = CGRect(x: 0, y: 0, width: 430, height: 500)
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertLessThan(host.fittingSize.height, 500)
            if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path).appendingPathComponent("reset-settings-\(language.rawValue).png"))
            }
            window.close()
        }
    }
}

private struct IntegrationAccountReader: CodexAppServerReading {
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        CodexAppServerAccountSnapshot(accountID: "fixture-account", email: "fixture@example.com", planName: "plus",
            rateLimits: [CodexAppServerRateLimitSnapshot(limitID: "codex", limitName: nil,
                primary: CodexAppServerRateLimitWindow(usedPercent: 50, durationMinutes: 300, resetsAt: Date().addingTimeInterval(7200)),
                secondary: nil, creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: "plus")], resetCredits: [], tokenUsage: nil)
    }
}
private actor IntegrationResetClient: ResetCreditServicing {
    var reads = 0
    let card = CodexAppServerResetCredit(id: "fixture-expiring", resetType: "codexRateLimits", status: "available", expiresAt: Date().addingTimeInterval(1800))
    func read(account: String, token: CodexOAuthToken?) async throws -> CodexAppServerAccountSnapshot {
        reads += 1
        return CodexAppServerAccountSnapshot(accountID: "fixture-account", email: nil, planName: nil, rateLimits: [], resetCredits: [card], resetCreditDetailsAvailable: true, tokenUsage: nil)
    }
    func consume(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit, idempotencyKey: String, authorization: ResetCreditAuthorization) async throws -> ResetCreditOutcome { .reset }
}
@MainActor private final class ResetSilentNotifications: NotificationCenterClient {
    var requests: [UNNotificationRequest] = []
    func configuration() async -> NotificationCenterConfiguration { NotificationCenterConfiguration(authorizationStatus: .authorized, alertSetting: .enabled, alertStyle: .alert) }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws { requests.append(request) }
    func deliveredIdentifiers() async -> Set<String> { Set(requests.map(\.identifier)) }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

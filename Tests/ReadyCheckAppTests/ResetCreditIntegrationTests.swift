import AppKit
import SwiftUI

import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class ResetCreditIntegrationTests: XCTestCase {
    func testUnreadableConsentDoesNotPresentAConfirmedOffSwitch() throws {
        _ = NSApplication.shared
        let savedLanguage = UserDefaults.standard.object(forKey: "ReadyCheck.language.v1")
        defer {
            if let savedLanguage { UserDefaults.standard.set(savedLanguage, forKey: "ReadyCheck.language.v1") }
            else { UserDefaults.standard.removeObject(forKey: "ReadyCheck.language.v1") }
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: IntegrationAccountReader(),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: ResetSilentNotifications(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("automation.json")))
        model.codexOAuthStatus = .connected
        model.resetCreditStatus = ResetCreditAutomationStatus(enabled: false, status: .storageFailed, updatedAt: nil)
        XCTAssertTrue(ResetCreditAutomationView(model: model).authorizationIsUnknown)
        model.resetCreditStatus = ResetCreditAutomationStatus(enabled: false, status: .off, updatedAt: nil)
        XCTAssertFalse(ResetCreditAutomationView(model: model).authorizationIsUnknown)
        model.codexOAuthStatus = .credentialStorageFailed
        XCTAssertTrue(ResetCreditAutomationView(model: model).authorizationIsUnknown)
        model.codexOAuthStatus = .connected
        for enabled in [true, false] {
            model.resetCreditStatus = ResetCreditAutomationStatus(enabled: enabled, status: enabled ? .waiting : .off, updatedAt: nil)
            XCTAssertFalse(ResetCreditAutomationView(model: model).authorizationIsUnknown)
        }
        model.resetCreditStatus = ResetCreditAutomationStatus(enabled: false, status: .storageFailed, updatedAt: nil)
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for dark in [false, true] {
                let size = CGSize(width: 380, height: 310)
                let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                let host = NSHostingView(rootView: ResetCreditAutomationView(model: model).padding(16).frame(width: size.width)
                    .background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, dark ? .dark : .light))
                window.contentView = host
                host.frame = CGRect(origin: .zero, size: size)
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.15))
                XCTAssertLessThanOrEqual(host.fittingSize.height, size.height)
                if let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                    let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: directory).appendingPathComponent("consent-unknown-\(language.rawValue)-\(dark ? "dark" : "light").png"))
                }
                window.close()
            }
        }
    }

    func testReliabilityDetailsRenderSourceAndPreparedRequestBilingually() throws {
        _ = NSApplication.shared
        let key = "ReadyCheck.language.v1", original = UserDefaults.standard.object(forKey: "ReadyCheck.language.v1")
        defer { if let original { UserDefaults.standard.set(original, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) } }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: IntegrationAccountReader(),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: ResetSilentNotifications(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("automation.json")))
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        model.resetCreditStatus = .init(enabled: true, status: .waiting, updatedAt: nil)
        let records = [
            ResetCreditExecutionRecord(id: "confirmed", expiresAt: now, status: .reset, updatedAt: now,
                successNotificationPending: true, startedAt: now.addingTimeInterval(-1800), requestCount: 2),
            ResetCreditExecutionRecord(id: "missing", expiresAt: now, status: .unrecorded, updatedAt: now,
                successNotificationPending: nil, observedOnly: true, reminderOnly: true),
            ResetCreditExecutionRecord(id: "server", expiresAt: now, status: .redeemedElsewhere, updatedAt: now,
                successNotificationPending: nil, observedOnly: true)
        ]
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for record in records {
                model.resetCreditRecords = [record]
                let size = CGSize(width: 540, height: 530)
                let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = NSAppearance(named: .darkAqua)
                let host = NSHostingView(rootView: ResetCreditDetailView(model: model, selection: .record(record.id), now: now)
                    .background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .dark))
                window.contentView = host; host.frame = CGRect(origin: .zero, size: size); host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.15))
                XCTAssertLessThanOrEqual(host.fittingSize.height, size.height)
                if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                    let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path).appendingPathComponent("card-\(record.id)-\(language.rawValue).png"))
                }
                window.close()
            }
        }
    }

    func testCredentialFailureIsRecordedAndWarningSubmittedOnce() async throws {
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.codexConnectionMode.v1"
        let original = defaults.object(forKey: key)
        defaults.set("localCodex", forKey: key)
        defer { if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) } }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let ledger = ResetCreditAutomation(fileURL: directory.appendingPathComponent("automation.json"))
        let notifications = ResetSilentNotifications()
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: IntegrationAccountReader(),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: notifications, verificationDelays: []),
            resetCreditAutomation: ledger, resetCreditClient: IntegrationResetClient())
        await model.reloadCodexOAuthConnectionStatus()
        _ = await ledger.setEnabled(true, account: "fixture-account")
        model.codexOAuthStatus = .credentialStorageFailed
        await model.checkResetCreditAutomation()
        await model.checkResetCreditAutomation()
        XCTAssertTrue(model.resetCreditStatus.enabled, "Failure is not consent revocation")
        XCTAssertEqual(model.resetCreditChecks.first?.reason, .credentialsUnavailable)
        XCTAssertEqual(model.resetCreditChecks.first?.count, 2)
        XCTAssertEqual(model.resetCreditChecks.first?.warningSubmitted, true)
        XCTAssertEqual(notifications.requests.count, 1, "Repeated blocked checks must not produce repeated banners")
        XCTAssertFalse(notifications.requests[0].identifier.contains("reset-used"))
        let restarted = ResetCreditAutomation(fileURL: directory.appendingPathComponent("automation.json"))
        let checks = try await restarted.checks(account: "fixture-account")
        XCTAssertEqual(checks.first?.warningSubmitted, true)
    }

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
        XCTAssertEqual(model.resetExpiryLeadHours, [12, 24, 48, 72])
        await model.setResetExpiryLeadHours([12, 48])
        await model.reloadReminderHistory()
        XCTAssertEqual(model.resetExpiryLeadHours, [12, 48])
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

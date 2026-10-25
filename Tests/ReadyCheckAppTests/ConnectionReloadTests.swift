import AppKit
import SwiftUI
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class ConnectionReloadTests: XCTestCase {
    func testStartupWaitsForOAuthBeforeCheckingExistingConsent() async throws {
        let started = expectation(description: "initial credential read held")
        let credentials = OAuthTestCredentials(onHeld: { started.fulfill() })
        try await withModel(credentials: credentials, savedConsent: true) { model, _ in
            defer { model.stopResetCreditAutomation() }
            await model.reloadReminderHistory()
            await credentials.holdNextRead()
            let startup = Task { await model.startConnectedServices() }
            await fulfillment(of: [started], timeout: 2)
            try await Task.sleep(for: .milliseconds(100))
            XCTAssertTrue(model.resetCreditChecks.isEmpty, "Pending sign-in reads must not create a false pause warning")
            await credentials.finishHeld(fails: false)
            await startup.value
            let deadline = Date().addingTimeInterval(2)
            while model.resetCreditChecks.isEmpty, Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
            XCTAssertEqual(model.resetCreditChecks.first?.reason, .checked)
            XCTAssertTrue(model.resetCreditStatus.enabled)
        }
    }

    func testLegacyLocalPreferenceCannotReplaceOAuthSignIn() async throws {
        let key = "ReadyCheck.codexConnectionMode.v1", old = UserDefaults.standard.object(forKey: "ReadyCheck.codexConnectionMode.v1")
        UserDefaults.standard.set("localCodex", forKey: key)
        defer { if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) } }
        try await withModel(credentials: OAuthTestCredentials(account: nil)) { model, _ in
            await model.reloadCodexOAuthConnectionStatus()
            await model.refresh(reason: .manual)
            XCTAssertEqual(model.codexOAuthStatus, .notConnected)
            XCTAssertEqual(model.snapshots.first?.errors, ["quota.error.oauthRequired"])
            XCTAssertFalse(model.canEnableResetCredits)
            XCTAssertEqual(UserDefaults.standard.string(forKey: key), "localCodex", "Keep legacy preference bytes for rollback; never use it for routing")
        }
    }

    func testFreshOAuthQuotaRestoresConnectionWithoutAnotherLogin() async throws {
        try await withModel { model, _ in
            await model.reloadCodexOAuthConnectionStatus()
            for status in [CodexOAuthConnectionStatus.notConnected, .credentialStorageFailed, .failed] {
                model.codexOAuthStatus = status; model.codexOAuthStatusMessage = "old failure"
                await model.refresh(reason: .automatic)
                XCTAssertEqual(model.codexOAuthStatus, .connected)
                XCTAssertNil(model.codexOAuthStatusMessage)
                XCTAssertEqual(model.snapshots.first?.source, .oauthAPI)
                XCTAssertTrue(model.canEnableResetCredits)
            }
        }
    }

    func testCachedQuotaCannotRestoreConnection() async throws {
        let http = OAuthTestHTTP()
        try await withModel(http: http) { model, _ in
            await model.refresh(reason: .manual)
            await http.failReads(); model.codexOAuthStatus = .notConnected
            await model.refresh(reason: .automatic)
            XCTAssertEqual(model.snapshots.first?.isCached, true)
            XCTAssertEqual(model.codexOAuthStatus, .notConnected)
        }
    }

    func testLateCredentialFailureCannotOverrideNewerSuccessfulQuota() async throws {
        let started = expectation(description: "held credential read")
        let credentials = OAuthTestCredentials(onHeld: { started.fulfill() })
        try await withModel(credentials: credentials) { model, _ in
            await model.reloadCodexOAuthConnectionStatus()
            await credentials.holdNextRead()
            let old = Task { await model.reloadCodexOAuthConnectionStatus() }
            await fulfillment(of: [started], timeout: 2)
            await model.refresh(reason: .automatic)
            await credentials.finishHeld(fails: true); await old.value
            XCTAssertEqual(model.codexOAuthStatus, .connected)
            XCTAssertTrue(model.canEnableResetCredits)
        }
    }

    func testLateCredentialReadCannotRestoreSignedOutAccount() async throws {
        let started = expectation(description: "held credential read")
        let credentials = OAuthTestCredentials(onHeld: { started.fulfill() })
        try await withModel(credentials: credentials) { model, _ in
            await credentials.holdNextRead()
            let old = Task { await model.reloadCodexOAuthConnectionStatus() }
            await fulfillment(of: [started], timeout: 2)
            await model.disconnectCodexOAuth()
            await credentials.finishHeld(fails: false); await old.value
            XCTAssertEqual(model.codexOAuthStatus, .notConnected)
            XCTAssertFalse(model.canEnableResetCredits)
        }
    }

    func testExistingConsentWaitsForLoginAndResumesOnlyForSameAccount() async throws {
        let credentials = OAuthTestCredentials(account: nil)
        try await withModel(credentials: credentials, savedConsent: true) { model, ledger in
            await model.reloadReminderHistory()
            await model.reloadCodexOAuthConnectionStatus()
            await model.refresh(reason: .manual)
            XCTAssertTrue(model.resetCreditStatus.enabled)
            XCTAssertTrue(ResetCreditAutomationView(model: model).authorizationIsUnknown)
            XCTAssertFalse(model.canEnableResetCredits)
            await credentials.useAccount("fixture-account")
            await model.reloadCodexOAuthConnectionStatus()
            XCTAssertTrue(model.resetCreditStatus.enabled)
            XCTAssertTrue(model.canEnableResetCredits)
            let saved = await ledger.status(account: "fixture-account")
            XCTAssertTrue(saved.enabled)
            await model.checkResetCreditAutomation()
            XCTAssertEqual(model.resetCreditChecks.first?.reason, .checked)
        }
    }

    func testDifferentOAuthAccountCannotInheritExistingConsent() async throws {
        try await withModel(credentials: OAuthTestCredentials(account: "other-account"), savedConsent: true) { model, ledger in
            await model.reloadReminderHistory(); await model.reloadCodexOAuthConnectionStatus()
            XCTAssertFalse(model.resetCreditStatus.enabled)
            let original = await ledger.status(account: "fixture-account")
            XCTAssertTrue(original.enabled)
            await model.checkResetCreditAutomation()
            XCTAssertTrue(model.resetCreditChecks.isEmpty)
        }
    }

    func testConnectionControlsRenderWithoutAlternativeLoginChoices() async throws {
        let key = "ReadyCheck.language.v1", saved = UserDefaults.standard.object(forKey: "ReadyCheck.language.v1")
        defer { if let saved { UserDefaults.standard.set(saved, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) } }
        try await withModel { model, _ in
            model.mainWindowPage = .settings; model.mainSettingsSection = .connection
            for language in [AppLanguage.zhCN, .enUS] {
                model.language = language
                for (index, status) in [CodexOAuthConnectionStatus.connected, .notConnected, .credentialStorageFailed].enumerated() {
                    model.codexOAuthStatus = status
                    let size = CGSize(width: 740, height: 760)
                    let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
                    window.isReleasedWhenClosed = false; window.appearance = NSAppearance(named: .darkAqua)
                    let host = NSHostingView(rootView: SettingsView(model: model).background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .dark))
                    window.contentView = host; host.frame = CGRect(origin: .zero, size: size); host.layoutSubtreeIfNeeded()
                    if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds)); host.cacheDisplay(in: host.bounds, to: bitmap)
                        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path).appendingPathComponent("oauth-only-\(index)-\(language.rawValue).png"))
                    }
                    window.close()
                }
            }
        }
    }

    func testWakeRefreshesOAuthAccountRatherThanFollowingLocalAccount() async throws {
        try await withModel { model, _ in
            defer { model.stopRateLimitMonitoring() }
            model.refreshAfterWake()
            let deadline = Date().addingTimeInterval(2)
            while model.snapshots.isEmpty, Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
            XCTAssertEqual(model.codexOAuthStatus, .connected)
            XCTAssertEqual(model.snapshots.first?.accountID, "fixture-account")
            XCTAssertNil(model.snapshots.first?.details?.accountTokenUsage)
        }
    }

    private func withModel(credentials: OAuthTestCredentials = OAuthTestCredentials(), http: OAuthTestHTTP = OAuthTestHTTP(),
                           savedConsent: Bool = false, body: (ReadyCheckAppModel, ResetCreditAutomation) async throws -> Void) async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let reminders = QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json"))
        let ledger = ResetCreditAutomation(fileURL: directory.appendingPathComponent("automation.json"))
        if savedConsent { await reminders.updateDetailsAccount("fixture-account"); _ = await ledger.setEnabled(true, account: "fixture-account") }
        let model = ReadyCheckAppModel(credentialStore: credentials, codexQuotaClient: CodexQuotaHTTPClient(loader: http),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")), quotaReminderStore: reminders,
            codexAppServerClient: OtherLocalAccountReader(), rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: OAuthConnectionNotifications(), verificationDelays: []),
            resetCreditAutomation: ledger, resetCreditClient: NonConsumingOAuthResetClient())
        try await body(model, ledger)
    }
}

private struct OtherLocalAccountReader: CodexAppServerReading {
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        .init(accountID: "local-other-account", email: nil, planName: nil, rateLimits: [],
            resetCredits: [], tokenUsage: .init(summary: .init(lifetimeTokens: 999), dailyBuckets: []))
    }
}
private struct NonConsumingOAuthResetClient: ResetCreditServicing {
    func read(account: String, token: CodexOAuthToken?) async throws -> CodexAppServerAccountSnapshot {
        .init(accountID: account, email: nil, planName: nil, rateLimits: [], resetCredits: [], resetCreditDetailsAvailable: true, tokenUsage: nil)
    }
    func consume(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit, idempotencyKey: String, authorization: ResetCreditAuthorization) async throws -> ResetCreditOutcome { throw URLError(.unsupportedURL) }
}
@MainActor private final class OAuthConnectionNotifications: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration { .init(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none) }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

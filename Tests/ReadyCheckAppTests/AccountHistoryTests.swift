import AppKit
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class AccountHistoryTests: XCTestCase {
    func testDisconnectRemovesOnlyOAuthTokenAndPreservesHistoryAndReminderChoices() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let credentials = InMemoryCredentialStore()
        let unrelated = CredentialKey(providerId: "other-provider", name: "retained")
        try await credentials.saveCredential("fixture-secret", for: unrelated)
        let tokens = CodexOAuthTokenStore(credentialStore: credentials)
        try await tokens.saveToken(CodexOAuthToken(accessToken: "fixture-access", refreshToken: "fixture-refresh",
            idToken: nil, tokenType: "Bearer", expiresAt: Date().addingTimeInterval(3600), accountID: "fixture-account", email: nil))
        let historyURL = directory.appendingPathComponent("history.json")
        let original = try JSONEncoder().encode([QuotaHistorySample(providerID: "codex-oauth", recordedAt: Date(),
            values: [QuotaHistoryValue(windowID: "short", labelKey: "quota.fiveHour", remainingRatio: 0.5, resetAt: nil)], accountKey: "fixture-owner")])
        try original.write(to: historyURL)
        let reminders = QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json"))
        _ = await reminders.setLowQuotaThreshold(10)
        _ = await reminders.setAutomaticRecoveryEnabled(true)
        _ = await reminders.setResetExpiryReminderEnabled(false)
        let model = ReadyCheckAppModel(credentialStore: credentials,
            quotaHistoryStore: QuotaHistoryStore(fileURL: historyURL), quotaReminderStore: reminders,
            quotaNotificationService: QuotaNotificationService(client: SilentHistoryNotificationClient(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json")))
        await model.disconnectCodexOAuth()
        let token = try await tokens.loadToken()
        let other = try await credentials.loadCredential(for: unrelated)
        let threshold = await reminders.lowQuotaThreshold()
        let recovery = await reminders.automaticRecoveryEnabled()
        let expiry = await reminders.resetExpiryReminderEnabled()
        XCTAssertNil(token)
        XCTAssertEqual(other, "fixture-secret")
        XCTAssertEqual(try Data(contentsOf: historyURL), original)
        XCTAssertEqual(threshold, 10)
        XCTAssertTrue(recovery)
        XCTAssertFalse(expiry)
        XCTAssertEqual(model.codexOAuthStatus, .notConnected)
    }

    func testRefreshBindsQuotaHistoryToVerifiedSnapshotAccount() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let key = "ReadyCheck.codexConnectionMode.v1"
        let previous = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set("localCodex", forKey: key)
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let history = QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json"))
        let credentials = OAuthTestCredentials(account: "A")
        let model = ReadyCheckAppModel(credentialStore: credentials, codexQuotaClient: CodexQuotaHTTPClient(loader: OAuthTestHTTP(usedByAccount: ["A": 20, "B": 60])), quotaHistoryStore: history,
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: HistoryAccountReader(),
            quotaNotificationService: QuotaNotificationService(client: SilentHistoryNotificationClient(), verificationDelays: []))
        for (account, ratio) in [("A", 0.8), ("B", 0.4), ("A", 0.8)] {
            await credentials.useAccount(account)
            await model.refresh(reason: .manual)
            XCTAssertEqual(model.snapshots.first(where: { $0.providerId == "codex-oauth" })?.accountID, account)
            XCTAssertEqual(model.quotaHistorySamples.count, 1)
            XCTAssertEqual(model.quotaHistorySamples.first?.values.first?.remainingRatio, ratio)
        }
        let storedB = await history.load(accountID: "B")
        XCTAssertEqual(storedB.first?.values.first?.remainingRatio, 0.4)
    }
}

private actor HistoryAccountReader: CodexAppServerReading {
    var index = 0
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        let isB = index % 3 == 1
        index += 1
        return CodexAppServerAccountSnapshot(accountID: isB ? "B" : "A", email: nil, planName: nil,
            rateLimits: [CodexAppServerRateLimitSnapshot(limitID: "codex", limitName: nil,
                primary: CodexAppServerRateLimitWindow(usedPercent: isB ? 60 : 20, durationMinutes: 300,
                    resetsAt: Date().addingTimeInterval(3600)), secondary: nil,
                creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: nil)], manualResetCount: 0,
            resetCredits: [], tokenUsage: nil, ordinaryUsageAllowed: true)
    }
}

@MainActor
private final class SilentHistoryNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

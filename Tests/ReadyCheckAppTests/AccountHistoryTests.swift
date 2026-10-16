import AppKit
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class AccountHistoryTests: XCTestCase {
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
        let model = ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(), quotaHistoryStore: history,
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: HistoryAccountReader(),
            quotaNotificationService: QuotaNotificationService(client: SilentHistoryNotificationClient(), verificationDelays: []))
        for (account, ratio) in [("A", 0.8), ("B", 0.4), ("A", 0.8)] {
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

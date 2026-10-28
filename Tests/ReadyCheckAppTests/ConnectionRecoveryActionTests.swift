import XCTest
import ReadyCheckCore
@testable import ReadyCheckApp

final class ConnectionRecoveryActionTests: XCTestCase {
    private func snapshot(errors: [String]) -> ProviderQuotaSnapshot {
        .init(providerId: "codex-oauth", displayName: "Codex", status: .unavailable,
              source: .oauthAPI, refreshedAt: .now, staleAfter: .distantFuture, windows: [], errors: errors)
    }

    func testCredentialRestrictionTakesPriorityWithoutTreatingItAsExpiredLogin() {
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .credentialStorageFailed,
            snapshot: snapshot(errors: ["quota.error.authorizationRejected"])), .retryCredentials)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected,
            snapshot: snapshot(errors: ["oauth.error.keychainReadFailed"])), .retryCredentials)
    }

    func testNetworkOrMissingCardDataUsesRefreshInsteadOfReplacingAuthorization() {
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected,
            snapshot: snapshot(errors: ["quota.error.network"])), .refresh)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected,
            snapshot: snapshot(errors: [])), .refresh)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected, snapshot: nil), .refresh)
    }

    func testExplicitAuthenticationFailureRoutesToConnectionAndPendingLoginWaits() {
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected,
            snapshot: snapshot(errors: ["quota.error.authorizationRejected"])), .connection)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .notConnected, snapshot: nil), .connection)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .failed, snapshot: nil), .connection)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .waitingForCallback, snapshot: nil), .waiting)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .exchanging, snapshot: nil), .waiting)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .waitingForCallback,
            snapshot: snapshot(errors: ["oauth.error.keychainReadFailed"])), .waiting)
    }

    @MainActor
    func testConnectionActionNavigatesDirectlyAndStaleActionDoesNothing() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ReadyCheckAppModel(credentialStore: OAuthTestCredentials(account: nil),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: ClaritySilentNotifications(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json")))
        var opened = 0
        model.openMainWindow = { opened += 1 }
        model.mainWindowPage = .notifications
        model.codexOAuthStatus = .failed
        await model.performConnectionRecovery(.refresh)
        XCTAssertNil(model.lastRefreshAt)
        XCTAssertEqual(model.mainWindowPage, .notifications)
        await model.performConnectionRecovery(.connection)
        XCTAssertEqual(model.mainWindowPage, .settings)
        XCTAssertEqual(model.mainSettingsSection, .connection)
        XCTAssertEqual(opened, 1)
        XCTAssertEqual(model.codexOAuthStatus, .failed, "Navigation must not replace existing credentials")
        model.codexOAuthStatus = .waitingForCallback
        await model.performConnectionRecovery(.connection)
        XCTAssertEqual(opened, 1)
    }

    func testUnsupportedParserHasAnUpdateActionAndUnsafeEndpointDoesNotRetry() {
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected,
            snapshot: snapshot(errors: ["quota.error.parserUnavailable"])), .checkUpdates)
        XCTAssertEqual(ConnectionRecoveryAction.resolve(status: .connected,
            snapshot: snapshot(errors: ["quota.error.unsafeEndpoint"])), .connection)
    }
}

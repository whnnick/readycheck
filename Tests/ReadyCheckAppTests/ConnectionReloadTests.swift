import AppKit
import SwiftUI
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class ConnectionReloadTests: XCTestCase {
    func testConnectionPagePreservesSavedSourceAndConsentInBothLanguages() async throws {
        let languageKey = "ReadyCheck.language.v1"
        let original = UserDefaults.standard.object(forKey: languageKey)
        defer {
            if let original { UserDefaults.standard.set(original, forKey: languageKey) }
            else { UserDefaults.standard.removeObject(forKey: languageKey) }
        }
        for language in [AppLanguage.zhCN, .enUS] {
            for mode in CodexConnectionMode.allCases {
                try await withModel(mode: mode, reader: ImmediateConnectionReader()) { model in
                    model.language = language
                    model.mainWindowPage = .settings; model.mainSettingsSection = .connection
                    model.resetCreditStatus = .init(enabled: true, status: .waiting, updatedAt: nil)
                    let statuses: [CodexOAuthConnectionStatus] = mode == .localCodex ? [.connected, .notConnected] : [.connected, .credentialStorageFailed]
                    for (index, status) in statuses.enumerated() {
                        model.codexOAuthStatus = status
                        model.codexOAuthLoginEmail = status == .connected ? "sample@example.com" : nil
                        let size = CGSize(width: 740, height: 760)
                        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
                        window.isReleasedWhenClosed = false
                        window.appearance = NSAppearance(named: .darkAqua)
                        let host = NSHostingView(rootView: SettingsView(model: model)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .environment(\.colorScheme, .dark))
                        window.contentView = host; host.frame = CGRect(origin: .zero, size: size)
                        host.layoutSubtreeIfNeeded()
                        try await Task.sleep(for: .milliseconds(180))
                        XCTAssertEqual(model.codexConnectionMode, mode)
                        XCTAssertEqual(UserDefaults.standard.string(forKey: "ReadyCheck.codexConnectionMode.v1"), mode.rawValue)
                        XCTAssertTrue(model.resetCreditStatus.enabled, "Rendering cannot reset existing card-use consent")
                        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                            host.cacheDisplay(in: host.bounds, to: bitmap)
                            try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path).appendingPathComponent("connection-\(mode.rawValue)-\(index)-\(language.rawValue).png"))
                        }
                        window.close()
                    }
                }
            }
        }
    }

    func testLateLocalConnectionResultCannotReplaceStandaloneSignedOutState() async throws {
        for fails in [false, true] {
            let started = expectation(description: "old local read started")
            let reader = DelayedConnectionReader(onStarted: { started.fulfill() })
            try await withModel(mode: .localCodex, reader: reader) { model in
                let oldRead = Task { await model.reloadCodexOAuthConnectionStatus() }
                await fulfillment(of: [started], timeout: 2)
                await model.setCodexConnectionMode(.standaloneOAuth)
                XCTAssertEqual(model.codexOAuthStatus, .notConnected)
                await reader.finish(fails: fails)
                await oldRead.value
                XCTAssertEqual(model.codexConnectionMode, .standaloneOAuth)
                XCTAssertEqual(model.codexOAuthStatus, .notConnected)
                XCTAssertNil(model.codexOAuthLoginEmail)
                XCTAssertNil(model.codexOAuthStatusMessage)
            }
        }
    }

    func testLateStoredCredentialCannotReplaceLocalAccount() async throws {
        for fails in [false, true] {
            let started = expectation(description: "old credential read started")
            let credentials = DelayedConnectionCredentials(onStarted: { started.fulfill() })
            try await withModel(mode: .standaloneOAuth, reader: ImmediateConnectionReader(), credentials: credentials) { model in
                let oldRead = Task { await model.reloadCodexOAuthConnectionStatus() }
                await fulfillment(of: [started], timeout: 2)
                await model.setCodexConnectionMode(.localCodex)
                XCTAssertEqual(model.codexOAuthLoginEmail, "new@example.com")
                try await credentials.finish(fails: fails)
                await oldRead.value
                XCTAssertEqual(model.codexConnectionMode, .localCodex)
                XCTAssertEqual(model.codexOAuthStatus, .connected)
                XCTAssertEqual(model.codexOAuthLoginEmail, "new@example.com")
                XCTAssertNil(model.codexOAuthStatusMessage)
                XCTAssertEqual(model.snapshots.first?.accountID, "new-account")
            }
        }
    }

    func testNewConnectionRefreshDoesNotWaitForOrGetClearedByOldRefresh() async throws {
        let oldStarted = expectation(description: "old refresh started")
        let newStarted = expectation(description: "new connection refresh started")
        let reader = SwitchingConnectionReader(oldStarted: { oldStarted.fulfill() },
                                               newStarted: { newStarted.fulfill() })
        try await withModel(mode: .standaloneOAuth, reader: reader) { model in
            let oldRefresh = Task { await model.refresh(reason: .manual) }
            await fulfillment(of: [oldStarted], timeout: 2)
            let newConnection = Task { await model.setCodexConnectionMode(.localCodex) }
            await fulfillment(of: [newStarted], timeout: 2)
            XCTAssertTrue(model.isRefreshing)
            await reader.finishOld()
            await oldRefresh.value
            XCTAssertTrue(model.isRefreshing, "The old request must not clear the new connection's activity")
            await reader.finishNew()
            await newConnection.value
            XCTAssertFalse(model.isRefreshing)
            XCTAssertEqual(model.snapshots.first?.accountID, "new-account")
            XCTAssertEqual(model.quotaHistorySamples.first?.values.first?.remainingRatio, 0.8)
        }
    }

    func testWakeCallbackRefreshesConnectionAndFreshQuotaWithoutLaunchingHost() async throws {
        try await withModel(mode: .localCodex, reader: ImmediateConnectionReader()) { model in
            defer { model.stopRateLimitMonitoring() }
            model.refreshAfterWake()
            let deadline = Date().addingTimeInterval(2)
            while model.snapshots.isEmpty, Date() < deadline {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            XCTAssertEqual(model.codexOAuthStatus, .connected)
            XCTAssertEqual(model.codexOAuthLoginEmail, "new@example.com")
            XCTAssertEqual(model.snapshots.first?.accountID, "new-account")
            XCTAssertNotEqual(model.snapshots.first?.isCached, true)
            XCTAssertNotNil(model.lastRefreshAt)
            XCTAssertFalse(model.isRefreshing)
        }
    }

    private func withModel(mode: CodexConnectionMode, reader: any CodexAppServerReading, credentials: any CredentialStore = InMemoryCredentialStore(),
                           body: (ReadyCheckAppModel) async throws -> Void) async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let key = "ReadyCheck.codexConnectionMode.v1"
        let saved = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(mode.rawValue, forKey: key)
        defer {
            try? FileManager.default.removeItem(at: directory)
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let model = ReadyCheckAppModel(credentialStore: credentials,
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            codexAppServerClient: reader,
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: ConnectionNotificationClient(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("automation.json")))
        try await body(model)
    }
}

private actor DelayedConnectionReader: CodexAppServerReading {
    let onStarted: @Sendable () -> Void
    var continuation: CheckedContinuation<CodexAppServerAccountSnapshot, Error>?
    private var started = false
    init(onStarted: @escaping @Sendable () -> Void) { self.onStarted = onStarted }
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        guard !started else { throw URLError(.notConnectedToInternet) }
        started = true
        return try await withCheckedThrowingContinuation {
            continuation = $0
            onStarted()
        }
    }
    func finish(fails: Bool) {
        if fails { continuation?.resume(throwing: URLError(.notConnectedToInternet)) }
        else {
            continuation?.resume(returning: CodexAppServerAccountSnapshot(accountID: "old-account",
                email: "old@example.com", planName: nil,
                rateLimits: [CodexAppServerRateLimitSnapshot(limitID: "codex", limitName: nil,
                    primary: CodexAppServerRateLimitWindow(usedPercent: 20, durationMinutes: 300,
                        resetsAt: Date().addingTimeInterval(3600)), secondary: nil,
                    creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: nil)],
                resetCredits: [], tokenUsage: nil))
        }
        continuation = nil
    }
}

@MainActor
private final class ConnectionNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

private struct ImmediateConnectionReader: CodexAppServerReading {
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot { connectionSnapshot() }
}

private func connectionSnapshot() -> CodexAppServerAccountSnapshot {
    CodexAppServerAccountSnapshot(accountID: "new-account", email: "new@example.com", planName: nil,
        rateLimits: [CodexAppServerRateLimitSnapshot(limitID: "codex", limitName: nil,
            primary: CodexAppServerRateLimitWindow(usedPercent: 20, durationMinutes: 300,
                resetsAt: Date().addingTimeInterval(3600)), secondary: nil,
            creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: nil)],
        resetCredits: [], tokenUsage: nil)
}

private actor DelayedConnectionCredentials: CredentialStore {
    let onStarted: @Sendable () -> Void
    private var started = false
    private var continuation: CheckedContinuation<String?, Error>?
    init(onStarted: @escaping @Sendable () -> Void) { self.onStarted = onStarted }
    func loadCredential(for key: CredentialKey) async throws -> String? {
        guard !started else { return nil }
        started = true
        return try await withCheckedThrowingContinuation { continuation = $0; onStarted() }
    }
    func saveCredential(_ credential: String, for key: CredentialKey) async throws {}
    func removeCredential(for key: CredentialKey) async throws {}
    func finish(fails: Bool) throws {
        if fails { continuation?.resume(throwing: KeychainCredentialStoreError.unexpectedStatus(-25293)) }
        else {
            let token = CodexOAuthToken(accessToken: "synthetic-access", refreshToken: "synthetic-refresh",
                idToken: nil, tokenType: "Bearer", expiresAt: Date().addingTimeInterval(3600),
                accountID: "old-account", email: "old@example.com")
            let payload = String(decoding: try JSONEncoder().encode(token), as: UTF8.self)
            continuation?.resume(returning: payload)
        }
        continuation = nil
    }
}

private actor SwitchingConnectionReader: CodexAppServerReading {
    let oldStarted: @Sendable () -> Void
    let newStarted: @Sendable () -> Void
    private var count = 0
    private var oldContinuation: CheckedContinuation<CodexAppServerAccountSnapshot, Never>?
    private var newContinuation: CheckedContinuation<CodexAppServerAccountSnapshot, Never>?
    init(oldStarted: @escaping @Sendable () -> Void, newStarted: @escaping @Sendable () -> Void) {
        self.oldStarted = oldStarted; self.newStarted = newStarted
    }
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        count += 1
        if count == 1 {
            return await withCheckedContinuation { oldContinuation = $0; oldStarted() }
        }
        if count == 3 {
            return await withCheckedContinuation { newContinuation = $0; newStarted() }
        }
        return connectionSnapshot()
    }
    func finishOld() { oldContinuation?.resume(returning: connectionSnapshot()); oldContinuation = nil }
    func finishNew() { newContinuation?.resume(returning: connectionSnapshot()); newContinuation = nil }
}

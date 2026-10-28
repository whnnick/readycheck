import AppKit
import SwiftUI
import UserNotifications
import XCTest
import ReadyCheckCore
@testable import ReadyCheckApp

@MainActor
final class ReminderClarityNativeTests: XCTestCase {
    func testCardTimelineAndRecoveryAtNativeSizes() async throws {
        guard let output = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else {
            throw XCTSkip("Opt-in synthetic native evidence")
        }
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let savedLanguage = defaults.object(forKey: "ReadyCheck.language.v1")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            if let savedLanguage { defaults.set(savedLanguage, forKey: "ReadyCheck.language.v1") }
            else { defaults.removeObject(forKey: "ReadyCheck.language.v1") }
            try? FileManager.default.removeItem(at: directory)
        }
        let model = ReadyCheckAppModel(credentialStore: OAuthTestCredentials(account: nil),
            quotaHistoryStore: QuotaHistoryStore(fileURL: directory.appendingPathComponent("history.json")),
            quotaReminderStore: QuotaReminderStore(fileURL: directory.appendingPathComponent("reminders.json")),
            rateLimitMonitor: CodexAppServerRateLimitMonitor(candidateExecutableURLs: []),
            quotaNotificationService: QuotaNotificationService(client: ClaritySilentNotifications(), verificationDelays: []),
            resetCreditAutomation: ResetCreditAutomation(fileURL: directory.appendingPathComponent("reset.json")))
        let now = Date()
        let records = [
            ResetCreditExecutionRecord(id: "synthetic-confirmed", expiresAt: now.addingTimeInterval(1200), status: .reset,
                updatedAt: now.addingTimeInterval(-120), successNotificationPending: false,
                startedAt: now.addingTimeInterval(-180), requestCount: 1),
            ResetCreditExecutionRecord(id: "synthetic-observed", expiresAt: now.addingTimeInterval(7200), status: .observing,
                updatedAt: now.addingTimeInterval(-240), successNotificationPending: nil, observedOnly: true),
            ResetCreditExecutionRecord(id: "synthetic-legacy", expiresAt: now.addingTimeInterval(-7200), status: .unrecorded,
                updatedAt: now.addingTimeInterval(-7200), successNotificationPending: nil, observedOnly: true, reminderOnly: true)
        ]
        let confirmed = records[0]
        model.reminderHistoryRecords = [.init(id: "reset-used:\(confirmed.id)", kind: .resetCreditUsed, status: .delivered,
            lastAttemptAt: now.addingTimeInterval(-90), deliveredAt: now.addingTimeInterval(-89), expiresAt: confirmed.expiresAt)]
        model.resetCreditRecords = records
        model.resetCreditStatus = .init(enabled: true, status: .waiting, updatedAt: nil)
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for dark in [false, true] {
                for record in records {
                    try await capture(ResetCreditDetailView(model: model, selection: .record(record.id), now: now),
                        name: "detail-\(record.id)-\(language.rawValue)-\(dark)", size: .init(width: 540, height: 400), dark: dark, output: output)
                }
                model.codexOAuthStatus = .credentialStorageFailed
                try await capture(DataStatusView(model: model, close: {}), name: "restricted-\(language.rawValue)-\(dark)",
                    size: .init(width: 390, height: 450), dark: dark, output: output)
            }
        }
    }

    private func capture<Content: View>(_ content: Content, name: String, size: CGSize, dark: Bool, output: String) async throws {
        let host = NSHostingView(rootView: content.background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, dark ? .dark : .light))
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        window.contentView = host
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertLessThanOrEqual(host.fittingSize.width, size.width + 1)
        XCTAssertLessThanOrEqual(host.fittingSize.height, size.height + 1)
        try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: output).appendingPathComponent(name + ".png"))
    }
}

@MainActor
final class ClaritySilentNotifications: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        .init(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws { XCTFail("Read-only clarity tests must not submit notifications") }
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

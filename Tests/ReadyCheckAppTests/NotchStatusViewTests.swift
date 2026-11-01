import AppKit
import SwiftUI
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class NotchStatusViewTests: XCTestCase {
    func testDualDetailsOrderIsStableButSingleModeRetainsPrimarySelectionAndEveryWindow() {
        let five = window("five", minutes: 300), seven = window("seven", minutes: 10080)
        let other = window("other", minutes: 1440), windows = [seven, other, five]
        let primary = NotchQuotaSelection.window("seven")
        XCTAssertEqual(NotchDetailsView.orderedWindows(windows, primary: primary, showsBoth: true).map(\.id), ["five", "seven", "other"])
        XCTAssertEqual(NotchDetailsView.orderedWindows(windows, primary: primary, showsBoth: false).map(\.id), ["seven", "other", "five"])
    }

    func testDualRowsKeepFiveHourAndSevenDayOrderWithoutBorrowingMissingValues() {
        let five = window("five", minutes: 300), seven = window("seven", minutes: 10080)
        XCTAssertEqual(NotchStatusView.dualWindows(in: [seven, five]).map { $0?.id }, ["five", "seven"])
        XCTAssertEqual(NotchStatusView.dualWindows(in: [five]).map { $0?.id }, ["five", nil])
        XCTAssertEqual(NotchStatusView.dualWindows(in: [window("other", minutes: 1440)]).compactMap { $0 }.count, 0)
    }

    func testDualRowDoesNotPresentStaleOrMissingReadingAsPercentage() {
        let now = Date(), five = window("five", minutes: 300)
        XCTAssertEqual(NotchStatusView.ratio(for: five, snapshot: snapshot(now), now: now), 0.8)
        XCTAssertNil(NotchStatusView.ratio(for: nil, snapshot: snapshot(now), now: now))
        XCTAssertNil(NotchStatusView.ratio(for: five, snapshot: snapshot(now.addingTimeInterval(-600)), now: now))
    }

    func testDualLayoutDefaultsOnPersistsAndRetainsPrimaryWindowChoice() {
        let defaults = UserDefaults.standard, key = "ReadyCheck.notchShowsBothQuotas.v1"
        let saved = defaults.object(forKey: key), originalSelection = NotchQuotaSelection.value()
        defer { if let saved { defaults.set(saved, forKey: key) } else { defaults.removeObject(forKey: key) } }
        defaults.removeObject(forKey: key)
        let model = makeModel()
        XCTAssertTrue(model.notchShowsBothQuotas)
        model.notchShowsBothQuotas = false
        XCTAssertFalse(makeModel().notchShowsBothQuotas)
        XCTAssertEqual(NotchQuotaSelection.value(), originalSelection)
    }

    func testNotchLayoutsFitActualCompactSizeAndRenderRoundedCorners() throws {
        _ = NSApplication.shared
        let model = makeModel()
        let defaults = UserDefaults.standard, key = "ReadyCheck.notchShowsBothQuotas.v1"
        let saved = defaults.object(forKey: key), originalService = model.selectedDeepSeek
        defer {
            model.selectedDeepSeek = originalService
            if let saved { defaults.set(saved, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        model.snapshots = [snapshot(Date())]
        for mode in ["dual", "single", "deepseek", "missing"] {
            model.selectedDeepSeek = mode == "deepseek"
            model.notchShowsBothQuotas = mode != "single"
            model.snapshots = mode == "missing" ? [] : [snapshot(Date())]
            let view = NotchStatusView(model: model).frame(width: 185, height: 42)
                .padding(12).background(Color(red: 0.7, green: 0.75, blue: 0.8))
            let host = NSHostingView(rootView: view)
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 209, height: 66),
                styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.contentView = host
            host.frame = CGRect(x: 0, y: 0, width: 209, height: 66)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            defer { window.close() }
            XCTAssertLessThanOrEqual(host.fittingSize.height, 67, mode)
            XCTAssertLessThanOrEqual(host.fittingSize.width, 210, mode)
            if let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to:
                    URL(fileURLWithPath: directory).appendingPathComponent("notch-\(mode).png"))
            }
        }
    }

    func testExpandedDetailsRenderDualWithoutSelectorAndSingleWithSelector() throws {
        _ = NSApplication.shared
        let model = makeModel()
        let defaults = UserDefaults.standard, key = "ReadyCheck.notchShowsBothQuotas.v1"
        let saved = defaults.object(forKey: key), originalService = model.selectedDeepSeek
        let originalLanguage = model.language
        defer {
            model.selectedDeepSeek = originalService
            model.language = originalLanguage
            if let saved { defaults.set(saved, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        model.selectedDeepSeek = false
        model.snapshots = [snapshot(Date())]
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            for dual in [true, false] {
                model.notchShowsBothQuotas = dual
                let host = NSHostingView(rootView: NotchStatusView(model: model, isExpanded: true)
                    .frame(width: 360, height: 264).environment(\.locale, Locale(identifier: language.rawValue)))
                let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 360, height: 264),
                    styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = NSAppearance(named: .darkAqua)
                window.contentView = host
                host.frame = CGRect(x: 0, y: 0, width: 360, height: 264)
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                defer { window.close() }
                XCTAssertLessThanOrEqual(host.fittingSize.width, 361)
                XCTAssertLessThanOrEqual(host.fittingSize.height, 265)
                if let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] {
                    let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to:
                        URL(fileURLWithPath: directory).appendingPathComponent("notch-details-\(dual)-\(language.rawValue).png"))
                }
            }
        }
    }

    private func window(_ id: String, minutes: Int) -> QuotaWindow {
        QuotaWindow(id: id, labelKey: "quota.window.codex.primary", kind: .rolling,
            used: id == "seven" ? 65 : 20, limit: 100, remaining: id == "seven" ? 35 : 80,
            unit: .percent, resetAt: nil, confidence: .verified,
            durationMinutes: minutes)
    }

    private func makeModel() -> ReadyCheckAppModel {
        ReadyCheckAppModel(credentialStore: InMemoryCredentialStore(),
            quotaNotificationService: QuotaNotificationService(client: NotchLayoutNotificationClient(), verificationDelays: []))
    }

    private func snapshot(_ now: Date) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available,
            source: .appServer, refreshedAt: now, staleAfter: now.addingTimeInterval(300),
            windows: [window("five", minutes: 300), window("seven", minutes: 10080)], errors: [])
    }
}

@MainActor
private final class NotchLayoutNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        .init(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

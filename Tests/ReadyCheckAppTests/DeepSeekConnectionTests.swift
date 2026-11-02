import Foundation
import AppKit
import SwiftUI
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class DeepSeekConnectionTests: XCTestCase {
    func testSelectedServiceRefreshAndCompactBalance() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = InMemoryCredentialStore(), loader = CountingDeepSeekStub()
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: loader),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        await connection.connect(key: "synthetic")
        let model = ReadyCheckAppModel(credentialStore: store, deepSeekConnection: connection,
            deepSeekAlertStore: DeepSeekBalanceAlertStore(fileURL: directory.appendingPathComponent("alerts.json")),
            quotaNotificationService: QuotaNotificationService(client: DeepSeekSilentNotifications(), verificationDelays: []))
        let originalSelection = model.selectedDeepSeek
        defer { model.selectedDeepSeek = originalSelection }
        model.selectedDeepSeek = true
        await model.refreshSelectedService()
        let count = await loader.count
        XCTAssertEqual(count, 2)
        XCTAssertTrue(DeepSeekDisplay.balanceText(connection: connection, now: Date()).hasPrefix("CNY "))
        XCTAssertEqual(DeepSeekDisplay.balanceText(connection: connection, now: Date().addingTimeInterval(301)), "—")
        let readout = ServiceCompactReadout(model: model, now: Date())
        XCTAssertEqual(readout.balanceHeading, "CNY")
        XCTAssertFalse(readout.primaryText.contains("CNY"), "Currency belongs above the balance, not in its numeric line")
        XCTAssertFalse(readout.primaryText.contains("%"), "API balance has no quota percentage")
        let staleReadout = ServiceCompactReadout(model: model, now: Date().addingTimeInterval(301))
        XCTAssertEqual(staleReadout.primaryText, "—")
        XCTAssertNotEqual(staleReadout.balanceHeading, "CNY", "Unconfirmed state must remain visible")
    }

    func testDeepSeekNativeSurfacesWithSyntheticData() async throws {
        guard let output = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else {
            throw XCTSkip("Opt-in synthetic native evidence")
        }
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = InMemoryCredentialStore()
        let historyStore = DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json"))
        let credential = DeepSeekConnection.Credential(key: "synthetic", connectionID: UUID())
        try await store.saveCredential(try credential.encode(), for: DeepSeekConnection.credentialKey)
        for (seconds, amount) in [(-900.0, "5.0006"), (-600.0, "5.0004"), (-300.0, "5.0002")] {
            try await historyStore.record(connectionID: credential.connectionID, observedAt: Date().addingTimeInterval(seconds),
                balances: [DeepSeekBalance(currency: "CNY", total: Decimal(string: amount)!, granted: 1,
                    toppedUp: Decimal(string: amount)! - 1)])
        }
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: DeepSeekStub(status: 200)),
            historyStore: historyStore)
        await connection.refresh()
        await connection.refresh()
        let model = ReadyCheckAppModel(credentialStore: store, deepSeekConnection: connection,
            deepSeekAlertStore: DeepSeekBalanceAlertStore(fileURL: directory.appendingPathComponent("alerts.json")),
            quotaNotificationService: QuotaNotificationService(client: DeepSeekSilentNotifications(), verificationDelays: []))
        let originalSelection = model.selectedDeepSeek, originalLanguage = model.language
        defer { model.selectedDeepSeek = originalSelection; model.language = originalLanguage }
        model.selectedDeepSeek = true
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            let reading = try XCTUnwrap(DeepSeekDisplay.readings(connection: connection, now: Date()).first)
            let details = BalanceDetailsView(model: model, now: Date(), compact: true, openMainWindow: {})
            let summary = details.currencySummary(reading)
            let summaryHost = NSHostingView(rootView: summary.frame(width: 324))
            XCTAssertLessThanOrEqual(summaryHost.fittingSize.height, 160,
                "The first currency chart and disclaimer must fit the notch body without scrolling")
            let headerHost = NSHostingView(rootView: details.header.frame(width: 324))
            let footerHost = NSHostingView(rootView: details.footer.frame(width: 324))
            XCTAssertLessThanOrEqual(summaryHost.fittingSize.height + headerHost.fittingSize.height
                + footerHost.fittingSize.height + 16, 236,
                "Shared chrome and the full first currency must fit the notch's inner height")
            let expanded = BalanceDetailsView(model: model, now: Date(), openMainWindow: {})
            let expandedSummary = NSHostingView(rootView: expanded.currencySummary(reading).frame(width: 348))
            XCTAssertLessThanOrEqual(expandedSummary.fittingSize.height
                + headerHost.fittingSize.height + footerHost.fittingSize.height + 16, 312,
                "The selected balance-and-trend layout must fit the existing expanded panel")
            let views: [(String, AnyView, CGSize)] = [
                ("overview", AnyView(ScrollView { DeepSeekOverview(connection: connection, language: language, now: Date(), days: .constant(1)).padding() }), .init(width: 620, height: 650)),
                ("menu", AnyView(MenuBarQuotaView(model: model, openSettings: {})), .init(width: 340, height: 470)),
                ("widget", AnyView(FloatingWidgetView(model: model)), .init(width: 352, height: 440)),
                ("bubble", AnyView(BubbleWidgetView(model: model, isExpanded: false, tabEdge: nil, onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})), BubbleWidgetPlacement.bubbleSize),
                ("edge", AnyView(BubbleWidgetView(model: model, isExpanded: false, tabEdge: .left, onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})), BubbleWidgetPlacement.tabSize),
                ("expanded", AnyView(BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil, onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})), BubbleWidgetPlacement.expandedSize),
                ("notch", AnyView(NotchStatusView(model: model)), .init(width: 150, height: 60)),
                ("details", AnyView(NotchStatusView(model: model, isExpanded: true)), .init(width: 360, height: 264))
            ]
            for (name, view, size) in views {
                let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height)
                    .background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .light))
                let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = NSAppearance(named: .aqua)
                window.contentView = host
                host.frame = CGRect(origin: .zero, size: size)
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(100))
                XCTAssertLessThanOrEqual(host.fittingSize.width, size.width + 1, name)
                XCTAssertLessThanOrEqual(host.fittingSize.height, size.height + 1, name)
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to:
                    URL(fileURLWithPath: output).appendingPathComponent("deepseek-\(name)-\(language.rawValue).png"))
                window.close()
            }
        }
    }

    func testManualRefreshImmediatelyReadsAgainAndReportsUnchangedBalance() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let loader = CountingDeepSeekStub()
        let connection = DeepSeekConnection(store: InMemoryCredentialStore(),
            client: DeepSeekBalanceClient(loader: loader),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        await connection.connect(key: "synthetic")
        let firstRead = try XCTUnwrap(connection.observedAt)
        await connection.refresh()
        let count = await loader.count
        XCTAssertEqual(count, 2)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(connection.observedAt), firstRead)
        XCTAssertEqual(connection.refreshOutcome, .unchanged)
        XCTAssertFalse(connection.isBusy)
    }

    func testHistoryRangeCoversSelectedIntervalAndFreshReading() {
        let now = Date(), newReading = now.addingTimeInterval(2)
        for days in [1, 7, 30] {
            let range = DeepSeekHistoryWindow.range(now: now, lastObservedAt: newReading, days: days)
            XCTAssertEqual(range.upperBound, newReading)
            XCTAssertEqual(range.upperBound.timeIntervalSince(range.lowerBound), Double(days) * 86400)
            let ticks = DeepSeekHistoryWindow.ticks(in: range)
            XCTAssertEqual(ticks.count, 5)
            XCTAssertEqual(ticks.first, range.lowerBound)
            XCTAssertEqual(ticks.last, range.upperBound)
        }
    }

    func testCompactReadingShowsStaleOnErrorOrAge() {
        let now = Date()
        XCTAssertFalse(DeepSeekReadingStatus.isStale(observedAt: now, hasError: false, now: now))
        XCTAssertTrue(DeepSeekReadingStatus.isStale(observedAt: now, hasError: true, now: now))
        XCTAssertTrue(DeepSeekReadingStatus.isStale(observedAt: now.addingTimeInterval(-301), hasError: false, now: now))
        XCTAssertTrue(DeepSeekReadingStatus.isStale(observedAt: nil, hasError: false, now: now))
    }

    func testConnectStoresOnlyAfterSuccessfulReadAndDisconnectRemovesOnlyDeepSeek() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let history = DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json"))
        let store = InMemoryCredentialStore()
        let codexKey = CredentialKey(providerId: "codex-oauth", name: "test")
        try await store.saveCredential("keep", for: codexKey)
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: DeepSeekStub(status: 200)), historyStore: history)
        await connection.connect(key: "synthetic")
        XCTAssertTrue(connection.isConnected)
        XCTAssertEqual(connection.snapshot?.balances.first?.currency, "CNY")
        let saved = try await store.loadCredential(for: DeepSeekConnection.credentialKey)
        XCTAssertEqual(try saved.flatMap { try DeepSeekConnection.Credential.parse($0) }?.key, "synthetic")
        await connection.disconnect()
        XCTAssertFalse(connection.isConnected)
        let old = try await store.loadCredential(for: codexKey)
        let removed = try await store.loadCredential(for: DeepSeekConnection.credentialKey)
        XCTAssertEqual(old, "keep")
        XCTAssertNil(removed)
    }

    func testFailedRefreshKeepsLastReadingAndMarksError() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let loader = MutableDeepSeekStub()
        let connection = DeepSeekConnection(store: InMemoryCredentialStore(), client: DeepSeekBalanceClient(loader: loader), historyStore: DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json")))
        await connection.connect(key: "synthetic")
        let before = connection.snapshot
        await loader.setStatus(429)
        await connection.refresh()
        XCTAssertTrue(connection.isConnected)
        XCTAssertEqual(connection.snapshot, before)
        XCTAssertEqual(connection.error, .rateLimited)
    }

    func testRefreshClearsPreviousBalanceWhenStoredConnectionChangesAndReadFails() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = InMemoryCredentialStore(), loader = MutableDeepSeekStub()
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: loader), historyStore: DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json")))
        await connection.connect(key: "first")
        XCTAssertNotNil(connection.snapshot)
        let replacement = DeepSeekConnection.Credential(key: "second", connectionID: UUID())
        try await store.saveCredential(try replacement.encode(), for: DeepSeekConnection.credentialKey)
        await loader.setStatus(401)
        await connection.refresh()
        XCTAssertTrue(connection.isConnected)
        XCTAssertNil(connection.snapshot, "Never display the previous connection balance under a different identity")
        XCTAssertNil(connection.observedAt)
        XCTAssertTrue(connection.history.isEmpty)
        XCTAssertEqual(connection.error, .unauthorized)
    }

    func testMonitoringRefreshesWithoutOpeningAViewAndStops() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = InMemoryCredentialStore()
        try await store.saveCredential("legacy", for: DeepSeekConnection.credentialKey)
        let loader = CountingDeepSeekStub()
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: loader), historyStore: DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json")))
        let model = ReadyCheckAppModel(credentialStore: store, deepSeekConnection: connection, deepSeekAlertStore: DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json")), quotaNotificationService: QuotaNotificationService(client: DeepSeekSilentNotifications(), verificationDelays: []))
        model.startDeepSeekMonitoring()
        model.startDeepSeekMonitoring()
        defer { model.stopDeepSeekMonitoring() }
        let deadline = Date().addingTimeInterval(2)
        while connection.snapshot == nil && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertNotNil(connection.snapshot)
        let count = await loader.count
        XCTAssertEqual(count, 1)
        model.stopDeepSeekMonitoring()
    }

    func testReplacementIsolatesHistoryAndSameKeyRetainsIdentity() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let history = DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json"))
        let store = InMemoryCredentialStore()
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: DeepSeekStub(status: 200)), historyStore: history)
        await connection.connect(key: "first")
        let first = try XCTUnwrap(connection.history.first?.connectionID)
        await connection.connect(key: "first")
        XCTAssertEqual(connection.history.first?.connectionID, first)
        await connection.connect(key: "second")
        let second = try XCTUnwrap(connection.history.first?.connectionID)
        XCTAssertNotEqual(first, second)
        let savedFirstHistory = try await history.load(connectionID: first)
        XCTAssertEqual(savedFirstHistory.count, 1)
        let bytes = try Data(contentsOf: dir.appendingPathComponent("history.json"))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("first"))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("second"))
    }

    func testLegacyKeyMigratesOnlyAfterSuccessfulRead() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = InMemoryCredentialStore()
        try await store.saveCredential("legacy", for: DeepSeekConnection.credentialKey)
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: DeepSeekStub(status: 200)), historyStore: DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json")))
        await connection.refresh()
        let raw = try await store.loadCredential(for: DeepSeekConnection.credentialKey)
        XCTAssertEqual(try raw.flatMap { try DeepSeekConnection.Credential.parse($0) }?.key, "legacy")
        XCTAssertEqual(connection.history.count, 1)
    }

    func testExplicitCredentialRetryRecoversWithoutChangingConnectionIdentity() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let credential = DeepSeekConnection.Credential(key: "synthetic", connectionID: UUID())
        let store = RetryCredentialStore(raw: try credential.encode())
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: DeepSeekStub(status: 200)),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        await connection.refresh()
        XCTAssertTrue(connection.credentialError)
        await connection.retryCredentialRead()
        XCTAssertFalse(connection.credentialError)
        XCTAssertTrue(connection.isConnected)
        XCTAssertEqual(connection.connectionID, credential.connectionID)
        let raw = try await store.loadCredential(for: DeepSeekConnection.credentialKey)
        XCTAssertEqual(raw, try credential.encode())
    }

    func testRejectedReplacementPreservesExistingKeyAndSnapshot() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let history = DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json"))
        let store = InMemoryCredentialStore()
        try await store.saveCredential("old", for: DeepSeekConnection.credentialKey)
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: DeepSeekStub(status: 401)), historyStore: history)
        await connection.connect(key: "new")
        let saved = try await store.loadCredential(for: DeepSeekConnection.credentialKey)
        XCTAssertEqual(saved, "old")
        XCTAssertEqual(connection.connectError, .unauthorized)
        XCTAssertNil(connection.error)
    }
}

private struct DeepSeekStub: HTTPDataLoading {
    let status: Int
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data = Data(#"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"5","granted_balance":"1","topped_up_balance":"4"}]}"#.utf8)
        return (data, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

private actor MutableDeepSeekStub: HTTPDataLoading {
    private var status = 200
    func setStatus(_ value: Int) { status = value }
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data = Data(#"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"5","granted_balance":"1","topped_up_balance":"4"}]}"#.utf8)
        return (data, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

private actor CountingDeepSeekStub: HTTPDataLoading {
    private(set) var count = 0
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        count += 1
        let data = Data(#"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"5","granted_balance":"1","topped_up_balance":"4"}]}"#.utf8)
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

@MainActor private final class DeepSeekSilentNotifications: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration { .init(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none) }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

private actor RetryCredentialStore: CredentialStore {
    let raw: String
    private var blocked = true
    init(raw: String) { self.raw = raw }
    func loadCredential(for key: CredentialKey) throws -> String? {
        if blocked { blocked = false; throw KeychainCredentialStoreError.unexpectedStatus(-25308) }
        return raw
    }
    func saveCredential(_ credential: String, for key: CredentialKey) { }
    func removeCredential(for key: CredentialKey) { }
}

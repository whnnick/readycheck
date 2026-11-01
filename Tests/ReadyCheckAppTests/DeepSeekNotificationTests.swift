import Foundation
import UserNotifications
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor final class DeepSeekNotificationTests: XCTestCase {
    func testAcceptedUnverifiedAlertDoesNotRepeatAndOmitsBalance() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json")), id = UUID()
        try await store.configure(connectionID: id, currency: "CNY", threshold: 10, enabled: true)
        let candidate = try await store.evaluate(connectionID: id, currency: "CNY", total: 2)
        let alert = try XCTUnwrap(candidate)
        let client = DeepSeekNotificationStub(verified: false)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let result = await service.deliverDeepSeekBalanceAlert(alert, localization: .init(language: .zhCN), alertStore: store)
        XCTAssertEqual(result, .submitted)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertFalse(client.requests[0].content.body.contains("2"))
        let reloaded = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json"))
        let next = try await reloaded.evaluate(connectionID: id, currency: "CNY", total: 1)
        XCTAssertNil(next)
        let rules = try await reloaded.rules(connectionID: id)
        XCTAssertNotNil(rules.first?.lastSubmittedAt)
        XCTAssertNil(rules.first?.lastDeliveredAt)
    }

    func testEnablingThresholdConnectsFreshReadToVerifiedAlertOnce() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let credentials = InMemoryCredentialStore()
        let connection = DeepSeekConnection(store: credentials, client: DeepSeekBalanceClient(loader: DeepSeekAlertHTTPStub()), historyStore: DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json")))
        let alerts = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json"))
        let client = DeepSeekNotificationStub(verified: true)
        let model = ReadyCheckAppModel(credentialStore: credentials, deepSeekConnection: connection, deepSeekAlertStore: alerts, quotaNotificationService: QuotaNotificationService(client: client, verificationDelays: [.zero]))
        await connection.connect(key: "synthetic")
        XCTAssertEqual(client.requests.count, 0, "Alerts start disabled")
        await model.configureDeepSeekAlert(currency: "CNY", threshold: 10, enabled: true)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(model.deepSeekAlertRules.first?.lastDeliveredAt)
        await connection.refresh()
        XCTAssertEqual(client.requests.count, 1, "The same low-balance cycle must not repeat")
    }

    func testDisabledNotificationPermissionDoesNotConsumeAlert() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json")), id = UUID()
        try await store.configure(connectionID: id, currency: "CNY", threshold: 10, enabled: true)
        let pending = try await store.evaluate(connectionID: id, currency: "CNY", total: 2)
        let alert = try XCTUnwrap(pending)
        let client = DeepSeekNotificationStub(verified: false, authorized: false)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        let result = await service.deliverDeepSeekBalanceAlert(alert, localization: .init(language: .zhCN), alertStore: store)
        XCTAssertEqual(result, .notSubmitted)
        XCTAssertTrue(client.requests.isEmpty)
        let retry = try await store.evaluate(connectionID: id, currency: "CNY", total: 2)
        XCTAssertEqual(retry?.id, alert.id)
    }

    func testVerifiedAlertAndNotificationClickUseDeepSeekRoute() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json")), id = UUID()
        try await store.configure(connectionID: id, currency: "USD", threshold: 10, enabled: true)
        let candidate = try await store.evaluate(connectionID: id, currency: "USD", total: 2)
        let alert = try XCTUnwrap(candidate)
        let client = DeepSeekNotificationStub(verified: true)
        let service = QuotaNotificationService(client: client, verificationDelays: [.zero])
        var deepSeekOpened = false, normalOpened = false
        service.onOpenDeepSeekNotification = { deepSeekOpened = true }
        service.onOpenNotification = { normalOpened = true }
        let result = await service.deliverDeepSeekBalanceAlert(alert, localization: .init(language: .enUS), alertStore: store)
        XCTAssertEqual(result, .delivered)
        let rules = try await store.rules(connectionID: id)
        XCTAssertNotNil(rules.first?.lastDeliveredAt)
        service.handleNotificationResponse(actionIdentifier: UNNotificationDismissActionIdentifier, notificationIdentifier: client.requests[0].identifier)
        XCTAssertFalse(deepSeekOpened)
        service.handleNotificationResponse(actionIdentifier: UNNotificationDefaultActionIdentifier, notificationIdentifier: client.requests[0].identifier)
        XCTAssertTrue(deepSeekOpened)
        XCTAssertFalse(normalOpened)
    }
}

@MainActor private final class DeepSeekNotificationStub: NotificationCenterClient {
    let verified: Bool
    let authorized: Bool
    var requests: [UNNotificationRequest] = []
    init(verified: Bool, authorized: Bool = true) { self.verified = verified; self.authorized = authorized }
    func configuration() async -> NotificationCenterConfiguration { .init(authorizationStatus: authorized ? .authorized : .denied, alertSetting: authorized ? .enabled : .disabled, alertStyle: .banner) }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func add(_ request: UNNotificationRequest) async throws { requests.append(request) }
    func deliveredIdentifiers() async -> Set<String> { verified ? Set(requests.map(\.identifier)) : [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

private struct DeepSeekAlertHTTPStub: HTTPDataLoading {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data = Data(#"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"5","granted_balance":"1","topped_up_balance":"4"}]}"#.utf8)
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

final class ServicePresentationTests: XCTestCase {
    func testCurrentServicesDescribeAccessAndReadoutIndependently() {
        XCTAssertEqual(ServiceSettingsTarget.codex.presentation.connectionMethod, .oauth)
        XCTAssertEqual(ServiceSettingsTarget.codex.presentation.readoutKind, .quota)
        XCTAssertEqual(ServiceSettingsTarget.deepSeek.presentation.connectionMethod, .apiKey)
        XCTAssertEqual(ServiceSettingsTarget.deepSeek.presentation.readoutKind, .balance)
        let apiQuota = ServicePresentation(connectionMethod: .apiKey, readoutKind: .quota)
        let oauthBalance = ServicePresentation(connectionMethod: .oauth, readoutKind: .balance)
        XCTAssertEqual(apiQuota.readoutKind, .quota)
        XCTAssertEqual(oauthBalance.readoutKind, .balance)
    }

    func testBalanceReadoutPreservesTinyAmountsAndUnknownBins() {
        let reading = BalanceSurfaceReading(currency: "CNY", total: 12, granted: 2, toppedUp: 10,
            values: [nil, 0, Decimal(string: "0.00001")], observedAt: nil, isStale: false)
        XCTAssertEqual(reading.observedDecrease, Decimal(string: "0.00001"))
        XCTAssertEqual(reading.values.count, 3)
        XCTAssertNil(reading.values[0])
        XCTAssertEqual(reading.values[1], 0)
        let unknown = BalanceSurfaceReading(currency: "USD", total: 3, granted: nil, toppedUp: nil,
            values: [nil, nil], observedAt: nil, isStale: true)
        XCTAssertNil(unknown.observedDecrease)
        XCTAssertNotEqual(reading.currency, unknown.currency)
    }

    @MainActor
    func testCompactReadoutNeverLabelsFailedOrDisconnectedStateAsCollecting() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = InMemoryCredentialStore(), loader = PresentationBalanceLoader()
        let connection = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: loader),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        let model = ReadyCheckAppModel(credentialStore: store, deepSeekConnection: connection,
            quotaNotificationService: QuotaNotificationService(client: ClaritySilentNotifications(), verificationDelays: []))
        let originalService = model.selectedDeepSeek, originalLanguage = model.language
        defer { model.selectedDeepSeek = originalService; model.language = originalLanguage }
        model.selectedDeepSeek = true
        for language in [AppLanguage.zhCN, .enUS] {
            model.language = language
            XCTAssertEqual(ServiceCompactReadout(model: model, now: Date()).secondaryText,
                language == .zhCN ? "连接未就绪" : "Connection not ready")
        }
        await connection.connect(key: "synthetic")
        XCTAssertEqual(ServiceCompactReadout(model: model, now: Date()).secondaryText, "Collecting readings")
        await loader.fail()
        await connection.refresh()
        let failed = ServiceCompactReadout(model: model, now: Date())
        XCTAssertEqual(failed.primaryText, "—")
        XCTAssertEqual(failed.secondaryText, "Update failed")
        model.selectedDeepSeek = false
        XCTAssertEqual(ServiceCompactReadout(model: model, now: Date()).secondaryText, "Reset unconfirmed")
    }

    @MainActor
    func testBalanceAdapterKeepsCurrenciesAndStaleFailureSeparate() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let loader = PresentationBalanceLoader()
        let connection = DeepSeekConnection(store: InMemoryCredentialStore(),
            client: DeepSeekBalanceClient(loader: loader),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        await connection.connect(key: "synthetic")
        let now = Date()
        let readings = DeepSeekDisplay.readings(connection: connection, now: now)
        XCTAssertEqual(readings.map(\.currency), ["CNY", "USD"])
        XCTAssertEqual(readings.map(\.total), [12, 3])
        XCTAssertTrue(readings.allSatisfy { $0.observedDecrease == nil && !$0.isStale })
        XCTAssertTrue(DeepSeekDisplay.readings(connection: connection, now: now.addingTimeInterval(301)).allSatisfy(\.isStale))
        await loader.fail()
        await connection.refresh()
        let failed = DeepSeekDisplay.readings(connection: connection, now: Date())
        XCTAssertEqual(failed.map(\.total), [12, 3], "A failed request keeps the last balances")
        XCTAssertTrue(failed.allSatisfy(\.isStale), "A failed request is never presented as a fresh zero reading")
        XCTAssertEqual(connection.refreshOutcome, .failed)
    }
}

private actor PresentationBalanceLoader: HTTPDataLoading {
    private var status = 200
    func fail() { status = 429 }
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let body = #"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"12","granted_balance":"2","topped_up_balance":"10"},{"currency":"USD","total_balance":"3","granted_balance":"0","topped_up_balance":"3"}]}"#
        return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

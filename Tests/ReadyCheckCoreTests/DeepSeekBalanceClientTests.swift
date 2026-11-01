import Foundation
import XCTest
@testable import ReadyCheckCore

final class DeepSeekBalanceClientTests: XCTestCase {
    func testReadsSeparateCurrenciesAndUsesOnlyOfficialReadEndpoint() async throws {
        let loader = BalanceTestLoader(status: 200, body: #"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"110.00","granted_balance":"10.00","topped_up_balance":"100.00"},{"currency":"USD","total_balance":"0.00","granted_balance":"0","topped_up_balance":"0"}]}"#)
        let result = try await DeepSeekBalanceClient(loader: loader).fetch(apiKey: "example-key")
        XCTAssertTrue(result.isAvailable)
        XCTAssertEqual(result.balances.map(\.currency), ["CNY", "USD"])
        XCTAssertEqual(result.balances[0].total, Decimal(110))
        XCTAssertEqual(result.balances[0].granted, Decimal(10))
        XCTAssertEqual(result.balances[0].toppedUp, Decimal(100))
        XCTAssertEqual(result.balances[1].granted, Decimal(0))
        XCTAssertEqual(result.balances[1].toppedUp, Decimal(0))
        let request = await loader.request
        XCTAssertEqual(request?.url?.absoluteString, "https://api.deepseek.com/user/balance")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer example-key")
    }

    func testRejectsInvalidOrNegativeAmountsAndMissingFields() async throws {
        for amount in ["-1", "1x", "NaN", ""] {
            let body = "{\"is_available\":true,\"balance_infos\":[{\"currency\":\"CNY\",\"total_balance\":\"\(amount)\",\"granted_balance\":\"0\",\"topped_up_balance\":\"0\"}]}"
            do { _ = try await DeepSeekBalanceClient(loader: BalanceTestLoader(status: 200, body: body)).fetch(apiKey: "x"); XCTFail("accepted invalid amount") }
            catch { XCTAssertEqual(error as? DeepSeekBalanceError, .invalidResponse) }
        }
        do { _ = try await DeepSeekBalanceClient(loader: BalanceTestLoader(status: 200, body: #"{"is_available":true}"#)).fetch(apiKey: "x"); XCTFail("accepted missing field") }
        catch { XCTAssertEqual(error as? DeepSeekBalanceError, .invalidResponse) }
    }

    func testMapsAuthAndRateLimitWithoutReturningResponseBody() async throws {
        for (status, expected) in [(401, DeepSeekBalanceError.unauthorized), (429, .rateLimited), (500, .server)] {
            do { _ = try await DeepSeekBalanceClient(loader: BalanceTestLoader(status: status, body: "secret response")).fetch(apiKey: "x"); XCTFail("accepted error") }
            catch { XCTAssertEqual(error as? DeepSeekBalanceError, expected) }
        }
    }
}

private actor BalanceTestLoader: HTTPDataLoading {
    let status: Int
    let body: String
    var request: URLRequest?
    init(status: Int, body: String) { self.status = status; self.body = body }
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

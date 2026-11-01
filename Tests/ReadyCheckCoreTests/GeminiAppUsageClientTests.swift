import Foundation
import XCTest
@testable import ReadyCheckCore

final class GeminiAppUsageClientTests: XCTestCase {
    func testUsesOnlyFixedGoogleHostAndExplicitSession() async throws {
        let loader = GeminiFixtureLoader(status: 200, body: #"[{"data":{"viewer":{"rpcs":{"getUsageInfo":{"pools":[{"poolType":"GXU_WEEKLY","percentageUsed":0.25}]}}}}}]"#)
        let reading = try await GeminiAppUsageClient(loader: loader).fetch(sessionCookie: "example_session=synthetic")
        XCTAssertEqual(reading.weekly?.usedFraction, 0.25)
        let request = await loader.request
        XCTAssertEqual(request?.url?.host, "gemini.google.com")
        XCTAssertEqual(request?.url?.scheme, "https")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Cookie"), "example_session=synthetic")
        XCTAssertFalse(request?.url?.absoluteString.contains("synthetic") ?? true)
        XCTAssertEqual(request?.httpShouldHandleCookies, false)
    }

    func testRejectsBadSessionAndClassifiesHTTPWithoutEchoingBody() async throws {
        let loader = GeminiFixtureLoader(status: 403, body: "private response")
        for value in ["", "a=b\nInjected: value", "a=b\rInjected: value", "a=b\0", "a=" + String(repeating: "x", count: 16_384)] {
            do { _ = try await GeminiAppUsageClient(loader: loader).fetch(sessionCookie: value); XCTFail("invalid cookie accepted") }
            catch { XCTAssertEqual(error as? GeminiAppUsageClient.Failure, .invalidSession) }
        }
        do { _ = try await GeminiAppUsageClient(loader: loader).fetch(sessionCookie: "a=b"); XCTFail("403 accepted") }
        catch { XCTAssertEqual(error as? GeminiAppUsageClient.Failure, .unauthorized) }
        let redirect = GeminiFixtureLoader(status: 302, body: "")
        do { _ = try await GeminiAppUsageClient(loader: redirect).fetch(sessionCookie: "a=b"); XCTFail("redirect accepted") }
        catch { XCTAssertEqual(error as? GeminiAppUsageClient.Failure, .unauthorized) }
        let foreign = GeminiFixtureLoader(status: 200, body: "", responseURL: URL(string: "https://example.com/")!)
        do { _ = try await GeminiAppUsageClient(loader: foreign).fetch(sessionCookie: "a=b"); XCTFail("foreign response accepted") }
        catch { XCTAssertEqual(error as? GeminiAppUsageClient.Failure, .invalidResponse) }
    }
}

private actor GeminiFixtureLoader: HTTPDataLoading {
    let status: Int
    let body: String
    let responseURL: URL?
    private(set) var request: URLRequest?
    init(status: Int, body: String, responseURL: URL? = nil) { self.status = status; self.body = body; self.responseURL = responseURL }
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        return (Data(body.utf8), HTTPURLResponse(url: responseURL ?? request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

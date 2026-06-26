import XCTest
@testable import ReadyCheckCore

final class CodexOAuthQuotaProviderTests: XCTestCase {
    func testProviderReturnsAuthorizationRequiredWithoutStoredToken() async throws {
        let provider = CodexOAuthQuotaProvider(
            credentialStore: InMemoryCredentialStore(),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        XCTAssertEqual(snapshot.providerId, "codex-oauth")
        XCTAssertEqual(snapshot.displayName, "Codex")
        XCTAssertEqual(snapshot.status, .unavailable)
        XCTAssertEqual(snapshot.source, .oauthAPI)
        XCTAssertEqual(snapshot.windows, [])
        XCTAssertEqual(snapshot.errors, ["quota.error.oauthRequired"])
        XCTAssertFalse(snapshot.canShowPercentages(now: Date(timeIntervalSince1970: 1_000)))
    }

    func testProviderReturnsCalibrationRequiredWithStoredTokenButNoQuotaEndpoint() async throws {
        let credentialStore = InMemoryCredentialStore()
        let tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        try await tokenStore.saveToken(
            CodexOAuthToken(
                accessToken: "access",
                refreshToken: "refresh",
                idToken: nil,
                tokenType: "Bearer",
                expiresAt: Date(timeIntervalSince1970: 4_600),
                accountID: nil,
                email: nil
            )
        )
        let provider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            quotaEndpoint: nil,
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        XCTAssertEqual(snapshot.status, .unavailable)
        XCTAssertEqual(snapshot.errors, ["quota.error.endpointCalibrationRequired"])
        XCTAssertFalse(snapshot.canShowPercentages(now: Date(timeIntervalSince1970: 1_000)))
    }

    func testProviderFetchesCodexUsageEndpointAndReturnsWindows() async throws {
        let credentialStore = InMemoryCredentialStore()
        let tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        try await tokenStore.saveToken(
            CodexOAuthToken(
                accessToken: "access",
                refreshToken: "refresh",
                idToken: nil,
                tokenType: "Bearer",
                expiresAt: Date(timeIntervalSince1970: 4_600),
                accountID: "account-123",
                email: nil
            )
        )
        let loader = QuotaRecordingHTTPDataLoader(
            data: Data(
                """
                {
                  "rate_limit": {
                    "primary_window": {
                      "used_percent": 20,
                      "limit_window_seconds": 18000,
                      "reset_at": 4600
                    },
                    "secondary_window": {
                      "used_percent": 30,
                      "limit_window_seconds": 604800,
                      "reset_at": 605800
                    }
                  }
                }
                """.utf8
            ),
            statusCode: 200
        )
        let endpoint = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/usage"))
        let provider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            quotaEndpoint: endpoint,
            quotaClient: CodexQuotaHTTPClient(loader: loader),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        let request = try await loader.recordedRequest()
        XCTAssertEqual(request.url, endpoint)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access")
        XCTAssertEqual(request.value(forHTTPHeaderField: "ChatGPT-Account-Id"), "account-123")
        XCTAssertEqual(snapshot.status, .available)
        XCTAssertEqual(snapshot.source, .oauthAPI)
        XCTAssertEqual(snapshot.errors, [])
        XCTAssertEqual(snapshot.windows.map(\.labelKey), ["quota.window.codex.5h", "quota.window.codex.7d"])
        XCTAssertEqual(snapshot.windows[0].remainingRatio, 0.8)
    }

    func testProviderFailsClosedWithoutAccountID() async throws {
        let credentialStore = InMemoryCredentialStore()
        let tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        try await tokenStore.saveToken(
            CodexOAuthToken(
                accessToken: "not-a-jwt",
                refreshToken: "refresh",
                idToken: nil,
                tokenType: "Bearer",
                expiresAt: Date(timeIntervalSince1970: 4_600),
                accountID: nil,
                email: nil
            )
        )
        let loader = QuotaRecordingHTTPDataLoader(data: Data(), statusCode: 200)
        let provider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            quotaClient: CodexQuotaHTTPClient(loader: loader),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))
        let request = await loader.recordedRequestIfPresent()

        XCTAssertNil(request)
        XCTAssertEqual(snapshot.status, .unavailable)
        XCTAssertEqual(snapshot.errors, ["quota.error.accountIdUnavailable"])
        XCTAssertEqual(snapshot.windows, [])
    }
}

private actor QuotaRecordingHTTPDataLoader: HTTPDataLoading {
    private let data: Data
    private let statusCode: Int
    private var request: URLRequest?

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func recordedRequest() throws -> URLRequest {
        try XCTUnwrap(request)
    }

    func recordedRequestIfPresent() -> URLRequest? {
        request
    }
}

import XCTest
@testable import ReadyCheckCore

final class CodexOAuthTests: XCTestCase {
    func testAuthorizationURLUsesPKCEAndCodexOAuthParameters() throws {
        let client = CodexOAuthClient()
        let url = try client.authorizationURL(
            state: "state-123",
            pkce: OAuthPKCECodes(verifier: "verifier", challenge: "challenge")
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = queryDictionary(from: components)

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "auth.openai.com")
        XCTAssertEqual(components.path, "/oauth/authorize")
        XCTAssertEqual(query["client_id"], "app_EMoamEEZ73f0CkXaXp7hrann")
        XCTAssertEqual(query["response_type"], "code")
        XCTAssertEqual(query["redirect_uri"], "http://localhost:1455/auth/callback")
        XCTAssertEqual(query["scope"], "openid email profile offline_access")
        XCTAssertEqual(query["state"], "state-123")
        XCTAssertEqual(query["code_challenge"], "challenge")
        XCTAssertEqual(query["code_challenge_method"], "S256")
        XCTAssertEqual(query["prompt"], "login")
        XCTAssertEqual(query["id_token_add_organizations"], "true")
        XCTAssertEqual(query["codex_cli_simplified_flow"], "true")
    }

    func testCallbackParserAcceptsManualCallbackURL() throws {
        let callback = try XCTUnwrap(
            OAuthCallbackParser.parse("http://localhost:1455/auth/callback?code=abc&state=state-123")
        )

        XCTAssertEqual(callback.code, "abc")
        XCTAssertEqual(callback.state, "state-123")
        XCTAssertNil(callback.error)
    }

    func testLoopbackCallbackServerAcceptsBrowserCallback() async throws {
        let port: UInt16 = 18455
        let server = OAuthLoopbackCallbackServer(port: port)
        defer {
            server.stop()
        }

        let ready = expectation(description: "loopback server is ready")
        let received = expectation(description: "callback is received")
        final class CallbackBox: @unchecked Sendable {
            var value: String?
        }
        let callback = CallbackBox()

        try server.start(
            onReady: {
                ready.fulfill()
            },
            onCallback: { callbackURL in
                callback.value = callbackURL
                received.fulfill()
            },
            onFailure: { error in
                XCTFail("Unexpected loopback failure: \(error)")
            }
        )

        await fulfillment(of: [ready], timeout: 2)

        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(port)/auth/callback?code=abc&state=state-123"))
        let (_, response) = try await URLSession.shared.data(from: url)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        await fulfillment(of: [received], timeout: 2)
        XCTAssertEqual(callback.value, "http://localhost:\(port)/auth/callback?code=abc&state=state-123")
    }

    func testTokenExchangePostsFormToOAuthTokenEndpoint() async throws {
        let loader = RecordingHTTPDataLoader(
            data: """
            {
              "access_token": "access",
              "refresh_token": "refresh",
              "id_token": "id",
              "token_type": "Bearer",
              "expires_in": 3600
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let client = CodexOAuthClient(loader: loader, now: { Date(timeIntervalSince1970: 1_000) })

        let token = try await client.exchangeCode(
            "code-123",
            pkce: OAuthPKCECodes(verifier: "verifier", challenge: "challenge")
        )

        let request = try await loader.recordedRequest()
        XCTAssertEqual(request.url?.absoluteString, "https://auth.openai.com/oauth/token")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(String(data: try XCTUnwrap(request.httpBody), encoding: .utf8), "client_id=app_EMoamEEZ73f0CkXaXp7hrann&code=code-123&code_verifier=verifier&grant_type=authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A1455%2Fauth%2Fcallback")
        XCTAssertEqual(token.accessToken, "access")
        XCTAssertEqual(token.refreshToken, "refresh")
        XCTAssertEqual(token.expiresAt, Date(timeIntervalSince1970: 4_600))
    }

    func testAuthorizerCompletesCallbackAndStoresToken() async throws {
        let loader = RecordingHTTPDataLoader(
            data: """
            {
              "access_token": "access",
              "refresh_token": "refresh",
              "id_token": "id",
              "token_type": "Bearer",
              "expires_in": 3600
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let credentialStore = InMemoryCredentialStore()
        let tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        let client = CodexOAuthClient(loader: loader, now: { Date(timeIntervalSince1970: 1_000) })
        let authorizer = CodexOAuthAuthorizer(client: client, tokenStore: tokenStore)
        let session = CodexOAuthSession(
            state: "state-123",
            pkce: OAuthPKCECodes(verifier: "verifier", challenge: "challenge"),
            authorizationURL: URL(string: "https://auth.openai.com/oauth/authorize")!
        )

        let token = try await authorizer.complete(
            callbackURL: "http://localhost:1455/auth/callback?code=code-123&state=state-123",
            session: session
        )

        XCTAssertEqual(token.accessToken, "access")
        let storedToken = try await tokenStore.loadToken()
        XCTAssertEqual(storedToken, token)
    }

    func testAuthorizerRejectsCallbackStateMismatchBeforeNetwork() async throws {
        let loader = RecordingHTTPDataLoader(data: Data(), statusCode: 200)
        let credentialStore = InMemoryCredentialStore()
        let tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        let client = CodexOAuthClient(loader: loader)
        let authorizer = CodexOAuthAuthorizer(client: client, tokenStore: tokenStore)
        let session = CodexOAuthSession(
            state: "expected-state",
            pkce: OAuthPKCECodes(verifier: "verifier", challenge: "challenge"),
            authorizationURL: URL(string: "https://auth.openai.com/oauth/authorize")!
        )

        do {
            _ = try await authorizer.complete(
                callbackURL: "http://localhost:1455/auth/callback?code=code-123&state=wrong-state",
                session: session
            )
            XCTFail("Expected state mismatch")
        } catch {
            XCTAssertEqual(error as? CodexOAuthError, .stateMismatch)
        }

        let request = await loader.recordedRequestIfPresent()
        let storedToken = try await tokenStore.loadToken()
        XCTAssertNil(request)
        XCTAssertNil(storedToken)
    }

    func testQuotaHTTPClientRejectsInferenceEndpointBeforeNetwork() async throws {
        let loader = RecordingHTTPDataLoader(data: Data(), statusCode: 200)
        let client = CodexQuotaHTTPClient(loader: loader)
        let endpoint = try XCTUnwrap(URL(string: "https://api.openai.com/v1/responses"))

        do {
            _ = try await client.fetchReadOnlyPayload(from: endpoint, accessToken: "access")
            XCTFail("Expected unsafe endpoint rejection")
        } catch {
            XCTAssertEqual(error as? CodexQuotaHTTPClientError, .unsafeRefreshEndpoint)
        }

        let request = await loader.recordedRequestIfPresent()
        XCTAssertNil(request)
    }

    func testQuotaHTTPClientUsesGETForAllowedUsageEndpoint() async throws {
        let loader = RecordingHTTPDataLoader(data: Data("{}".utf8), statusCode: 200)
        let client = CodexQuotaHTTPClient(loader: loader)
        let endpoint = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/usage/completions"))

        let payload = try await client.fetchReadOnlyPayload(
            from: endpoint,
            accessToken: "access",
            accountID: "account-123"
        )

        let request = try await loader.recordedRequest()
        XCTAssertEqual(payload, Data("{}".utf8))
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access")
        XCTAssertEqual(request.value(forHTTPHeaderField: "ChatGPT-Account-Id"), "account-123")
    }

    func testTokenStoreRoundTripsWithoutProviderConfiguration() async throws {
        let store = InMemoryCredentialStore()
        let tokenStore = CodexOAuthTokenStore(credentialStore: store)
        let token = CodexOAuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            idToken: nil,
            tokenType: "Bearer",
            expiresAt: Date(timeIntervalSince1970: 2_000),
            accountID: nil,
            email: "user@example.com"
        )

        try await tokenStore.saveToken(token)

        let loaded = try await tokenStore.loadToken()
        XCTAssertEqual(loaded, token)
    }

    func testTokenLoginEmailTrimsEmail() {
        let token = CodexOAuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            idToken: nil,
            tokenType: "Bearer",
            expiresAt: Date(timeIntervalSince1970: 2_000),
            accountID: "account-123",
            email: " user@example.com "
        )

        XCTAssertEqual(token.loginEmail, "user@example.com")
    }

    func testTokenLoginEmailDoesNotFallbackToAccountID() {
        let token = CodexOAuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            idToken: nil,
            tokenType: "Bearer",
            expiresAt: Date(timeIntervalSince1970: 2_000),
            accountID: " account-123 ",
            email: nil
        )

        XCTAssertNil(token.loginEmail)
    }

    private func queryDictionary(from components: URLComponents) -> [String: String] {
        Dictionary(grouping: components.queryItems ?? [], by: \.name)
            .compactMapValues { $0.last?.value }
    }
}

private actor RecordingHTTPDataLoader: HTTPDataLoading {
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

import XCTest
@testable import ReadyCheckCore

final class CodexOAuthQuotaProviderTests: XCTestCase {
    func testLocalSignInCannotReplaceMissingOrUnreadableOAuth() async throws {
        for credentials: any CredentialStore in [InMemoryCredentialStore(), FailingCredentialStore()] {
            let provider = CodexOAuthQuotaProvider(credentialStore: credentials,
                appServerClient: StubCodexAppServerReader(snapshot: oauthOnlySupplement(account: "account-123")),
                now: { Date(timeIntervalSince1970: 1_000) })
            let result = try await provider.fetchSnapshot(context: .init(reason: .manual))
            XCTAssertNotEqual(result.status, .available)
            XCTAssertTrue(result.windows.isEmpty)
        }
    }

    func testOAuthOwnsQuotaAndLocalInterfaceOnlySupplementsMatchingAccount() async throws {
        for sameAccount in [false, true] {
            let credentials = InMemoryCredentialStore()
            try await CodexOAuthTokenStore(credentialStore: credentials).saveToken(.init(accessToken: "synthetic",
                refreshToken: "synthetic", idToken: nil, tokenType: "Bearer", expiresAt: Date(timeIntervalSince1970: 4_600),
                accountID: "account-123", email: nil))
            let loader = QuotaRecordingHTTPDataLoader(data: Data(#"{"rate_limit":{"primary_window":{"used_percent":20,"limit_window_seconds":18000}}}"#.utf8), statusCode: 200)
            let provider = CodexOAuthQuotaProvider(credentialStore: credentials, resetCreditsEndpoint: nil,
                quotaClient: CodexQuotaHTTPClient(loader: loader),
                appServerClient: StubCodexAppServerReader(snapshot: oauthOnlySupplement(account: sameAccount ? "account-123" : "other-account")),
                now: { Date(timeIntervalSince1970: 1_000) })
            let result = try await provider.fetchSnapshot(context: .init(reason: .manual))
            XCTAssertEqual(result.source, .oauthAPI)
            XCTAssertEqual(result.windows.first?.remainingRatio, 0.8, "Local primary data must not replace OAuth quota")
            XCTAssertEqual(result.windows.count, sameAccount ? 2 : 1)
            XCTAssertEqual(result.details?.accountTokenUsage?.summary.lifetimeTokens, sameAccount ? 100 : nil)
            if sameAccount { XCTAssertEqual(result.windows.last?.displayLabel, "Spark") }
        }
    }

    func testOAuthRejectionCannotFallBackToLocalSignIn() async throws {
        let credentials = InMemoryCredentialStore()
        try await CodexOAuthTokenStore(credentialStore: credentials).saveToken(.init(accessToken: "synthetic",
            refreshToken: "synthetic", idToken: nil, tokenType: "Bearer", expiresAt: Date(timeIntervalSince1970: 4_600),
            accountID: "account-123", email: nil))
        let provider = CodexOAuthQuotaProvider(credentialStore: credentials,
            quotaClient: CodexQuotaHTTPClient(loader: QuotaRecordingHTTPDataLoader(data: Data(), statusCode: 401)),
            appServerClient: StubCodexAppServerReader(snapshot: oauthOnlySupplement(account: "account-123")),
            now: { Date(timeIntervalSince1970: 1_000) })
        let result = try await provider.fetchSnapshot(context: .init(reason: .manual))
        XCTAssertEqual(result.errors, ["quota.error.authorizationRejected"])
        XCTAssertTrue(result.windows.isEmpty)
    }

    func testSupplementalRefreshGateThrottlesAutomaticRefreshButAllowsManualRefresh() async {
        let gate = CodexSupplementalRefreshGate(automaticInterval: 900)
        let start = Date(timeIntervalSince1970: 1_000)

        let openedPanel = await gate.shouldRefresh(reason: .openedPanel, now: start)
        let earlyAutomatic = await gate.shouldRefresh(reason: .automatic, now: start.addingTimeInterval(60))
        let dueAutomatic = await gate.shouldRefresh(reason: .automatic, now: start.addingTimeInterval(900))
        let manual = await gate.shouldRefresh(reason: .manual, now: start.addingTimeInterval(901))
        let serverEvent = await gate.shouldRefresh(reason: .serverEvent, now: start.addingTimeInterval(902))

        XCTAssertTrue(openedPanel)
        XCTAssertFalse(earlyAutomatic)
        XCTAssertTrue(dueAutomatic)
        XCTAssertTrue(manual)
        XCTAssertTrue(serverEvent)
    }

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
                    "allowed": false,
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
            resetCreditsEndpoint: nil,
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
        XCTAssertEqual(snapshot.ordinaryUsageAllowed, false)
        XCTAssertEqual(snapshot.errors, [])
        XCTAssertEqual(snapshot.windows.map(\.labelKey), ["quota.window.codex.5h", "quota.window.codex.7d"])
        XCTAssertEqual(snapshot.windows[0].remainingRatio, 0.8)
    }

    func testSeparateSignInUsesOnlyMatchingLocalTokenHistory() async throws {
        let credentialStore = InMemoryCredentialStore()
        try await CodexOAuthTokenStore(credentialStore: credentialStore).saveToken(
            CodexOAuthToken(
                accessToken: "access",
                refreshToken: "refresh",
                idToken: nil,
                tokenType: "Bearer",
                expiresAt: Date(timeIntervalSince1970: 4_600),
                accountID: "separate-account",
                email: "shared@example.com"
            )
        )
        let endpoint = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/usage"))
        let loader = QuotaRecordingHTTPDataLoader(
            data: Data(#"{"rate_limit":{"primary_window":{"used_percent":20,"limit_window_seconds":18000}}}"#.utf8),
            statusCode: 200
        )
        func localSnapshot(accountID: String, tokens: Int64) -> CodexAppServerAccountSnapshot {
            CodexAppServerAccountSnapshot(
                accountID: accountID,
                email: "shared@example.com",
                planName: "plus",
                rateLimits: [
                    CodexAppServerRateLimitSnapshot(
                        limitID: "codex",
                        limitName: nil,
                        primary: CodexAppServerRateLimitWindow(usedPercent: 90, durationMinutes: 300, resetsAt: nil),
                        secondary: nil,
                        creditBalance: nil,
                        hasCredits: false,
                        creditsUnlimited: false,
                        planName: "plus"
                    )
                ],
                resetCredits: [],
                tokenUsage: AccountTokenUsage(
                    summary: AccountTokenUsageSummary(lifetimeTokens: tokens),
                    dailyBuckets: [AccountTokenUsageDailyBucket(startDate: "2026-09-29", tokens: tokens)]
                )
            )
        }
        let provider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            quotaEndpoint: endpoint,
            resetCreditsEndpoint: nil,
            quotaClient: CodexQuotaHTTPClient(loader: loader),
            appServerClient: StubCodexAppServerReader(snapshots: [
                localSnapshot(accountID: "other-account", tokens: 999),
                localSnapshot(accountID: "separate-account", tokens: 123)
            ]),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        XCTAssertEqual(snapshot.source, .oauthAPI)
        XCTAssertEqual(snapshot.windows.first?.remainingRatio, 0.8)
        XCTAssertEqual(snapshot.details?.accountTokenUsage?.dailyBuckets.first?.tokens, 123)

        let unmatchedProvider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            quotaEndpoint: endpoint,
            resetCreditsEndpoint: nil,
            quotaClient: CodexQuotaHTTPClient(loader: loader),
            appServerClient: StubCodexAppServerReader(snapshot: localSnapshot(accountID: "other-account", tokens: 999)),
            now: { Date(timeIntervalSince1970: 1_000) }
        )
        let unmatchedSnapshot = try await unmatchedProvider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))
        XCTAssertEqual(unmatchedSnapshot.source, .oauthAPI)
        XCTAssertNil(unmatchedSnapshot.details?.accountTokenUsage)
    }

    func testProviderFetchesResetCreditExpirationsFromDetailEndpoint() async throws {
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
        let usageEndpoint = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/usage"))
        let resetCreditsEndpoint = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits"))
        let loader = QueueingQuotaRecordingHTTPDataLoader(responses: [
            .init(
                data: Data(
                    """
                    {
                      "rate_limit": {
                        "primary_window": {
                          "used_percent": 20,
                          "limit_window_seconds": 18000,
                          "reset_at": 4600
                        }
                      },
                      "rate_limit_reset_credits": {
                        "available_count": 1
                      },
                      "credits": {
                        "has_credits": true,
                        "unlimited": false,
                        "balance": "3336.5"
                      }
                    }
                    """.utf8
                ),
                statusCode: 200
            ),
            .init(
                data: Data(
                    """
                    {
                      "available_count": 1,
                      "credits": [
                        {
                          "reset_type": "codex_rate_limits",
                          "status": "available",
                          "expires_at": "2026-07-31T20:38:12.468133Z"
                        }
                      ]
                    }
                    """.utf8
                ),
                statusCode: 200
            )
        ])
        let provider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            quotaEndpoint: usageEndpoint,
            resetCreditsEndpoint: resetCreditsEndpoint,
            quotaClient: CodexQuotaHTTPClient(loader: loader),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.url), [usageEndpoint, resetCreditsEndpoint])
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "OpenAI-Beta"), "codex-1")
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "originator"), "Codex Desktop")
        XCTAssertEqual(snapshot.details?.manualResetCount, 1)
        XCTAssertEqual(snapshot.details?.manualResetExpirations.map { Int($0.timeIntervalSince1970) }, [1_785_530_292])
        XCTAssertEqual(snapshot.details?.creditBalance, "3336.5")
        XCTAssertEqual(snapshot.details?.creditsUnlimited, false)
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

    func testServerFailureRetainsOnlyVerifiedRequestIdentity() async throws {
        let credentials = InMemoryCredentialStore()
        try await CodexOAuthTokenStore(credentialStore: credentials).saveToken(CodexOAuthToken(
            accessToken: "test-access", refreshToken: "test-refresh", idToken: nil, tokenType: "Bearer",
            expiresAt: Date(timeIntervalSince1970: 4600), accountID: "test-account", email: nil))
        let provider = CodexOAuthQuotaProvider(credentialStore: credentials, resetCreditsEndpoint: nil,
            quotaClient: CodexQuotaHTTPClient(loader: QuotaRecordingHTTPDataLoader(data: Data(), statusCode: 503)),
            now: { Date(timeIntervalSince1970: 1000) })
        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))
        XCTAssertEqual(snapshot.accountID, "test-account")
        XCTAssertEqual(snapshot.errors, ["quota.error.requestFailed"])
        XCTAssertTrue(snapshot.windows.isEmpty)
    }

    func testProviderRequestsReauthenticationOnlyWhenUsageAuthorizationIsRejected() async throws {
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
        let loader = QuotaRecordingHTTPDataLoader(data: Data(), statusCode: 401)
        let provider = CodexOAuthQuotaProvider(
            credentialStore: credentialStore,
            resetCreditsEndpoint: nil,
            quotaClient: CodexQuotaHTTPClient(loader: loader),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        XCTAssertEqual(snapshot.errors, ["quota.error.authorizationRejected"])
        XCTAssertNil(snapshot.accountID)
        XCTAssertEqual(snapshot.recoveryAction, .reconnect)
    }
}

private struct FailingCredentialStore: CredentialStore {
    func loadCredential(for key: CredentialKey) async throws -> String? {
        throw KeychainCredentialStoreError.unexpectedStatus(errSecInteractionNotAllowed)
    }

    func saveCredential(_ credential: String, for key: CredentialKey) async throws {}
    func removeCredential(for key: CredentialKey) async throws {}
}

private struct StubCodexAppServerReader: CodexAppServerReading {
    let snapshots: [CodexAppServerAccountSnapshot]

    init(snapshot: CodexAppServerAccountSnapshot) {
        self.snapshots = [snapshot]
    }

    init(snapshots: [CodexAppServerAccountSnapshot]) {
        self.snapshots = snapshots
    }

    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        snapshots[0]
    }

    func readAccountSnapshots() async throws -> [CodexAppServerAccountSnapshot] {
        snapshots
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

private actor QueueingQuotaRecordingHTTPDataLoader: HTTPDataLoading {
    struct Response {
        let data: Data
        let statusCode: Int
    }

    private var responses: [Response]
    private var requests: [URLRequest] = []

    init(responses: [Response]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let responsePayload = responses.isEmpty
            ? Response(data: Data(), statusCode: 500)
            : responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: responsePayload.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responsePayload.data, response)
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

private func oauthOnlySupplement(account: String) -> CodexAppServerAccountSnapshot {
    CodexAppServerAccountSnapshot(accountID: account, email: nil, planName: "plus", rateLimits: [
        .init(limitID: "codex", limitName: nil, primary: .init(usedPercent: 90, durationMinutes: 300, resetsAt: nil),
            secondary: nil, creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: nil),
        .init(limitID: "codex_spark", limitName: "Spark", primary: .init(usedPercent: 50, durationMinutes: 300, resetsAt: nil),
            secondary: nil, creditBalance: nil, hasCredits: nil, creditsUnlimited: nil, planName: nil)
    ], resetCredits: [], tokenUsage: .init(summary: .init(lifetimeTokens: 100), dailyBuckets: []))
}

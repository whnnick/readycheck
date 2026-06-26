import Foundation

public struct CodexOAuthQuotaProvider: QuotaProvider {
    public let id = "codex-oauth"
    public let displayName = "Codex"

    private let tokenStore: CodexOAuthTokenStore
    private let oauthClient: CodexOAuthClient
    private let quotaClient: CodexQuotaHTTPClient
    private let usageParser: CodexUsageParser
    private let quotaEndpoint: URL?
    private let now: @Sendable () -> Date

    public init(
        credentialStore: any CredentialStore,
        quotaEndpoint: URL? = URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
        oauthClient: CodexOAuthClient = CodexOAuthClient(),
        quotaClient: CodexQuotaHTTPClient = CodexQuotaHTTPClient(),
        usageParser: CodexUsageParser = CodexUsageParser(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        self.oauthClient = oauthClient
        self.quotaClient = quotaClient
        self.usageParser = usageParser
        self.quotaEndpoint = quotaEndpoint
        self.now = now
    }

    public func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        let date = now()
        guard var token = try await tokenStore.loadToken() else {
            return snapshot(date: date, error: "quota.error.oauthRequired")
        }

        guard let quotaEndpoint else {
            return snapshot(date: date, error: "quota.error.endpointCalibrationRequired")
        }

        guard EndpointSafety.isAllowedForRefresh(quotaEndpoint) else {
            return ProviderQuotaSnapshot(
                providerId: id,
                displayName: displayName,
                status: .error,
                source: .oauthAPI,
                refreshedAt: date,
                staleAfter: date.addingTimeInterval(300),
                windows: [],
                errors: ["quota.error.unsafeEndpoint"]
            )
        }

        if token.expiresAt <= date {
            do {
                token = try await oauthClient.refreshToken(token.refreshToken)
                try await tokenStore.saveToken(token)
            } catch {
                return snapshot(date: date, error: "quota.error.tokenRefreshFailed")
            }
        }

        guard let accountID = token.accountID ?? CodexJWTClaims.accountID(from: token.accessToken) else {
            return snapshot(date: date, error: "quota.error.accountIdUnavailable")
        }

        do {
            let payload = try await quotaClient.fetchReadOnlyPayload(
                from: quotaEndpoint,
                accessToken: token.accessToken,
                accountID: accountID
            )
            let windows = try usageParser.parse(payload, refreshedAt: date)
            return ProviderQuotaSnapshot(
                providerId: id,
                displayName: displayName,
                status: .available,
                source: .oauthAPI,
                refreshedAt: date,
                staleAfter: date.addingTimeInterval(300),
                windows: windows,
                errors: []
            )
        } catch CodexUsageParserError.noDisplayableWindows {
            return snapshot(date: date, error: "quota.error.parserUnavailable")
        } catch {
            return snapshot(date: date, error: "quota.error.requestFailed")
        }
    }

    private func snapshot(date: Date, error: String) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(
            providerId: id,
            displayName: displayName,
            status: .unavailable,
            source: .oauthAPI,
            refreshedAt: date,
            staleAfter: date.addingTimeInterval(300),
            windows: [],
            errors: [error]
        )
    }
}

import Foundation

public struct CodexOAuthQuotaProvider: QuotaProvider {
    public let id = "codex-oauth"
    public let displayName = "Codex"

    private let tokenStore: CodexOAuthTokenStore
    private let oauthClient: CodexOAuthClient
    private let quotaClient: CodexQuotaHTTPClient
    private let usageParser: CodexUsageParser
    private let appServerClient: (any CodexAppServerReading)?
    private let quotaEndpoint: URL?
    private let resetCreditsEndpoint: URL?
    private let now: @Sendable () -> Date

    public init(
        credentialStore: any CredentialStore,
        quotaEndpoint: URL? = URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
        resetCreditsEndpoint: URL? = URL(string: "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits")!,
        oauthClient: CodexOAuthClient = CodexOAuthClient(),
        quotaClient: CodexQuotaHTTPClient = CodexQuotaHTTPClient(),
        usageParser: CodexUsageParser = CodexUsageParser(),
        appServerClient: (any CodexAppServerReading)? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.tokenStore = CodexOAuthTokenStore(credentialStore: credentialStore)
        self.oauthClient = oauthClient
        self.quotaClient = quotaClient
        self.usageParser = usageParser
        self.appServerClient = appServerClient
        self.quotaEndpoint = quotaEndpoint
        self.resetCreditsEndpoint = resetCreditsEndpoint
        self.now = now
    }

    public func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        let date = now()
        guard var token = try await tokenStore.loadToken() else {
            return snapshot(date: date, error: "quota.error.oauthRequired")
        }

        if token.expiresAt <= date {
            do {
                token = try await oauthClient.refreshToken(token.refreshToken)
                try await tokenStore.saveToken(token)
            } catch {
                return snapshot(date: date, error: "quota.error.tokenRefreshFailed")
            }
        }

        if let appServerClient,
           let appServerSnapshot = try? await appServerClient.readAccountSnapshot(),
           accountsMatch(token: token, snapshot: appServerSnapshot),
           let officialSnapshot = makeOfficialSnapshot(
               appServerSnapshot,
               token: token,
               refreshedAt: date
           ) {
            return officialSnapshot
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
            let usageDetails = await mergedManualResetDetails(
                usagePayload: payload,
                accessToken: token.accessToken,
                accountID: accountID
            )
            return ProviderQuotaSnapshot(
                providerId: id,
                displayName: displayName,
                status: .available,
                source: .oauthAPI,
                refreshedAt: date,
                staleAfter: date.addingTimeInterval(300),
                windows: windows,
                errors: [],
                details: ProviderQuotaDetails(
                    planName: CodexJWTClaims.planName(from: token.idToken),
                    subscriptionRenewalAt: CodexJWTClaims.subscriptionRenewalAt(from: token.idToken),
                    manualResetCount: usageDetails.manualResetCount,
                    manualResetExpirations: usageDetails.manualResetExpirations,
                    creditBalance: usageDetails.creditBalance,
                    creditsUnlimited: usageDetails.creditsUnlimited
                )
            )
        } catch CodexUsageParserError.noDisplayableWindows {
            return snapshot(date: date, error: "quota.error.parserUnavailable")
        } catch CodexQuotaHTTPClientError.requestFailed(let statusCode)
            where statusCode == 401 || statusCode == 403 {
            return snapshot(date: date, error: "quota.error.authorizationRejected")
        } catch {
            return snapshot(date: date, error: "quota.error.requestFailed")
        }
    }

    private func accountsMatch(
        token: CodexOAuthToken,
        snapshot: CodexAppServerAccountSnapshot
    ) -> Bool {
        guard let readyCheckEmail = token.loginEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let appServerEmail = snapshot.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !readyCheckEmail.isEmpty,
              !appServerEmail.isEmpty
        else {
            return false
        }
        return readyCheckEmail == appServerEmail
    }

    private func makeOfficialSnapshot(
        _ appServerSnapshot: CodexAppServerAccountSnapshot,
        token: CodexOAuthToken,
        refreshedAt: Date
    ) -> ProviderQuotaSnapshot? {
        let windows = appServerSnapshot.rateLimits.flatMap { snapshot in
            [
                makeOfficialWindow(
                    snapshot.primary,
                    id: "\(snapshot.limitID)-primary",
                    fallbackLabelKey: "quota.window.codex.primary"
                ),
                makeOfficialWindow(
                    snapshot.secondary,
                    id: "\(snapshot.limitID)-secondary",
                    fallbackLabelKey: "quota.window.codex.secondary"
                )
            ].compactMap { $0 }
        }
        guard !windows.isEmpty else { return nil }

        let defaultLimit = appServerSnapshot.rateLimits.first {
            $0.limitID == "codex"
        } ?? appServerSnapshot.rateLimits.first
        let resetExpirations = appServerSnapshot.resetCredits.compactMap { credit -> Date? in
            guard credit.status == nil || credit.status == "available" else { return nil }
            return credit.expiresAt
        }.sorted()

        return ProviderQuotaSnapshot(
            providerId: id,
            displayName: displayName,
            status: .available,
            source: .appServer,
            refreshedAt: refreshedAt,
            staleAfter: refreshedAt.addingTimeInterval(300),
            windows: windows,
            errors: [],
            details: ProviderQuotaDetails(
                planName: defaultLimit?.planName
                    ?? appServerSnapshot.planName
                    ?? CodexJWTClaims.planName(from: token.idToken),
                subscriptionRenewalAt: CodexJWTClaims.subscriptionRenewalAt(from: token.idToken),
                manualResetCount: resetExpirations.count,
                manualResetExpirations: resetExpirations,
                creditBalance: defaultLimit?.hasCredits == false ? nil : defaultLimit?.creditBalance,
                creditsUnlimited: defaultLimit?.creditsUnlimited,
                accountTokenUsage: appServerSnapshot.tokenUsage
            )
        )
    }

    private func makeOfficialWindow(
        _ window: CodexAppServerRateLimitWindow?,
        id: String,
        fallbackLabelKey: String
    ) -> QuotaWindow? {
        guard let window, window.usedPercent.isFinite else { return nil }
        let used = min(max(window.usedPercent, 0), 100)
        return QuotaWindow(
            id: id,
            labelKey: labelKey(durationMinutes: window.durationMinutes, fallback: fallbackLabelKey),
            kind: .rolling,
            used: used,
            limit: 100,
            remaining: 100 - used,
            unit: .percent,
            resetAt: window.resetsAt,
            confidence: .verified
        )
    }

    private func labelKey(durationMinutes: Int?, fallback: String) -> String {
        switch durationMinutes {
        case 300:
            "quota.window.codex.5h"
        case 10_080:
            "quota.window.codex.7d"
        default:
            fallback
        }
    }

    private func mergedManualResetDetails(
        usagePayload: Data,
        accessToken: String,
        accountID: String
    ) async -> ProviderQuotaDetails {
        let usageDetails = usageParser.parseManualResetDetails(usagePayload)
        guard let resetCreditsEndpoint else {
            return usageDetails
        }

        guard let resetCreditsPayload = try? await quotaClient.fetchReadOnlyPayload(
            from: resetCreditsEndpoint,
            accessToken: accessToken,
            accountID: accountID,
            additionalHeaders: [
                "OpenAI-Beta": "codex-1",
                "originator": "Codex Desktop"
            ]
        ) else {
            return usageDetails
        }

        let resetCreditDetails = usageParser.parseManualResetDetails(resetCreditsPayload)
        return ProviderQuotaDetails(
            manualResetCount: resetCreditDetails.manualResetCount ?? usageDetails.manualResetCount,
            manualResetExpirations: resetCreditDetails.manualResetExpirations.isEmpty
                ? usageDetails.manualResetExpirations
                : resetCreditDetails.manualResetExpirations,
            creditBalance: usageDetails.creditBalance,
            creditsUnlimited: usageDetails.creditsUnlimited,
            accountTokenUsage: usageDetails.accountTokenUsage
        )
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

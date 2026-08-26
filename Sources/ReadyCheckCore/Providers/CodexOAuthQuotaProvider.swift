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
    private let supplementalRefreshGate = CodexSupplementalRefreshGate()

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
        let shouldRefreshSupplementalDetails = await supplementalRefreshGate.shouldRefresh(
            reason: context.reason,
            now: date
        )
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

        if shouldRefreshSupplementalDetails,
           let appServerClient,
           let appServerSnapshots = try? await appServerClient.readAccountSnapshots(),
           let appServerSnapshot = mergedMatchingAppServerSnapshot(
               appServerSnapshots,
               token: token
           ),
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
                accountID: accountID,
                shouldRefreshResetCredits: shouldRefreshSupplementalDetails
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

    private func mergedMatchingAppServerSnapshot(
        _ snapshots: [CodexAppServerAccountSnapshot],
        token: CodexOAuthToken
    ) -> CodexAppServerAccountSnapshot? {
        let matching = snapshots.filter { accountsMatch(token: token, snapshot: $0) }
        guard var merged = matching.first else { return nil }

        for candidate in matching.dropFirst() {
            let shouldPreserveExplicitZero = merged.manualResetCount == 0
            let resolvedCount = merged.manualResetCount ?? candidate.manualResetCount
            let resolvedResetCredits: [CodexAppServerResetCredit]
            if shouldPreserveExplicitZero || !merged.resetCredits.isEmpty {
                resolvedResetCredits = merged.resetCredits
            } else {
                resolvedResetCredits = candidate.resetCredits
            }

            merged = CodexAppServerAccountSnapshot(
                email: merged.email,
                planName: merged.planName ?? candidate.planName,
                rateLimits: merged.rateLimits.isEmpty ? candidate.rateLimits : merged.rateLimits,
                manualResetCount: resolvedCount,
                resetCredits: resolvedResetCredits,
                tokenUsage: merged.tokenUsage ?? candidate.tokenUsage
            )
        }
        return merged
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
                    fallbackLabelKey: "quota.window.codex.primary",
                    limitName: snapshot.limitName,
                    limitID: snapshot.limitID,
                    limitStateCode: snapshot.reachedStateCode
                ),
                makeOfficialWindow(
                    snapshot.secondary,
                    id: "\(snapshot.limitID)-secondary",
                    fallbackLabelKey: "quota.window.codex.secondary",
                    limitName: snapshot.limitName,
                    limitID: snapshot.limitID,
                    limitStateCode: snapshot.reachedStateCode
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
                manualResetCount: appServerSnapshot.manualResetCount,
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
        fallbackLabelKey: String,
        limitName: String?,
        limitID: String,
        limitStateCode: String?
    ) -> QuotaWindow? {
        guard let window, window.usedPercent.isFinite else { return nil }
        let used = min(max(window.usedPercent, 0), 100)
        let labelKey = labelKey(durationMinutes: window.durationMinutes, fallback: fallbackLabelKey)
        return QuotaWindow(
            id: id,
            labelKey: labelKey,
            displayLabel: officialDisplayLabel(
                limitName,
                limitID: limitID,
                usesFallbackLabel: labelKey == fallbackLabelKey
            ),
            limitStateCode: limitStateCode,
            kind: .rolling,
            used: used,
            limit: 100,
            remaining: 100 - used,
            unit: .percent,
            resetAt: window.resetsAt,
            confidence: .verified
        )
    }

    private func officialDisplayLabel(
        _ limitName: String?,
        limitID: String,
        usesFallbackLabel: Bool
    ) -> String? {
        guard usesFallbackLabel,
              let value = limitName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              value.caseInsensitiveCompare(limitID) != .orderedSame
        else {
            return nil
        }
        return value
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
        accountID: String,
        shouldRefreshResetCredits: Bool
    ) async -> ProviderQuotaDetails {
        let usageDetails = usageParser.parseManualResetDetails(usagePayload)
        guard shouldRefreshResetCredits, let resetCreditsEndpoint else {
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

actor CodexSupplementalRefreshGate {
    private let automaticInterval: TimeInterval
    private var lastAttemptAt: Date?

    init(automaticInterval: TimeInterval = 15 * 60) {
        self.automaticInterval = automaticInterval
    }

    func shouldRefresh(reason: RefreshReason, now: Date) -> Bool {
        if reason == .manual {
            lastAttemptAt = now
            return true
        }
        guard let lastAttemptAt else {
            self.lastAttemptAt = now
            return true
        }
        guard now.timeIntervalSince(lastAttemptAt) >= automaticInterval else {
            return false
        }
        self.lastAttemptAt = now
        return true
    }
}

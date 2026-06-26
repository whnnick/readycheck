import Foundation

public struct MockQuotaProvider: QuotaProvider {
    public let id = "mock"
    public let displayName = "Mock"
    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    public func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        let date = now()
        return ProviderQuotaSnapshot(
            providerId: id,
            displayName: displayName,
            status: .available,
            source: .mock,
            refreshedAt: date,
            staleAfter: date.addingTimeInterval(60),
            windows: [
                QuotaWindow(
                    id: "codex-5h",
                    labelKey: "quota.window.codex.5h",
                    kind: .rolling,
                    used: 28,
                    limit: 100,
                    remaining: 72,
                    unit: .percent,
                    resetAt: date.addingTimeInterval(5 * 60 * 60),
                    confidence: .verified
                ),
                QuotaWindow(
                    id: "codex-7d",
                    labelKey: "quota.window.codex.7d",
                    kind: .rolling,
                    used: 52,
                    limit: 100,
                    remaining: 48,
                    unit: .percent,
                    resetAt: date.addingTimeInterval(7 * 24 * 60 * 60),
                    confidence: .verified
                ),
                QuotaWindow(
                    id: "claude-monthly",
                    labelKey: "quota.window.claude.monthly",
                    kind: .calendar,
                    used: 59,
                    limit: 100,
                    remaining: 41,
                    unit: .percent,
                    resetAt: nil,
                    confidence: .verified
                ),
                QuotaWindow(
                    id: "openai-api-monthly",
                    labelKey: "quota.window.openai.monthly",
                    kind: .billing,
                    used: 18.40,
                    limit: 50,
                    remaining: 31.60,
                    unit: .usd,
                    resetAt: nil,
                    confidence: .verified
                )
            ],
            errors: []
        )
    }
}

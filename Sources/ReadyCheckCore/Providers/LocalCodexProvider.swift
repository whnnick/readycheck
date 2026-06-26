import Foundation

public enum LocalCodexValidationState: Equatable, Sendable {
    case notValidated
    case validatedWithoutQuotaWindows
}

public struct LocalCodexProvider: QuotaProvider {
    public let id = "local-codex"
    public let displayName = "Codex"

    private let sourceURLs: [URL]
    private let validation: LocalCodexValidationState
    private let now: @Sendable () -> Date

    public init(
        sourceURLs: [URL],
        validation: LocalCodexValidationState,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.sourceURLs = sourceURLs
        self.validation = validation
        self.now = now
    }

    public func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        let date = now()
        let message: String
        switch validation {
        case .notValidated:
            message = "Needs calibration"
        case .validatedWithoutQuotaWindows:
            message = "Quota windows unavailable"
        }

        return ProviderQuotaSnapshot(
            providerId: id,
            displayName: displayName,
            status: .unavailable,
            source: .local,
            refreshedAt: date,
            staleAfter: date.addingTimeInterval(60),
            windows: [],
            errors: [message]
        )
    }

    public func auditSources() -> [String] {
        sourceURLs.map { $0.path }
    }
}

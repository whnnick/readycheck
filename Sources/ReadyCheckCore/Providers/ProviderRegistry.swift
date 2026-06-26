import Foundation

public struct ProviderRegistry: Sendable {
    public let providers: [any QuotaProvider]

    public init(providers: [any QuotaProvider]) {
        self.providers = providers
    }

    public init(
        configurations: [ProviderConfiguration],
        credentialStore: any CredentialStore = InMemoryCredentialStore(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.init(
            providers: configurations.compactMap { configuration in
                guard configuration.isEnabled else { return nil }

                switch configuration.provider {
                case .mock:
                    return MockQuotaProvider(now: now)
                case .localCodex:
                    return LocalCodexProvider(sourceURLs: [], validation: .notValidated, now: now)
                case .codexOAuth:
                    return CodexOAuthQuotaProvider(credentialStore: credentialStore, now: now)
                }
            }
        )
    }

    public func provider(id: String) -> (any QuotaProvider)? {
        providers.first { $0.id == id }
    }
}

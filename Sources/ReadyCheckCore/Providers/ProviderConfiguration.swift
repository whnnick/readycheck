import Foundation

public enum BuiltInProvider: String, CaseIterable, Codable, Equatable, Sendable {
    case mock
    case localCodex = "local-codex"
    case codexOAuth = "codex-oauth"

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .mock:
            "Mock"
        case .localCodex:
            "Codex"
        case .codexOAuth:
            "Codex OAuth"
        }
    }
}

public struct ProviderConfiguration: Identifiable, Codable, Equatable, Sendable {
    public let provider: BuiltInProvider
    public var isEnabled: Bool

    public var id: String {
        provider.id
    }

    public init(provider: BuiltInProvider, isEnabled: Bool) {
        self.provider = provider
        self.isEnabled = isEnabled
    }

    public static let defaults: [ProviderConfiguration] = [
        ProviderConfiguration(provider: .mock, isEnabled: false),
        ProviderConfiguration(provider: .localCodex, isEnabled: false),
        ProviderConfiguration(provider: .codexOAuth, isEnabled: true)
    ]
}

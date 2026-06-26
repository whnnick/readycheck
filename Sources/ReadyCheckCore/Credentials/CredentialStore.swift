public struct CredentialKey: Hashable, Codable, Sendable {
    public let providerId: String
    public let name: String

    public init(providerId: String, name: String) {
        self.providerId = providerId
        self.name = name
    }
}

public protocol CredentialStore: Sendable {
    func loadCredential(for key: CredentialKey) async throws -> String?
    func saveCredential(_ credential: String, for key: CredentialKey) async throws
    func removeCredential(for key: CredentialKey) async throws
}

public actor InMemoryCredentialStore: CredentialStore {
    private var credentials: [CredentialKey: String] = [:]

    public init() {}

    public func loadCredential(for key: CredentialKey) async throws -> String? {
        credentials[key]
    }

    public func saveCredential(_ credential: String, for key: CredentialKey) async throws {
        credentials[key] = credential
    }

    public func removeCredential(for key: CredentialKey) async throws {
        credentials[key] = nil
    }
}

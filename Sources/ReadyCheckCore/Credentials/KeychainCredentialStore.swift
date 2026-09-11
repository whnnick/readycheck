import Foundation
import Security

public struct KeychainCredentialStore: CredentialStore {
    private static let queue = DispatchQueue(label: "com.readycheck.keychain")
    private let service: String
    private let allowsInteraction: Bool

    public init(service: String = "com.readycheck.credentials", allowsInteraction: Bool = false) {
        self.service = service
        self.allowsInteraction = allowsInteraction
    }

    public func loadCredential(for key: CredentialKey) async throws -> String? {
        try await Self.perform {
            if allowsInteraction { return try loadSynchronously(for: key) }
            return try KeychainReadInteraction.withoutPrompt {
                try loadSynchronously(for: key)
            }
        }
    }

    private func loadSynchronously(for key: CredentialKey) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainCredentialStoreError.unexpectedStatus(status)
        }
        guard let data = item as? Data, let credential = String(data: data, encoding: .utf8) else {
            throw KeychainCredentialStoreError.invalidCredentialData
        }

        return credential
    }

    public func saveCredential(_ credential: String, for key: CredentialKey) async throws {
        try await Self.perform { try saveSynchronously(credential, for: key) }
    }

    private func saveSynchronously(_ credential: String, for key: CredentialKey) throws {
        let data = Data(credential.utf8)
        var query = baseQuery(for: key)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainCredentialStoreError.unexpectedStatus(updateStatus)
        }

        query[kSecValueData as String] = data
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainCredentialStoreError.unexpectedStatus(addStatus)
        }
    }

    public func removeCredential(for key: CredentialKey) async throws {
        try await Self.perform { try removeSynchronously(for: key) }
    }

    private func removeSynchronously(for key: CredentialKey) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainCredentialStoreError.unexpectedStatus(status)
        }
    }

    private static func perform<T: Sendable>(_ operation: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { continuation.resume(with: Result { try operation() }) }
        }
    }

    private func baseQuery(for key: CredentialKey) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(key.providerId):\(key.name)"
        ]
    }
}

enum KeychainReadInteraction {
    // Legacy file-based keychains ignore per-query authentication UI options.
    // Serialize all store operations and restore this process-only flag on every exit.
    static func withoutPrompt<T>(
        get: (UnsafeMutablePointer<DarwinBoolean>) -> OSStatus = SecKeychainGetUserInteractionAllowed,
        set: (Bool) -> OSStatus = SecKeychainSetUserInteractionAllowed,
        operation: () throws -> T
    ) throws -> T {
        var allowed = DarwinBoolean(false)
        let getStatus = get(&allowed)
        guard getStatus == errSecSuccess else {
            throw KeychainCredentialStoreError.unexpectedStatus(getStatus)
        }
        let setStatus = set(false)
        guard setStatus == errSecSuccess else {
            throw KeychainCredentialStoreError.unexpectedStatus(setStatus)
        }
        let result = Result { try operation() }
        let restoreStatus = set(allowed.boolValue)
        guard restoreStatus == errSecSuccess else {
            throw KeychainCredentialStoreError.unexpectedStatus(restoreStatus)
        }
        return try result.get()
    }
}

public enum KeychainCredentialStoreError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case invalidCredentialData
}

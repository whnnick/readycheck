import Foundation
import Security

public struct KeychainCredentialStore: CredentialStore {
    private let service: String

    public init(service: String = "com.readycheck.credentials") {
        self.service = service
    }

    public func loadCredential(for key: CredentialKey) async throws -> String? {
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
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainCredentialStoreError.unexpectedStatus(status)
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

public enum KeychainCredentialStoreError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case invalidCredentialData
}

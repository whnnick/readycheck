import XCTest
@testable import ReadyCheckCore

final class CredentialStoreTests: XCTestCase {
    func testInMemoryCredentialStoreLoadsSavedCredential() async throws {
        let store = InMemoryCredentialStore()
        let key = CredentialKey(providerId: "openai", name: "admin-credential")

        try await store.saveCredential("sample-credential", for: key)

        let credential = try await store.loadCredential(for: key)
        XCTAssertEqual(credential, "sample-credential")
    }

    func testInMemoryCredentialStoreRemovesCredential() async throws {
        let store = InMemoryCredentialStore()
        let key = CredentialKey(providerId: "anthropic", name: "provider-credential")

        try await store.saveCredential("sample-credential", for: key)
        try await store.removeCredential(for: key)

        let credential = try await store.loadCredential(for: key)
        XCTAssertNil(credential)
    }

    func testCredentialKeySeparatesProviderAndName() {
        let openAIKey = CredentialKey(providerId: "openai", name: "provider-credential")
        let anthropicKey = CredentialKey(providerId: "anthropic", name: "provider-credential")

        XCTAssertNotEqual(openAIKey, anthropicKey)
    }
}

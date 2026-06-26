import XCTest
@testable import ReadyCheckCore

final class ProviderConfigurationTests: XCTestCase {
    func testDefaultConfigurationsEnableOnlyCodexOAuthProvider() {
        let configurations = ProviderConfiguration.defaults

        XCTAssertEqual(configurations.map(\.id), ["mock", "local-codex", "codex-oauth"])
        XCTAssertEqual(configurations.map(\.isEnabled), [false, false, true])
    }

    func testRegistryBuildsOnlyEnabledProvidersInConfigurationOrder() {
        let configurations = [
            ProviderConfiguration(provider: .codexOAuth, isEnabled: true),
            ProviderConfiguration(provider: .mock, isEnabled: false)
        ]

        let registry = ProviderRegistry(configurations: configurations)

        XCTAssertEqual(registry.providers.map(\.id), ["codex-oauth"])
        XCTAssertEqual(registry.provider(id: "codex-oauth")?.displayName, "Codex")
        XCTAssertNil(registry.provider(id: "mock"))
    }

    func testProviderConfigurationCodableRoundTripsWithoutCredentials() throws {
        let configuration = ProviderConfiguration(provider: .mock, isEnabled: true)

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(ProviderConfiguration.self, from: data)

        XCTAssertEqual(decoded, configuration)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("credential"))
    }
}

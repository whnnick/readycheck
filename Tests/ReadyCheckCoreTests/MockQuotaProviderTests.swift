import XCTest
@testable import ReadyCheckCore

final class MockQuotaProviderTests: XCTestCase {
    func testMockProviderReturnsCodexFiveHourAndSevenDayWindows() async throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let provider = MockQuotaProvider(now: { date })

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        XCTAssertEqual(snapshot.providerId, "mock")
        XCTAssertEqual(snapshot.status, .available)
        XCTAssertEqual(snapshot.source, .mock)
        XCTAssertEqual(snapshot.windows.map(\.id), ["codex-5h", "codex-7d", "claude-monthly", "openai-api-monthly"])
        XCTAssertEqual(snapshot.refreshedAt, date)
        XCTAssertEqual(snapshot.staleAfter, date.addingTimeInterval(60))
        XCTAssertEqual(snapshot.windows[0].resetAt, date.addingTimeInterval(5 * 60 * 60))
        XCTAssertEqual(snapshot.windows[1].resetAt, date.addingTimeInterval(7 * 24 * 60 * 60))
        XCTAssertTrue(snapshot.canShowPercentages(now: date))
    }

    func testRegistryFindsProviderById() {
        let mock = MockQuotaProvider(now: { Date(timeIntervalSince1970: 1_000) })
        let registry = ProviderRegistry(providers: [mock])

        XCTAssertEqual(registry.provider(id: "mock")?.id, "mock")
        XCTAssertNil(registry.provider(id: "missing"))
    }
}

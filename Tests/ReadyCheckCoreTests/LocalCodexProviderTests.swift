import XCTest
@testable import ReadyCheckCore

final class LocalCodexProviderTests: XCTestCase {
    func testLocalCodexProviderReturnsNeedsCalibrationBeforeValidationPasses() async throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let provider = LocalCodexProvider(
            sourceURLs: [URL(fileURLWithPath: "/tmp/local-codex-fixture.json")],
            validation: .notValidated,
            now: { date }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .manual))

        XCTAssertEqual(snapshot.providerId, "local-codex")
        XCTAssertEqual(snapshot.displayName, "Codex")
        XCTAssertEqual(snapshot.status, .unavailable)
        XCTAssertEqual(snapshot.source, .local)
        XCTAssertEqual(snapshot.refreshedAt, date)
        XCTAssertEqual(snapshot.staleAfter, date.addingTimeInterval(60))
        XCTAssertEqual(snapshot.windows, [])
        XCTAssertEqual(snapshot.errors, ["Needs calibration"])
        XCTAssertFalse(snapshot.canShowPercentages(now: date))
    }

    func testValidatedProviderStillSuppressesPercentagesWithoutParsedWindows() async throws {
        let date = Date(timeIntervalSince1970: 2_000)
        let provider = LocalCodexProvider(
            sourceURLs: [],
            validation: .validatedWithoutQuotaWindows,
            now: { date }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .automatic))

        XCTAssertEqual(snapshot.providerId, "local-codex")
        XCTAssertEqual(snapshot.displayName, "Codex")
        XCTAssertEqual(snapshot.status, .unavailable)
        XCTAssertEqual(snapshot.source, .local)
        XCTAssertEqual(snapshot.refreshedAt, date)
        XCTAssertEqual(snapshot.staleAfter, date.addingTimeInterval(60))
        XCTAssertEqual(snapshot.windows, [])
        XCTAssertEqual(snapshot.errors, ["Quota windows unavailable"])
        XCTAssertFalse(snapshot.canShowPercentages(now: date))
    }

    func testAuditSourcesReturnsConfiguredPaths() {
        let provider = LocalCodexProvider(
            sourceURLs: [
                URL(fileURLWithPath: "/tmp/local-codex/a.json"),
                URL(fileURLWithPath: "/tmp/local-codex/b.json")
            ],
            validation: .notValidated
        )

        XCTAssertEqual(provider.auditSources(), [
            "/tmp/local-codex/a.json",
            "/tmp/local-codex/b.json"
        ])
    }

    func testSnapshotBecomesStaleAtConfiguredBoundary() async throws {
        let date = Date(timeIntervalSince1970: 3_000)
        let provider = LocalCodexProvider(
            sourceURLs: [],
            validation: .notValidated,
            now: { date }
        )

        let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: .openedPanel))

        XCTAssertFalse(snapshot.isStale(now: date.addingTimeInterval(59)))
        XCTAssertTrue(snapshot.isStale(now: date.addingTimeInterval(60)))
        XCTAssertFalse(snapshot.canShowPercentages(now: date.addingTimeInterval(59)))
    }
}

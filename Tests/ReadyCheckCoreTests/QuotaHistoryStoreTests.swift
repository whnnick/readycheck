import XCTest
@testable import ReadyCheckCore

final class QuotaHistoryStoreTests: XCTestCase {
    func testRecordsOnlyAvailableValidatedSnapshots() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = QuotaHistoryStore(
            fileURL: fileURL,
            now: { Date(timeIntervalSince1970: 10_000) }
        )

        let samples = await store.record(makeSnapshot(at: 9_000, remaining: 0.7))

        XCTAssertEqual(samples.count, 1)
        XCTAssertEqual(samples[0].values.map(\.remainingRatio), [0.7, 0.8])
        let unavailable = makeSnapshot(at: 9_100, remaining: 0.6, status: .unavailable)
        let afterUnavailable = await store.record(unavailable)
        XCTAssertEqual(afterUnavailable, samples)
    }

    func testReplacesSamplesInsideFiveMinuteBucket() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = QuotaHistoryStore(
            fileURL: fileURL,
            now: { Date(timeIntervalSince1970: 10_000) }
        )

        _ = await store.record(makeSnapshot(at: 9_000, remaining: 0.8))
        let samples = await store.record(makeSnapshot(at: 9_120, remaining: 0.7))

        XCTAssertEqual(samples.count, 1)
        XCTAssertEqual(samples[0].recordedAt, Date(timeIntervalSince1970: 9_120))
        XCTAssertEqual(samples[0].values[0].remainingRatio, 0.7)
    }

    func testRetainsThirtyDaysAndPersistsToDisk() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let now = Date(timeIntervalSince1970: 4_000_000)
        let store = QuotaHistoryStore(fileURL: fileURL, now: { now })

        _ = await store.record(makeSnapshot(at: now.timeIntervalSince1970 - 31 * 86_400, remaining: 0.9))
        _ = await store.record(makeSnapshot(at: now.timeIntervalSince1970 - 1_000, remaining: 0.6))

        let reloaded = await QuotaHistoryStore(fileURL: fileURL, now: { now }).load()
        XCTAssertEqual(reloaded.count, 1)
        XCTAssertEqual(reloaded[0].values[0].remainingRatio, 0.6)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("history.json")
    }

    private func makeSnapshot(
        at timestamp: TimeInterval,
        remaining: Double,
        status: ProviderStatus = .available
    ) -> ProviderQuotaSnapshot {
        let date = Date(timeIntervalSince1970: timestamp)
        return ProviderQuotaSnapshot(
            providerId: "codex-oauth",
            displayName: "Codex",
            status: status,
            source: .oauthAPI,
            refreshedAt: date,
            staleAfter: date.addingTimeInterval(300),
            windows: [
                QuotaWindow(
                    id: "codex-primary",
                    labelKey: "quota.window.codex.5h",
                    kind: .rolling,
                    used: (1 - remaining) * 100,
                    limit: 100,
                    remaining: remaining * 100,
                    unit: .percent,
                    resetAt: date.addingTimeInterval(3_600),
                    confidence: .verified
                ),
                QuotaWindow(
                    id: "codex-secondary",
                    labelKey: "quota.window.codex.7d",
                    kind: .rolling,
                    used: 20,
                    limit: 100,
                    remaining: 80,
                    unit: .percent,
                    resetAt: date.addingTimeInterval(86_400),
                    confidence: .verified
                )
            ],
            errors: []
        )
    }
}

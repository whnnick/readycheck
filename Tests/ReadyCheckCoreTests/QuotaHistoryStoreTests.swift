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
        XCTAssertEqual(samples[0].values.first?.displayLabel, "Codex allowance")
        let unavailable = makeSnapshot(at: 9_100, remaining: 0.6, status: .unavailable)
        let afterUnavailable = await store.record(unavailable)
        XCTAssertEqual(afterUnavailable, samples)
    }

    func testReplacesSamplesInsideOneMinuteBucket() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = QuotaHistoryStore(
            fileURL: fileURL,
            now: { Date(timeIntervalSince1970: 10_000) }
        )

        _ = await store.record(makeSnapshot(at: 9_000, remaining: 0.8))
        let samples = await store.record(makeSnapshot(at: 9_030, remaining: 0.7))

        XCTAssertEqual(samples.count, 1)
        XCTAssertEqual(samples[0].recordedAt, Date(timeIntervalSince1970: 9_030))
        XCTAssertEqual(samples[0].values[0].remainingRatio, 0.7)
    }

    func testMinuteRefreshesAppendInEachFixedMinuteBucket() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = QuotaHistoryStore(
            fileURL: fileURL,
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        for minute in 0...6 {
            _ = await store.record(makeSnapshot(at: TimeInterval(600 + minute * 60), remaining: 0.8))
        }

        let samples = await store.load(accountID: "A")
        XCTAssertEqual(samples.count, 7)
        XCTAssertEqual(samples.map { Int($0.recordedAt.timeIntervalSince1970) }, [600, 660, 720, 780, 840, 900, 960])
    }

    func testRetainsThirtyDaysAndPersistsToDisk() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let now = Date(timeIntervalSince1970: 4_000_000)
        let store = QuotaHistoryStore(fileURL: fileURL, now: { now })

        _ = await store.record(makeSnapshot(at: now.timeIntervalSince1970 - 31 * 86_400, remaining: 0.9))
        _ = await store.record(makeSnapshot(at: now.timeIntervalSince1970 - 1_000, remaining: 0.6))

        let reloaded = await QuotaHistoryStore(fileURL: fileURL, now: { now }).load(accountID: "A")
        XCTAssertEqual(reloaded.count, 1)
        XCTAssertEqual(reloaded[0].values[0].remainingRatio, 0.6)
    }

    func testLegacyUnownedHistoryIsNotAssignedToCurrentAccount() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(
            """
            [{
              "providerID": "codex-oauth",
              "recordedAt": -978298200,
              "values": [{
                "windowID": "codex-primary",
                "labelKey": "quota.window.codex.7d",
                "remainingRatio": 0.75,
                "resetAt": null
              }]
            }]
            """.utf8
        ).write(to: fileURL)
        let store = QuotaHistoryStore(
            fileURL: fileURL,
            retention: 10_000,
            now: { Date(timeIntervalSince1970: 10_000) }
        )

        let samples = await store.load(accountID: "A")

        XCTAssertTrue(samples.isEmpty)
        let original = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode([QuotaHistorySample].self, from: original)
        XCTAssertNil(decoded.first?.values.first?.displayLabel)
    }

    func testAccountSwitchAndRestartKeepIndependentHistory() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = QuotaHistoryStore(fileURL: fileURL, now: { Date(timeIntervalSince1970: 10_000) })
        _ = await store.record(makeSnapshot(at: 9_000, remaining: 0.8, accountID: "A"))
        let b = await store.record(makeSnapshot(at: 9_030, remaining: 0.4, accountID: "B"))
        XCTAssertEqual(b.count, 1)
        XCTAssertEqual(b.first?.values.first?.remainingRatio, 0.4)
        let a = await store.load(accountID: "A")
        XCTAssertEqual(a.first?.values.first?.remainingRatio, 0.8)
        let restarted = QuotaHistoryStore(fileURL: fileURL, now: { Date(timeIntervalSince1970: 10_000) })
        let reloaded = await restarted.load(accountID: "B")
        XCTAssertEqual(reloaded, b)
        let unknown = await restarted.record(makeSnapshot(at: 9_060, remaining: 0.1, accountID: nil))
        XCTAssertTrue(unknown.isEmpty)
        let loggedOut = await restarted.load(accountID: nil)
        XCTAssertTrue(loggedOut.isEmpty)
    }

    func testLegacyFileIsBackedUpByteForByteAndUntouchedByNewWrites() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let legacy = fileURL.deletingLastPathComponent().appendingPathComponent("legacy.json")
        let original = Data("[broken legacy data preserved]".utf8)
        try original.write(to: legacy)
        let store = QuotaHistoryStore(fileURL: fileURL, legacyFileURL: legacy, now: { Date(timeIntervalSince1970: 10_000) })
        let samples = await store.record(makeSnapshot(at: 9_000, remaining: 0.8))
        XCTAssertEqual(samples.count, 1)
        let legacyPreserved = await store.hasUnassignedLegacyHistory()
        XCTAssertTrue(legacyPreserved)
        XCTAssertEqual(try Data(contentsOf: legacy), original)
        XCTAssertEqual(try Data(contentsOf: legacy.appendingPathExtension("legacy-backup")), original)
        let restarted = QuotaHistoryStore(fileURL: fileURL, legacyFileURL: legacy, now: { Date(timeIntervalSince1970: 10_000) })
        let loaded = await restarted.load(accountID: "A")
        XCTAssertEqual(loaded, samples)
        let stored = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertFalse(stored.contains("\"accountID\""))
        XCTAssertFalse(stored.contains("\"A\""))
    }

    func testCorruptScopedFileIsNeverOverwritten() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = Data("not JSON".utf8)
        try original.write(to: fileURL)
        let store = QuotaHistoryStore(fileURL: fileURL, now: { Date(timeIntervalSince1970: 10_000) })
        _ = await store.record(makeSnapshot(at: 9_000, remaining: 0.8))
        XCTAssertEqual(try Data(contentsOf: fileURL), original)
    }

    func testStaleAndOutOfOrderReadingsCannotRewriteHistory() async {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = QuotaHistoryStore(fileURL: fileURL, now: { Date(timeIntervalSince1970: 10_000) })
        let first = await store.record(makeSnapshot(at: 9_000, remaining: 0.8))
        let earlier = await store.record(makeSnapshot(at: 8_000, remaining: 0.9))
        XCTAssertEqual(earlier, first)
        let stale = makeSnapshot(at: -4_000_000, remaining: 0.1)
        let unchanged = await store.record(stale)
        XCTAssertEqual(unchanged, first)
    }

    func testBlockedLegacyBackupDoesNotReplaceLegacyOrCreateScopedFile() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let legacy = fileURL.deletingLastPathComponent().appendingPathComponent("legacy.json")
        let original = Data("legacy bytes".utf8)
        try original.write(to: legacy)
        // A broken symlink cannot be mistaken for a completed backup or overwritten.
        try FileManager.default.createSymbolicLink(atPath: legacy.appendingPathExtension("legacy-backup").path, withDestinationPath: fileURL.appendingPathExtension("missing").path)
        let store = QuotaHistoryStore(fileURL: fileURL, legacyFileURL: legacy, now: { Date(timeIntervalSince1970: 10_000) })
        let result = await store.record(makeSnapshot(at: 9_000, remaining: 0.8))
        XCTAssertTrue(result.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try Data(contentsOf: legacy), original)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("history.json")
    }

    private func makeSnapshot(
        at timestamp: TimeInterval,
        remaining: Double,
        status: ProviderStatus = .available,
        accountID: String? = "A"
    ) -> ProviderQuotaSnapshot {
        let date = Date(timeIntervalSince1970: timestamp)
        return ProviderQuotaSnapshot(
            providerId: "codex-oauth",
            displayName: "Codex",
            status: status,
            source: .oauthAPI,
            refreshedAt: date,
            staleAfter: date.addingTimeInterval(40 * 86_400),
            windows: [
                QuotaWindow(
                    id: "codex-primary",
                    labelKey: "quota.window.codex.5h",
                    displayLabel: "Codex allowance",
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
            errors: [], accountID: accountID
        )
    }
}

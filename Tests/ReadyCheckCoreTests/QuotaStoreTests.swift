import XCTest
@testable import ReadyCheckCore

final class QuotaStoreTests: XCTestCase {
    func testTransportFailureKeepsOnlySameAccountLastKnownValuesAndOriginalTime() async throws {
        let provider = AccountSequenceProvider(accounts: ["A", "A", "A"], statuses: [.available, .unavailable, .unavailable], errors: [[], ["quota.error.requestFailed"], ["quota.error.requestFailed"]])
        let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))
        await store.refreshAll(reason: .manual)
        let originals = await store.snapshots
        let original = try XCTUnwrap(originals.first)
        await store.refreshAll(reason: .manual)
        let cachedSnapshots = await store.snapshots
        let cached = try XCTUnwrap(cachedSnapshots.first)
        XCTAssertEqual(cached.windows, original.windows)
        XCTAssertEqual(cached.refreshedAt, original.refreshedAt)
        XCTAssertEqual(cached.accountID, "A")
        XCTAssertEqual(cached.isCached, true)
        XCTAssertEqual(cached.status, .unavailable)
        XCTAssertTrue(cached.isStale(now: cached.refreshedAt))
        XCTAssertTrue(cached.canShowPercentages(now: cached.refreshedAt.addingTimeInterval(3600)))
        XCTAssertNil(cached.ordinaryUsageAllowed)
        let baseline = LowQuotaReminderState(account: "A", windows: [:])
        XCTAssertTrue(LowQuotaReminderEvaluator.evaluate(snapshot: cached, now: cached.refreshedAt, account: "A", threshold: 5, state: baseline).alerts.isEmpty)
        XCTAssertFalse(QuotaRecoveryRequest.canArm(cached, now: cached.refreshedAt))
        await store.refreshAll(reason: .manual)
        let repeated = await store.snapshots.first
        XCTAssertEqual(repeated?.refreshedAt, original.refreshedAt)
    }

    func testTransportRecoveryReplacesCachedSnapshotWithFreshReading() async throws {
        let provider = AccountSequenceProvider(accounts: ["A", "A", "A"], statuses: [.available, .unavailable, .available], errors: [[], ["quota.error.requestFailed"], []])
        let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))
        await store.refreshAll(reason: .manual)
        let originalSnapshots = await store.snapshots
        let original = try XCTUnwrap(originalSnapshots.first)
        await store.refreshAll(reason: .manual)
        let cachedSnapshots = await store.snapshots
        let cached = try XCTUnwrap(cachedSnapshots.first)
        XCTAssertEqual(cached.isCached, true)
        await store.refreshAll(reason: .manual)
        let recoveredSnapshots = await store.snapshots
        let recovered = try XCTUnwrap(recoveredSnapshots.first)
        XCTAssertEqual(recovered.accountID, "A")
        XCTAssertEqual(recovered.status, .available)
        XCTAssertNotEqual(recovered.isCached, true)
        XCTAssertFalse(recovered.isStale(now: recovered.refreshedAt))
        XCTAssertGreaterThan(recovered.refreshedAt, original.refreshedAt)
        XCTAssertEqual(recovered.ordinaryUsageAllowed, true)
        XCTAssertTrue(recovered.errors.isEmpty)
        let baseline = LowQuotaReminderState(account: "A", windows: [:])
        let result = LowQuotaReminderEvaluator.evaluate(snapshot: recovered, now: recovered.refreshedAt, account: "A", threshold: 5, state: baseline)
        XCTAssertTrue(result.alerts.isEmpty, "Recovery establishes a fresh baseline; it must not replay an initial low reading")
        XCTAssertEqual(result.state?.windows.count, 1)
        let repeated = LowQuotaReminderEvaluator.evaluate(snapshot: recovered, now: recovered.refreshedAt, account: "A", threshold: 5, state: result.state)
        XCTAssertTrue(repeated.alerts.isEmpty)
    }

    func testAccountChangeMissingIdentityAndAuthorizationNeverBorrowCachedValues() async {
        for (account, error) in [("B", "quota.error.requestFailed"), (nil, "quota.error.requestFailed"), ("A", "quota.error.authorizationRejected"), ("A", "quota.error.tokenRefreshFailed"), ("A", "quota.error.parserUnavailable")] as [(String?, String)] {
            let provider = AccountSequenceProvider(accounts: ["A", account], statuses: [.available, .unavailable], errors: [[], [error]])
            let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))
            await store.refreshAll(reason: .manual)
            await store.refreshAll(reason: .manual)
            let failed = await store.snapshots.first
            XCTAssertTrue(failed?.windows.isEmpty == true)
            XCTAssertNotEqual(failed?.isCached, true)
        }
    }

    func testAccountSwitchDoesNotCarrySupplementalDetails() async {
        let provider = AccountSequenceProvider(accounts: ["A", "B"], statuses: [.available, .available], errors: [[], []])
        let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))
        await store.refreshAll(reason: .manual)
        await store.refreshAll(reason: .manual)
        let switched = await store.snapshots.first
        XCTAssertEqual(switched?.accountID, "B")
        XCTAssertNil(switched?.details?.accountTokenUsage)
        XCTAssertEqual(switched?.details?.manualResetExpirations, [])
    }

    func testRefreshStoresSnapshot() async {
        let provider = MockQuotaProvider(now: { Date(timeIntervalSince1970: 1_000) })
        let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))

        await store.refreshAll(reason: .manual)

        let snapshots = await store.snapshots
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.providerId, "mock")
    }

    func testRefreshStoresErrorSnapshotWhenProviderThrows() async {
        let provider = ThrowingQuotaProvider(id: "throwing", displayName: "Throwing")
        let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))

        await store.refreshAll(reason: .manual)

        let snapshots = await store.snapshots
        XCTAssertEqual(snapshots.count, 1)
        let snapshot = snapshots[0]
        XCTAssertEqual(snapshot.providerId, "throwing")
        XCTAssertEqual(snapshot.displayName, "Throwing")
        XCTAssertEqual(snapshot.status, .error)
        XCTAssertEqual(snapshot.source, .manual)
        XCTAssertEqual(snapshot.windows, [])
        XCTAssertEqual(snapshot.errors, ["provider failed"])
        XCTAssertEqual(snapshot.staleAfter.timeIntervalSince(snapshot.refreshedAt), 60, accuracy: 0.001)
    }

    func testRefreshReturnsSnapshotsInRegistryOrderWithMixedSuccessAndFailure() async {
        let providers: [any QuotaProvider] = [
            StaticQuotaProvider(id: "first", displayName: "First", batch: 1),
            ThrowingQuotaProvider(id: "second", displayName: "Second"),
            StaticQuotaProvider(id: "third", displayName: "Third", batch: 1)
        ]
        let store = QuotaStore(registry: ProviderRegistry(providers: providers))

        await store.refreshAll(reason: .manual)

        let snapshots = await store.snapshots
        XCTAssertEqual(snapshots.map(\.providerId), ["first", "second", "third"])
        XCTAssertEqual(snapshots.map(\.status), [.available, .error, .available])
        XCTAssertEqual(snapshots[1].windows, [])
        XCTAssertEqual(snapshots[1].errors, ["provider failed"])
    }

    func testOverlappingRefreshesShareActiveBatch() async {
        let state = DelayedQuotaProviderState()
        let provider = DelayedQuotaProvider(state: state)
        let store = QuotaStore(registry: ProviderRegistry(providers: [provider]))

        let firstRefresh = Task {
            await store.refreshAll(reason: .manual)
        }
        await state.waitUntilFetchStarted()

        let secondRefresh = Task {
            await store.refreshAll(reason: .automatic)
        }
        try? await Task.sleep(nanoseconds: 20_000_000)

        await state.releaseAll()
        await firstRefresh.value
        await secondRefresh.value

        let snapshots = await store.snapshots
        let fetchCount = await state.fetchCount
        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].displayName, "Delayed fetch 1")
    }

    func testSnapshotsKeepPreviousCompletedBatchDuringRefresh() async {
        let state = PartialBatchQuotaProviderState()
        let providers: [any QuotaProvider] = [
            PartialBatchQuotaProvider(id: "first", displayName: "First", state: state),
            PartialBatchQuotaProvider(id: "second", displayName: "Second", state: state)
        ]
        let store = QuotaStore(registry: ProviderRegistry(providers: providers))
        await store.refreshAll(reason: .manual)
        let initialSnapshots = await store.snapshots
        XCTAssertEqual(initialSnapshots.map(\.displayName), ["First batch 1", "Second batch 1"])

        let refresh = Task {
            await store.refreshAll(reason: .automatic)
        }
        await state.waitUntilSecondProviderIsSuspended()

        let snapshotsDuringRefresh = await store.snapshots
        XCTAssertEqual(snapshotsDuringRefresh.map(\.displayName), ["First batch 1", "Second batch 1"])

        await state.releaseSecondProvider()
        await refresh.value

        let snapshotsAfterRefresh = await store.snapshots
        XCTAssertEqual(snapshotsAfterRefresh.map(\.displayName), ["First batch 2", "Second batch 2"])
    }

    func testManualResetDetailsPreserveUnexpiredSuccessfulResultWhenNextRefreshIsUnavailable() {
        let expiration = Date(timeIntervalSince1970: 10_000)
        let previous = ProviderQuotaDetails(
            manualResetCount: 1,
            manualResetExpirations: [expiration]
        )
        let unavailable = ProviderQuotaDetails(manualResetCount: nil, manualResetExpirations: [])

        let merged = unavailable.preservingSupplementalDetails(
            from: previous,
            now: Date(timeIntervalSince1970: 9_000)
        )

        XCTAssertEqual(merged.manualResetCount, 1)
        XCTAssertEqual(merged.manualResetExpirations, [expiration])
    }

    func testManualResetDetailsClearOnlyWhenServerExplicitlyReturnsZero() {
        let previous = ProviderQuotaDetails(
            manualResetCount: 1,
            manualResetExpirations: [Date(timeIntervalSince1970: 10_000)]
        )
        let zero = ProviderQuotaDetails(manualResetCount: 0, manualResetExpirations: [])

        let merged = zero.preservingSupplementalDetails(
            from: previous,
            now: Date(timeIntervalSince1970: 9_000)
        )

        XCTAssertEqual(merged.manualResetCount, 0)
        XCTAssertEqual(merged.manualResetExpirations, [])
    }

    func testSnapshotUsesPersistedVerifiedExpirationWhenCurrentDetailsAreUnavailable() {
        let now = Date(timeIntervalSince1970: 9_000)
        let expiration = Date(timeIntervalSince1970: 10_000)
        let snapshot = ProviderQuotaSnapshot(
            providerId: "codex-oauth",
            displayName: "Codex",
            status: .available,
            source: .appServer,
            refreshedAt: now,
            staleAfter: now.addingTimeInterval(300),
            windows: [],
            errors: [],
            details: ProviderQuotaDetails(manualResetCount: nil)
        )

        let merged = snapshot.preservingKnownManualResetExpirations([expiration], now: now)

        XCTAssertEqual(merged.details?.manualResetCount, 1)
        XCTAssertEqual(merged.details?.manualResetExpirations, [expiration])
    }

    func testSnapshotExplicitZeroOverridesPersistedVerifiedExpiration() {
        let now = Date(timeIntervalSince1970: 9_000)
        let snapshot = ProviderQuotaSnapshot(
            providerId: "codex-oauth",
            displayName: "Codex",
            status: .available,
            source: .appServer,
            refreshedAt: now,
            staleAfter: now.addingTimeInterval(300),
            windows: [],
            errors: [],
            details: ProviderQuotaDetails(manualResetCount: 0)
        )

        let merged = snapshot.preservingKnownManualResetExpirations(
            [Date(timeIntervalSince1970: 10_000)],
            now: now
        )

        XCTAssertEqual(merged.details?.manualResetCount, 0)
        XCTAssertEqual(merged.details?.manualResetExpirations, [])
    }
}

private struct StaticQuotaProvider: QuotaProvider {
    let id: String
    let displayName: String
    let batch: Int

    func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        makeSnapshot(providerId: id, displayName: displayName, batch: batch)
    }
}

private struct ThrowingQuotaProvider: QuotaProvider {
    let id: String
    let displayName: String

    func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        throw TestProviderError.failure
    }
}

private struct DelayedQuotaProvider: QuotaProvider {
    let id = "delayed"
    let displayName = "Delayed"
    let state: DelayedQuotaProviderState

    func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        await state.fetch(providerId: id, displayName: displayName)
    }
}

private actor DelayedQuotaProviderState {
    private(set) var fetchCount = 0
    private var fetchStartedContinuations: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []

    func fetch(providerId: String, displayName: String) async -> ProviderQuotaSnapshot {
        fetchCount += 1
        let fetchNumber = fetchCount
        let continuations = fetchStartedContinuations
        fetchStartedContinuations = []
        continuations.forEach { $0.resume() }

        await withCheckedContinuation { continuation in
            releaseContinuations.append(continuation)
        }

        return makeSnapshot(providerId: providerId, displayName: "\(displayName) fetch \(fetchNumber)", batch: fetchNumber)
    }

    func waitUntilFetchStarted() async {
        guard fetchCount == 0 else { return }

        await withCheckedContinuation { continuation in
            fetchStartedContinuations.append(continuation)
        }
    }

    func releaseAll() {
        let continuations = releaseContinuations
        releaseContinuations = []
        continuations.forEach { $0.resume() }
    }
}

private struct PartialBatchQuotaProvider: QuotaProvider {
    let id: String
    let displayName: String
    let state: PartialBatchQuotaProviderState

    func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        await state.fetch(providerId: id, displayName: displayName)
    }
}

private actor PartialBatchQuotaProviderState {
    private var callCountByProvider: [String: Int] = [:]
    private var secondProviderIsSuspended = false
    private var secondProviderSuspendedContinuations: [CheckedContinuation<Void, Never>] = []
    private var releaseSecondProviderContinuation: CheckedContinuation<Void, Never>?

    func fetch(providerId: String, displayName: String) async -> ProviderQuotaSnapshot {
        let callCount = (callCountByProvider[providerId] ?? 0) + 1
        callCountByProvider[providerId] = callCount

        if providerId == "second", callCount == 2 {
            secondProviderIsSuspended = true
            let continuations = secondProviderSuspendedContinuations
            secondProviderSuspendedContinuations = []
            continuations.forEach { $0.resume() }

            await withCheckedContinuation { continuation in
                releaseSecondProviderContinuation = continuation
            }
        }

        return makeSnapshot(providerId: providerId, displayName: "\(displayName) batch \(callCount)", batch: callCount)
    }

    func waitUntilSecondProviderIsSuspended() async {
        guard !secondProviderIsSuspended else { return }

        await withCheckedContinuation { continuation in
            secondProviderSuspendedContinuations.append(continuation)
        }
    }

    func releaseSecondProvider() {
        releaseSecondProviderContinuation?.resume()
        releaseSecondProviderContinuation = nil
    }
}

private enum TestProviderError: Error, CustomStringConvertible {
    case failure

    var description: String {
        "provider failed"
    }
}

private func makeSnapshot(providerId: String, displayName: String, batch: Int) -> ProviderQuotaSnapshot {
    let date = Date(timeIntervalSince1970: TimeInterval(1_000 + batch))
    return ProviderQuotaSnapshot(
        providerId: providerId,
        displayName: displayName,
        status: .available,
        source: .mock,
        refreshedAt: date,
        staleAfter: date.addingTimeInterval(60),
        windows: [
            QuotaWindow(
                id: "\(providerId)-window-\(batch)",
                labelKey: "quota.window.test",
                kind: .manual,
                used: Double(batch),
                limit: 10,
                remaining: 10 - Double(batch),
                unit: .requests,
                resetAt: nil,
                confidence: .manual
            )
        ],
        errors: []
    )
}

private actor AccountSequenceProvider: QuotaProvider {
    nonisolated let id = "codex-oauth"
    nonisolated let displayName = "Codex"
    let accounts: [String?]
    let statuses: [ProviderStatus]
    let errors: [[String]]
    var index = 0

    init(accounts: [String?], statuses: [ProviderStatus], errors: [[String]]) {
        self.accounts = accounts
        self.statuses = statuses
        self.errors = errors
    }

    func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot {
        let tick = min(index, accounts.count - 1)
        index += 1
        let date = Date(timeIntervalSince1970: TimeInterval(10_000 + tick))
        let available = statuses[tick] == .available
        return ProviderQuotaSnapshot(providerId: id, displayName: displayName, status: statuses[tick],
            source: .oauthAPI, refreshedAt: date, staleAfter: date.addingTimeInterval(300),
            windows: available ? [QuotaWindow(id: "short", labelKey: "quota.fiveHour", kind: .rolling,
                used: 96, limit: 100, remaining: 4, unit: .percent, resetAt: date.addingTimeInterval(300), confidence: .verified)] : [],
            errors: errors[tick], details: available ? ProviderQuotaDetails(
                manualResetCount: tick == 0 ? 1 : nil,
                manualResetExpirations: tick == 0 ? [date.addingTimeInterval(3600)] : [],
                accountTokenUsage: tick == 0 ? AccountTokenUsage(summary: AccountTokenUsageSummary(lifetimeTokens: 123), dailyBuckets: []) : nil) : nil,
            ordinaryUsageAllowed: available ? true : nil, accountID: accounts[tick])
    }
}

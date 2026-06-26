import XCTest
@testable import ReadyCheckCore

final class QuotaStoreTests: XCTestCase {
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

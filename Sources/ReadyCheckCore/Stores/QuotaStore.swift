import Foundation

public actor QuotaStore {
    private let registry: ProviderRegistry
    private var snapshotByProvider: [String: ProviderQuotaSnapshot] = [:]
    private var isRefreshing = false
    private var refreshWaiters: [CheckedContinuation<Void, Never>] = []

    public init(registry: ProviderRegistry) {
        self.registry = registry
    }

    public var snapshots: [ProviderQuotaSnapshot] {
        registry.providers.compactMap { snapshotByProvider[$0.id] }
    }

    public func refreshAll(reason: RefreshReason) async {
        if isRefreshing {
            await waitForActiveRefresh()
            return
        }

        isRefreshing = true
        var nextSnapshotByProvider: [String: ProviderQuotaSnapshot] = [:]

        for provider in registry.providers {
            do {
                let snapshot = try await provider.fetchSnapshot(context: ProviderRefreshContext(reason: reason))
                nextSnapshotByProvider[provider.id] = preservingSupplementalDetails(
                    in: snapshot,
                    previous: snapshotByProvider[provider.id]
                )
            } catch {
                let now = Date()
                nextSnapshotByProvider[provider.id] = ProviderQuotaSnapshot(
                    providerId: provider.id,
                    displayName: provider.displayName,
                    status: .error,
                    source: .manual,
                    refreshedAt: now,
                    staleAfter: now.addingTimeInterval(60),
                    windows: [],
                    errors: [String(describing: error)]
                )
            }
        }

        snapshotByProvider = nextSnapshotByProvider
        isRefreshing = false
        let waiters = refreshWaiters
        refreshWaiters = []
        waiters.forEach { $0.resume() }
    }

    private func waitForActiveRefresh() async {
        await withCheckedContinuation { continuation in
            refreshWaiters.append(continuation)
        }
    }

    private func preservingSupplementalDetails(
        in snapshot: ProviderQuotaSnapshot,
        previous: ProviderQuotaSnapshot?
    ) -> ProviderQuotaSnapshot {
        guard snapshot.status == .available,
              let details = snapshot.details,
              let previousDetails = previous?.details
        else {
            return snapshot
        }

        return ProviderQuotaSnapshot(
            providerId: snapshot.providerId,
            displayName: snapshot.displayName,
            status: snapshot.status,
            source: snapshot.source,
            refreshedAt: snapshot.refreshedAt,
            staleAfter: snapshot.staleAfter,
            windows: snapshot.windows,
            errors: snapshot.errors,
            details: details.preservingSupplementalDetails(
                from: previousDetails,
                now: snapshot.refreshedAt
            )
        )
    }
}

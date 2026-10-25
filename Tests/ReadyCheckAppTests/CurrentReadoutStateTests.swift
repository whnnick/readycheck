import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

final class CurrentReadoutStateTests: XCTestCase {
    func testOldSuccessCannotHideFailedCachedOrStaleReadings() {
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        func snapshot(_ status: ProviderStatus = .available, cached: Bool = false, stale: Bool = false) -> ProviderQuotaSnapshot {
            .init(providerId: "codex-oauth", displayName: "Codex", status: status, source: .appServer,
                refreshedAt: now.addingTimeInterval(-60), staleAfter: now.addingTimeInterval(stale ? -1 : 240),
                windows: [], errors: [], ordinaryUsageAllowed: true, isCached: cached)
        }
        func state(_ value: ProviderQuotaSnapshot?, refreshing: Bool = false, credentials: Bool = false) -> CurrentReadoutState {
            .init(snapshot: value, refreshing: refreshing, credentialsUnavailable: credentials, now: now)
        }
        XCTAssertEqual(state(nil), .waiting)
        XCTAssertEqual(state(snapshot()), .current)
        XCTAssertEqual(state(snapshot(.unavailable)), .unavailable)
        XCTAssertEqual(state(snapshot(cached: true)), .cached)
        XCTAssertEqual(state(snapshot(stale: true)), .stale)
        XCTAssertEqual(state(snapshot(.unavailable, stale: true)), .unavailable)
        XCTAssertEqual(state(snapshot(), refreshing: true), .refreshing)
        XCTAssertEqual(state(snapshot(), refreshing: true, credentials: true), .credentials)
    }
}

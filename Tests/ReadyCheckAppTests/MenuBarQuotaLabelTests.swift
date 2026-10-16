import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

final class MenuBarQuotaLabelTests: XCTestCase {
    func testMenuBarShowsSelectedVerifiedQuotaAndNeverFallsBackOrShowsCacheAsCurrent() {
        let now = Date()
        let window = QuotaWindow(id: "short", labelKey: "quota.window.codex.5h", kind: .rolling,
            used: 20, limit: 100, remaining: 80, unit: .percent, resetAt: nil, confidence: .verified)
        func snapshot(cached: Bool = false, stale: Bool = false) -> ProviderQuotaSnapshot {
            ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available,
                source: .appServer, refreshedAt: now, staleAfter: now.addingTimeInterval(stale ? -1 : 300),
                windows: [window], errors: [], isCached: cached)
        }
        XCTAssertEqual(MenuBarQuotaLabel.text(snapshot: snapshot(), selection: .fiveHour, now: now), "5h 80%")
        XCTAssertEqual(MenuBarQuotaLabel.text(snapshot: snapshot(), selection: .sevenDay, now: now), "7d —")
        XCTAssertEqual(MenuBarQuotaLabel.text(snapshot: snapshot(cached: true), selection: .fiveHour, now: now), "5h —")
        XCTAssertEqual(MenuBarQuotaLabel.text(snapshot: snapshot(stale: true), selection: .fiveHour, now: now), "5h —")
    }
}

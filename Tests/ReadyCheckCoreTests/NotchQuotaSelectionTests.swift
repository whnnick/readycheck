import XCTest
@testable import ReadyCheckCore

final class NotchQuotaSelectionTests: XCTestCase {
    func testMatchesOnlySelectedWindowIncludingLegacyLabels() {
        XCTAssertTrue(NotchQuotaSelection.fiveHour.matches(labelKey: "quota.window.codex.5h"))
        XCTAssertTrue(NotchQuotaSelection.fiveHour.matches(labelKey: "quota.fiveHour"))
        XCTAssertFalse(NotchQuotaSelection.fiveHour.matches(labelKey: "quota.window.codex.7d"))
        XCTAssertTrue(NotchQuotaSelection.sevenDay.matches(labelKey: "quota.window.codex.7d"))
        XCTAssertTrue(NotchQuotaSelection.sevenDay.matches(labelKey: "quota.sevenDay"))
        XCTAssertFalse(NotchQuotaSelection.sevenDay.matches(labelKey: "quota.window.codex.5h"))
        XCTAssertFalse(NotchQuotaSelection.sevenDay.matches(labelKey: "unknown"))
    }

    func testDefaultAndPersistence() {
        let suite = "NotchQuotaSelectionTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .sevenDay)
        NotchQuotaSelection.fiveHour.persist(defaults: defaults)
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .fiveHour)
        NotchQuotaSelection.sevenDay.persist(defaults: defaults)
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .sevenDay)
    }
}

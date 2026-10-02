import XCTest
@testable import ReadyCheckCore

final class NotchQuotaSelectionTests: XCTestCase {
    func testSelectedWindowFallsBackToAnAvailableWindow() {
        let fifteenMinute = window(id: "codex-primary", labelKey: "quota.window.codex.primary", duration: 15)
        let sevenDay = window(id: "codex-secondary", labelKey: "quota.window.codex.7d", duration: 10_080)
        XCTAssertEqual(NotchQuotaSelection.sevenDay.resolve(in: [fifteenMinute, sevenDay])?.id, sevenDay.id)
        XCTAssertEqual(NotchQuotaSelection.sevenDay.resolve(in: [fifteenMinute])?.id, fifteenMinute.id)
        XCTAssertEqual(NotchQuotaSelection.window("missing").resolve(in: [fifteenMinute])?.id, fifteenMinute.id)
        XCTAssertFalse(NotchQuotaSelection.window("missing").hasPreferredWindow(in: [fifteenMinute]))
        XCTAssertTrue(NotchQuotaSelection.window(fifteenMinute.id).hasPreferredWindow(in: [fifteenMinute]))
        XCTAssertFalse(NotchQuotaSelection.sevenDay.hasPreferredWindow(in: [fifteenMinute]))
        XCTAssertNil(NotchQuotaSelection.automatic.resolve(in: []))
        XCTAssertEqual(QuotaWindowDisplay.shortLabel(for: fifteenMinute), "15m")
        XCTAssertEqual(
            QuotaWindowDisplay.title(for: fifteenMinute, localization: LocalizationService(language: .zhCN)),
            "15m 配额"
        )
    }

    func testLegacyPreferenceAndDynamicWindowPersistence() {
        let suite = "NotchQuotaSelectionTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .sevenDay)
        defaults.set("fiveHour", forKey: "ReadyCheck.notchQuotaSelection.v1")
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .fiveHour)
        NotchQuotaSelection.window("codex_other-primary").persist(defaults: defaults)
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .window("codex_other-primary"))
        NotchQuotaSelection.automatic.persist(defaults: defaults)
        XCTAssertEqual(NotchQuotaSelection.value(defaults: defaults), .automatic)
    }

    func testMissingPreferenceStaysSelectedWhileDisplayFallsBackAndRecovers() {
        let weekly = window(id: "weekly", labelKey: "quota.window.codex.7d", duration: 10_080)
        let extra = window(id: "extra", labelKey: "quota.window.dynamic", duration: 60)
        let preference = NotchQuotaSelection.window(extra.id)
        XCTAssertEqual(preference.pickerSelection(in: [weekly]), preference)
        XCTAssertEqual(preference.resolve(in: [weekly])?.id, weekly.id)
        XCTAssertEqual(preference.resolve(in: [weekly, extra])?.id, extra.id)
        XCTAssertEqual(preference.pickerSelection(in: []), preference)
        XCTAssertNil(preference.resolve(in: []))
    }

    func testMissingLegacyPreferenceDoesNotMasqueradeAsFallbackInPicker() {
        let weekly = window(id: "weekly", labelKey: "quota.window.codex.7d", duration: 10_080)
        XCTAssertEqual(NotchQuotaSelection.fiveHour.pickerSelection(in: [weekly]), .fiveHour)
        XCTAssertEqual(NotchQuotaSelection.sevenDay.pickerSelection(in: [weekly]), .window(weekly.id))
        XCTAssertEqual(NotchQuotaSelection.automatic.pickerSelection(in: [weekly]), .automatic)
    }

    private func window(id: String, labelKey: String, duration: Int) -> QuotaWindow {
        QuotaWindow(
            id: id,
            labelKey: labelKey,
            kind: .rolling,
            used: 20,
            limit: 100,
            remaining: 80,
            unit: .percent,
            resetAt: nil,
            confidence: .verified,
            durationMinutes: duration
        )
    }
}

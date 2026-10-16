import XCTest
@testable import ReadyCheckCore

final class NotchQuotaSelectionTests: XCTestCase {
    func testOnlyAutomaticSelectionFallsBackToAnAvailableWindow() {
        let fifteenMinute = window(id: "codex-primary", labelKey: "quota.window.codex.primary", duration: 15)
        let sevenDay = window(id: "codex-secondary", labelKey: "quota.window.codex.7d", duration: 10_080)
        XCTAssertEqual(NotchQuotaSelection.sevenDay.resolve(in: [fifteenMinute, sevenDay])?.id, sevenDay.id)
        XCTAssertNil(NotchQuotaSelection.sevenDay.resolve(in: [fifteenMinute]))
        XCTAssertNil(NotchQuotaSelection.window("missing").resolve(in: [fifteenMinute]))
        XCTAssertEqual(NotchQuotaSelection.automatic.resolve(in: [fifteenMinute])?.id, fifteenMinute.id)
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

    func testMissingExplicitSelectionKeepsUnknownPrimaryAndOtherWindowsVisible() {
        let fiveHour = window(id: "short", labelKey: "quota.window.codex.5h", duration: 300)
        let displayed = NotchQuotaSelection.sevenDay.displayWindows(in: [fiveHour])
        XCTAssertEqual(displayed.first?.labelKey, "quota.window.codex.7d")
        XCTAssertNil(displayed.first?.remainingRatio)
        XCTAssertEqual(displayed.first?.confidence, .unknown)
        XCTAssertEqual(displayed.last?.id, fiveHour.id)
        XCTAssertEqual(NotchQuotaSelection.sevenDay.displayWindows(in: [fiveHour], primaryFirst: false).last?.labelKey, "quota.window.codex.7d")
        let weekly = window(id: "weekly", labelKey: "quota.window.codex.7d", duration: 10_080)
        XCTAssertEqual(NotchQuotaSelection.sevenDay.displayWindows(in: [fiveHour, weekly]).map(\.id), [weekly.id, fiveHour.id])
        XCTAssertEqual(NotchQuotaSelection.window("saved").displayWindows(in: [fiveHour]).first?.id, "saved")
        XCTAssertTrue(NotchQuotaSelection.automatic.displayWindows(in: []).isEmpty)
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

    func testMissingPreferenceStaysUnknownAndRecovers() {
        let weekly = window(id: "weekly", labelKey: "quota.window.codex.7d", duration: 10_080)
        let extra = window(id: "extra", labelKey: "quota.window.dynamic", duration: 60)
        let preference = NotchQuotaSelection.window(extra.id)
        XCTAssertEqual(preference.pickerSelection(in: [weekly]), preference)
        XCTAssertNil(preference.resolve(in: [weekly]))
        XCTAssertEqual(preference.resolve(in: [weekly, extra])?.id, extra.id)
        XCTAssertEqual(preference.pickerSelection(in: []), preference)
        XCTAssertNil(preference.resolve(in: []))
    }

    func testSavedLabelSurvivesRestartWithoutRetainingAQuotaValue() {
        let suite = "NotchQuotaSelectionTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let weekly = window(id: "weekly", labelKey: "quota.window.codex.7d", duration: 10_080)
        NotchQuotaSelection.window(weekly.id).persist(defaults: defaults, windows: [weekly])
        let selection = NotchQuotaSelection.value(defaults: defaults)
        let missing = selection.displayWindows(in: [], defaults: defaults).first
        XCTAssertEqual(missing.map(QuotaWindowDisplay.shortLabel), "7d")
        XCTAssertNil(missing?.remainingRatio)
        XCTAssertNil(missing?.resetAt)
        XCTAssertEqual(selection.resolve(in: [weekly]), weekly)
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

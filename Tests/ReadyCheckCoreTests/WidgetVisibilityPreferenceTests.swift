import Foundation
import XCTest
@testable import ReadyCheckCore

final class WidgetVisibilityPreferenceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WidgetVisibilityPreferenceTests")!
        defaults.removePersistentDomain(forName: "WidgetVisibilityPreferenceTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WidgetVisibilityPreferenceTests")
        defaults = nil
        super.tearDown()
    }

    func testDefaultsToVisibleForNewPreferenceVersion() {
        XCTAssertTrue(WidgetVisibilityPreference.value(defaults: defaults))
    }

    func testPreservesHiddenChoiceFromPreviousSession() {
        defaults.set(false, forKey: WidgetVisibilityPreference.defaultsKey)

        XCTAssertFalse(WidgetVisibilityPreference.value(defaults: defaults))
    }

    func testExplicitVisibilityChoicesRoundTrip() {
        WidgetVisibilityPreference.set(false, defaults: defaults)
        XCTAssertFalse(WidgetVisibilityPreference.value(defaults: defaults))
        WidgetVisibilityPreference.set(true, defaults: defaults)
        XCTAssertTrue(WidgetVisibilityPreference.value(defaults: defaults))
    }

    func testWidgetDisplayModeDefaultsToMinimal() {
        XCTAssertEqual(WidgetDisplayModePreference.value(defaults: defaults), .minimal)
    }

    func testWidgetDisplayModePersistsDetailedSelection() {
        WidgetDisplayModePreference.set(.detailed, defaults: defaults)

        XCTAssertEqual(WidgetDisplayModePreference.value(defaults: defaults), .detailed)
    }

    func testBubblePresentationDefaultsAndCardChoicePersists() {
        XCTAssertEqual(WidgetPresentationPreference.value(defaults: defaults), .bubble)

        WidgetPresentationPreference.set(.card, defaults: defaults)
        XCTAssertEqual(WidgetPresentationPreference.value(defaults: defaults), .card)

        XCTAssertEqual(Set(WidgetPresentation.allCases), [.bubble, .card])
    }

    func testLegacyRailMigratesOnceWithPositionAndBackupPreserved() {
        let original = "{{600, 200}, {92, 92}}"
        let rail = "{{1200, 300}, {84, 176}}"
        defaults.set("edgeRail", forKey: WidgetPresentationPreference.defaultsKey)
        defaults.set(original, forKey: "ReadyCheck.bubbleWidgetFrame.v1")
        defaults.set(rail, forKey: "ReadyCheck.edgeRailFrame.v1")

        XCTAssertEqual(WidgetPresentationPreference.value(defaults: defaults), .bubble)
        XCTAssertEqual(defaults.string(forKey: WidgetPresentationPreference.defaultsKey), "bubble")
        XCTAssertEqual(defaults.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"), rail)
        XCTAssertEqual(defaults.string(forKey: "ReadyCheck.bubbleWidgetFrame.beforeUnified.v1"), original)
        XCTAssertEqual(defaults.string(forKey: "ReadyCheck.edgeRailFrame.v1"), rail)

        defaults.set(original, forKey: "ReadyCheck.bubbleWidgetFrame.v1")
        _ = WidgetPresentationPreference.value(defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"), original)
    }

    func testLegacyRailWithoutValidFrameKeepsExistingBubblePosition() {
        let original = "{{600, 200}, {92, 92}}"
        for invalid in ["", "invalid", "{{0, 0}, {0, 0}}", "{{0, 0}, {-20, 10}}"] {
            defaults.set("edgeRail", forKey: WidgetPresentationPreference.defaultsKey)
            defaults.set(original, forKey: "ReadyCheck.bubbleWidgetFrame.v1")
            defaults.set(invalid, forKey: "ReadyCheck.edgeRailFrame.v1")
            XCTAssertEqual(WidgetPresentationPreference.value(defaults: defaults), .bubble)
            XCTAssertEqual(defaults.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"), original)
        }
    }

    func testCardSelectionDoesNotMigrateUnusedRailPosition() {
        defaults.set("card", forKey: WidgetPresentationPreference.defaultsKey)
        defaults.set("{{1200, 300}, {84, 176}}", forKey: "ReadyCheck.edgeRailFrame.v1")
        XCTAssertEqual(WidgetPresentationPreference.value(defaults: defaults), .card)
        XCTAssertNil(defaults.object(forKey: "ReadyCheck.bubbleWidgetFrame.v1"))
    }

}

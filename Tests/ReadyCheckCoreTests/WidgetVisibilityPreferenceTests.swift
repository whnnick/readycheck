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

    func testPreservesExplicitChoiceForCurrentPreferenceVersion() {
        defaults.set(false, forKey: WidgetVisibilityPreference.defaultsKey)

        XCTAssertFalse(WidgetVisibilityPreference.value(defaults: defaults))
    }
}

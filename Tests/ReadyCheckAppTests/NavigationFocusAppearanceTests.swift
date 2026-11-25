import AppKit
import XCTest
@testable import ReadyCheckApp

final class NavigationFocusAppearanceTests: XCTestCase {
    func testPointerSelectionDoesNotDrawAKeyboardFocusIndicator() {
        var appearance = NavigationFocusAppearance<MainSettingsSection>()
        appearance.selected(.display, event: .leftMouseUp)
        appearance.focusChanged(to: .display)
        XCTAssertNil(appearance.keyboardFocus(for: .display))

        appearance.selected(.general, event: nil)
        appearance.focusChanged(to: .general)
        XCTAssertNil(appearance.keyboardFocus(for: .general))
    }

    func testKeyboardNavigationRestoresTheFocusIndicator() {
        var appearance = NavigationFocusAppearance<MainSettingsSection>()
        appearance.selected(.display, event: .leftMouseUp)
        appearance.focusChanged(to: .display)

        appearance.selected(.general, event: .keyDown)
        XCTAssertEqual(appearance.keyboardFocus(for: .general), .general)

        appearance.selected(.display, event: .leftMouseUp)
        appearance.focusChanged(to: .display)
        appearance.focusChanged(to: nil)
        XCTAssertEqual(appearance.keyboardFocus(for: .display), .display)
    }
}

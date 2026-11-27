import AppKit
import XCTest
@testable import ReadyCheckApp

@MainActor
final class NavigationFocusAppearanceTests: XCTestCase {
    func testMousePressSuppressesKeyboardMarkerBeforeSelectionChanges() throws {
        _ = NSApplication.shared
        let window = ReadyCheckMainWindow(contentRect: CGRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.navigationFocus.record(.keyDown)
        XCTAssertEqual(window.navigationFocus.keyboardFocus(for: MainWindowPage.overview), .overview)

        let receiver = MouseDownReceiver(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.contentView = receiver
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        receiver.onMouseDown = {
            // The newly focused row may be reported while the previous row is still selected.
            XCTAssertNil(window.navigationFocus.keyboardFocus(for: MainWindowPage.usage))
        }
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown, location: CGPoint(x: 50, y: 40),
            modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        window.sendEvent(event)
        XCTAssertTrue(receiver.receivedMouseDown)
        receiver.onMouseDown = nil
    }

    func testKeyboardInputRestoresFocusAndMouseReleaseDoesNot() {
        let appearance = NavigationFocusAppearance()
        XCTAssertNil(appearance.keyboardFocus(for: MainSettingsSection.display))
        appearance.record(.keyDown)
        XCTAssertEqual(appearance.keyboardFocus(for: MainSettingsSection.display), .display)
        appearance.record(.leftMouseDown)
        appearance.record(.leftMouseUp)
        XCTAssertNil(appearance.keyboardFocus(for: MainSettingsSection.general))
        appearance.record(.keyDown)
        XCTAssertEqual(appearance.keyboardFocus(for: MainSettingsSection.general), .general)
    }
}

private final class MouseDownReceiver: NSView {
    var onMouseDown: (() -> Void)?
    private(set) var receivedMouseDown = false
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        receivedMouseDown = true
        onMouseDown?()
    }
}

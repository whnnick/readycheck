import AppKit

final class ReadyCheckMainWindow: NSWindow {
    let navigationFocus = NavigationFocusAppearance()

    override func sendEvent(_ event: NSEvent) {
        // SwiftUI can move focus on mouse-down, before the button action on release.
        navigationFocus.record(event.type)
        super.sendEvent(event)
    }
}

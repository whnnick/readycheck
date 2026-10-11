import AppKit

@MainActor
enum WidgetSpaceBehavior {
    static func collectionBehavior(hideInFullscreen: Bool) -> NSWindow.CollectionBehavior {
        hideInFullscreen
            ? [.stationary, .canJoinAllApplications, .fullScreenNone]
            : [.canJoinAllSpaces, .stationary, .canJoinAllApplications, .fullScreenAuxiliary]
    }
}

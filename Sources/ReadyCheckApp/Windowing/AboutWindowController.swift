import AppKit
import ReadyCheckCore
import SwiftUI

@MainActor
final class AboutWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show(localization: LocalizationService) {
        if let window, window.isVisible {
            window.title = localization.text("about.title")
            window.contentView = NSHostingView(rootView: AboutView(localization: localization))
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = localization.text("about.title")
        window.contentView = NSHostingView(rootView: AboutView(localization: localization))
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 420, height: 440)
        window.collectionBehavior = [.moveToActiveSpace, .managed]
        window.level = .floating
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow === window
        else {
            return
        }

        window?.delegate = nil
        window = nil
    }
}

import AppKit
import ReadyCheckCore
import SwiftUI

@MainActor
final class FloatingWindowController: NSObject, NSWindowDelegate {
    private let frameDefaultsKey = "ReadyCheck.floatingWidgetFrame.v1"
    private var window: NSWindow?
    var onVisibilityChanged: ((Bool) -> Void)?

    func show(model: ReadyCheckAppModel) {
        if let window {
            show(window)
            onVisibilityChanged?(true)
            return
        }

        close(preservingFrame: true)

        let rootView = FloatingWidgetView(model: model)
        let hostingController = NSHostingController(rootView: rootView)
        let widgetSize = FloatingWidgetPlacement.defaultSize
        let window = NSPanel(
            contentRect: NSRect(origin: .zero, size: widgetSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        hostingController.view.frame = NSRect(origin: .zero, size: widgetSize)
        window.contentViewController = hostingController
        window.setContentSize(widgetSize)
        window.minSize = widgetSize
        window.maxSize = widgetSize
        window.title = model.localization.text("app.name")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        applyLevel(to: window, alwaysOnTop: model.widgetAlwaysOnTop)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.delegate = self

        self.window = window
        show(window)
        onVisibilityChanged?(true)
    }

    func updateLevel(alwaysOnTop: Bool) {
        guard let window else { return }
        applyLevel(to: window, alwaysOnTop: alwaysOnTop)

        if alwaysOnTop {
            window.orderFrontRegardless()
        } else {
            window.orderBack(nil)
        }
    }

    func showAtDefaultPosition(model: ReadyCheckAppModel) {
        UserDefaults.standard.removeObject(forKey: frameDefaultsKey)

        if let window {
            show(window)
            onVisibilityChanged?(true)
            return
        }

        show(model: model)
    }

    func resetPosition(model: ReadyCheckAppModel) {
        showAtDefaultPosition(model: model)
    }

    func close() {
        close(preservingFrame: true)
    }

    private func close(preservingFrame: Bool) {
        let closingWindow = window
        window = nil
        if preservingFrame, let closingWindow {
            persistFrame(closingWindow.frame)
        }
        closingWindow?.delegate = nil
        closingWindow?.close()
        onVisibilityChanged?(false)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow === window
        else {
            return
        }

        window?.delegate = nil
        window = nil
        onVisibilityChanged?(false)
    }

    func windowDidMove(_ notification: Notification) {
        guard let movedWindow = notification.object as? NSWindow,
              movedWindow === window
        else {
            return
        }

        persistFrame(movedWindow.frame)
    }

    private func show(_ window: NSWindow) {
        let savedFrame = persistedFrame()
        let visibleFrame = targetScreen(for: window, savedFrame: savedFrame)?.visibleFrame

        if let savedFrame, let visibleFrame {
            let frame = FloatingWidgetPlacement.clampedFrame(
                currentFrame: NSRect(origin: savedFrame.origin, size: FloatingWidgetPlacement.defaultSize),
                visibleFrame: visibleFrame
            )
            window.setFrame(frame, display: false)
        } else {
            positionNearBottomTrailing(window, visibleFrame: visibleFrame)
        }

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        clampInsideTargetScreen(window, visibleFrame: visibleFrame)
        persistFrame(window.frame)
    }

    private func applyLevel(to window: NSWindow, alwaysOnTop: Bool) {
        if alwaysOnTop {
            window.level = .floating
        } else {
            window.level = .normal
        }

        window.ignoresMouseEvents = false
    }

    private func positionNearBottomTrailing(_ window: NSWindow, visibleFrame: NSRect?) {
        guard let visibleFrame else {
            window.center()
            return
        }

        let frame = FloatingWidgetPlacement.frame(
            preferredSize: window.frame.size,
            visibleFrame: visibleFrame
        )
        window.setFrame(frame, display: false)
    }

    private func clampInsideTargetScreen(_ window: NSWindow, visibleFrame: NSRect?) {
        guard let visibleFrame else { return }

        let frame = FloatingWidgetPlacement.clampedFrame(
            currentFrame: window.frame,
            visibleFrame: visibleFrame
        )
        window.setFrame(frame, display: true)
    }

    private func targetScreen(for window: NSWindow, savedFrame: NSRect? = nil) -> NSScreen? {
        if let savedFrame,
           let screen = screen(containing: CGPoint(x: savedFrame.midX, y: savedFrame.midY)) {
            return screen
        }

        if let screen = NSApp.keyWindow?.screen ?? NSApp.mainWindow?.screen {
            return screen
        }

        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            return screen
        }

        return NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }

    private func persistedFrame() -> NSRect? {
        guard let value = UserDefaults.standard.string(forKey: frameDefaultsKey) else {
            return nil
        }

        let frame = NSRectFromString(value)
        guard frame.width.isFinite,
              frame.height.isFinite,
              frame.minX.isFinite,
              frame.minY.isFinite,
              frame.width > 0,
              frame.height > 0
        else {
            return nil
        }

        return frame
    }

    private func persistFrame(_ frame: NSRect) {
        guard frame.width.isFinite,
              frame.height.isFinite,
              frame.minX.isFinite,
              frame.minY.isFinite,
              frame.width > 0,
              frame.height > 0
        else {
            return
        }

        UserDefaults.standard.set(NSStringFromRect(frame), forKey: frameDefaultsKey)
    }
}

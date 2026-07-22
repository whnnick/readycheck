import AppKit
import ReadyCheckCore
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private struct ScreenContext {
        let screen: NSScreen
        let notchGap: CGRect
    }

    private var window: NSPanel?
    private weak var model: ReadyCheckAppModel?
    private var isObservingScreenChanges = false

    var isAvailable: Bool {
        Self.screenContext() != nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func show(model: ReadyCheckAppModel) {
        self.model = model
        guard let context = Self.screenContext() else {
            close()
            return
        }

        let frame = NotchStatusPlacement.frame(
            notchGap: context.notchGap,
            screenFrame: context.screen.frame
        )

        if let window {
            window.setFrame(frame, display: true)
            window.orderFrontRegardless()
            return
        }

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: context.screen
        )
        panel.contentViewController = NSHostingController(rootView: NotchStatusView(model: model))
        panel.setFrame(frame, display: false)
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.orderFrontRegardless()

        window = panel
        observeScreenChanges(model: model)
    }

    func close() {
        window?.close()
        window = nil
    }

    private func observeScreenChanges(model: ReadyCheckAppModel) {
        guard !isObservingScreenChanges else { return }
        isObservingScreenChanges = true
        self.model = model
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc
    private func screenParametersDidChange() {
        guard let model, model.notchStatusVisible else { return }
        show(model: model)
    }

    private static func screenContext() -> ScreenContext? {
        for screen in NSScreen.screens {
            guard let leftArea = screen.auxiliaryTopLeftArea,
                  let rightArea = screen.auxiliaryTopRightArea,
                  let notchGap = NotchStatusPlacement.notchGap(
                      leftArea: leftArea,
                      rightArea: rightArea
                  )
            else {
                continue
            }

            return ScreenContext(screen: screen, notchGap: notchGap)
        }

        return nil
    }
}

import AppKit
import ReadyCheckCore
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    struct ScreenContext {
        let screen: NSScreen
        let notchGap: CGRect
    }

    private var window: QuotaWidgetPanel?
    private var host: NSHostingController<NotchStatusView>?
    private weak var model: ReadyCheckAppModel?
    private let screenContextProvider: @MainActor () -> ScreenContext?
    private var isExpanded = false
    private var outsideClickMonitor: Any?
    private var localMonitor: Any?

    init(screenContextProvider: @escaping @MainActor () -> ScreenContext? = NotchWindowController.screenContext) {
        self.screenContextProvider = screenContextProvider
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
    }

    var isAvailable: Bool { screenContextProvider() != nil }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func show(model: ReadyCheckAppModel) {
        self.model = model
        guard let context = screenContextProvider() else { close(); return }
        if window != nil { updatePresentation(); return }
        let panel = QuotaWidgetPanel(contentRect: frame(context), styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false, screen: context.screen)
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        window = panel
        let controller = NSHostingController(rootView: makeView(model))
        controller.sizingOptions = []
        host = controller
        panel.contentViewController = controller
        updateFullscreenBehavior(hideInFullscreen: model.widgetHideInFullscreen)
        updatePresentation()
    }

    func updateFullscreenBehavior(hideInFullscreen: Bool) {
        window?.collectionBehavior = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: hideInFullscreen).union(.ignoresCycle)
    }

    func close() {
        isExpanded = false
        stopMonitors()
        window?.close()
        window = nil
        host = nil
    }

    func dismissFromExternalInteraction() { setExpanded(false) }

    private func setExpanded(_ expanded: Bool) {
        guard isExpanded != expanded else { return }
        isExpanded = expanded
        updatePresentation()
    }

    private func makeView(_ model: ReadyCheckAppModel) -> NotchStatusView {
        NotchStatusView(model: model, isExpanded: isExpanded,
            onClick: { [weak self] in
                guard let self else { return }
                self.setExpanded(!self.isExpanded)
            },
            onDismiss: { [weak self] in self?.setExpanded(false) })
    }

    private func frame(_ context: ScreenContext) -> CGRect {
        return NotchStatusPlacement.frame(notchGap: context.notchGap, screenFrame: context.screen.frame,
            height: isExpanded ? 264 : NotchStatusPlacement.defaultHeight, width: isExpanded ? 360 : nil)
    }

    private func updatePresentation() {
        guard let window, let model, let context = screenContextProvider() else { close(); return }
        host?.rootView = makeView(model)
        window.setFrame(frame(context), display: true)
        window.allowsKeyboard = isExpanded
        if window.allowsKeyboard { window.makeKeyAndOrderFront(nil) }
        else { window.resignKey(); window.orderFrontRegardless() }
        stopMonitors()
        guard isExpanded else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.window?.frame.contains(NSEvent.mouseLocation) == false else { return }
            self.dismissFromExternalInteraction()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53, self.window?.isKeyWindow == true { self.setExpanded(false); return nil }
            } else if event.window !== self.window { self.dismissFromExternalInteraction() }
            return event
        }
    }

    private func stopMonitors() {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        outsideClickMonitor = nil
        localMonitor = nil
    }

    @objc private func activeSpaceDidChange() { setExpanded(false) }
    @objc private func screenParametersDidChange() {
        guard let model, model.notchStatusVisible else { close(); return }
        show(model: model)
    }

    private static func screenContext() -> ScreenContext? {
        for screen in NSScreen.screens {
            guard let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea,
                  let gap = NotchStatusPlacement.notchGap(leftArea: left, rightArea: right) else { continue }
            return ScreenContext(screen: screen, notchGap: gap)
        }
        return nil
    }
}

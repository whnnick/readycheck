import AppKit
import QuartzCore
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
    private let reduceMotionProvider: @MainActor () -> Bool
    private var isExpanded = false
    private var targetFrame: CGRect?
    private var contentAnimation: Animation?
    private var outsideClickMonitor: Any?
    private var localMonitor: Any?
    private var dragStartFrame: CGRect?
    private var dragStartPointer: CGPoint?
    private var dragPointer: CGPoint?
    private var dragCancelled = false
    var onNotchDetachment: ((CGPoint) -> Void)?

    init(screenContextProvider: @escaping @MainActor () -> ScreenContext? = NotchWindowController.screenContext,
         reduceMotionProvider: @escaping @MainActor () -> Bool = { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }) {
        self.screenContextProvider = screenContextProvider
        self.reduceMotionProvider = reduceMotionProvider
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
        let panel = BubbleWidgetPanel(contentRect: frame(context), styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false, screen: context.screen)
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        window = panel
        panel.canStartDrag = { [weak self, weak panel] point in
            guard let self, let panel else { return false }
            return !self.isExpanded || (point.y >= panel.frame.height - 52 && point.x < 170)
        }
        panel.onPointerDown = { [weak self] in self?.dragCancelled = false }
        panel.onPointerDrag = { [weak self] start, pointer in self?.dragChanged(start: start, pointer: pointer) }
        panel.onPointerUp = { [weak self] moved in
            guard let self else { return }
            defer { self.dragCancelled = false }
            if moved { self.dragEnded() }
            else if !self.isExpanded { self.setExpanded(true) }
        }
        let controller = NSHostingController(rootView: makeView(model))
        controller.sizingOptions = []
        // The panel animator owns the geometry, not the hosting view's intrinsic size.
        if let view = controller.view as? NSHostingView<NotchStatusView> { view.sizingOptions = [] }
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
        targetFrame = nil
        contentAnimation = nil
        dragStartFrame = nil
        dragStartPointer = nil
        dragPointer = nil
        dragCancelled = false
    }

    func dismissFromExternalInteraction() {
        if dragStartFrame != nil { cancelDrag() }
        setExpanded(false)
    }

    private func dragChanged(start: CGPoint, pointer: CGPoint) {
        guard let window, !dragCancelled else { return }
        if dragStartFrame == nil {
            setExpanded(false, animated: false)
            dragStartFrame = window.frame
            dragStartPointer = start
            targetFrame = nil
            contentAnimation = nil
            updatePresentation()
        }
        guard let frame = dragStartFrame, let start = dragStartPointer else { return }
        dragPointer = pointer
        window.setFrameOrigin(BubbleWidgetPlacement.draggedFrame(from: frame, pointerStart: start, pointerNow: pointer).origin)
    }

    private func dragEnded() {
        guard let start = dragStartPointer, let pointer = dragPointer else { return }
        let detach = NotchStatusPlacement.shouldDetach(pointerStart: start, pointerNow: pointer)
        if detach, let onNotchDetachment {
            onNotchDetachment(pointer)
        }
        // The callback may close this window when the model enables the capsule.
        cancelDrag()
    }

    private func cancelDrag(animated: Bool = true) {
        guard dragStartFrame != nil else { return }
        dragCancelled = true
        dragStartFrame = nil
        dragStartPointer = nil
        dragPointer = nil
        contentAnimation = animated ? .easeOut(duration: 0.14) : nil
        targetFrame = nil
        updatePresentation(animated: animated)
    }

    private func setExpanded(_ expanded: Bool, animated: Bool = true) {
        guard isExpanded != expanded else { return }
        isExpanded = expanded
        contentAnimation = animated ? .easeOut(duration: reduceMotionProvider() ? 0.10 : 0.14) : nil
        updatePresentation(animated: animated)
    }

    private func makeView(_ model: ReadyCheckAppModel) -> NotchStatusView {
        NotchStatusView(model: model, isExpanded: isExpanded, isDragging: dragStartFrame != nil, presentationAnimation: contentAnimation,
            collapsedWidth: screenContextProvider()?.notchGap.width,
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

    private func updatePresentation(animated: Bool = false) {
        guard let window, let model, let context = screenContextProvider() else { close(); return }
        host?.rootView = makeView(model)
        let nextFrame = frame(context)
        if dragStartFrame == nil, targetFrame != nextFrame {
            targetFrame = nextFrame
            NSAnimationContext.runAnimationGroup { animation in
                animation.duration = animated && !reduceMotionProvider() ? (isExpanded ? 0.26 : 0.18) : 0
                animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1)
                window.animator().setFrame(nextFrame, display: true)
            }
        }
        window.allowsKeyboard = isExpanded || dragStartFrame != nil
        if window.allowsKeyboard { window.makeKeyAndOrderFront(nil) }
        else { window.resignKey(); window.orderFrontRegardless() }
        stopMonitors()
        guard isExpanded || dragStartFrame != nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.window?.frame.contains(NSEvent.mouseLocation) == false else { return }
            self.dismissFromExternalInteraction()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53, self.window?.isKeyWindow == true {
                    self.cancelDrag(animated: false)
                    self.setExpanded(false, animated: false)
                    return nil
                }
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

    @objc private func activeSpaceDidChange() { cancelDrag(animated: false); setExpanded(false, animated: false) }
    @objc private func screenParametersDidChange() {
        cancelDrag(animated: false)
        guard let model, model.notchStatusVisible else { close(); return }
        show(model: model)
    }

    static func screenContext() -> ScreenContext? {
        for screen in NSScreen.screens {
            guard let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea,
                  let gap = NotchStatusPlacement.notchGap(leftArea: left, rightArea: right) else { continue }
            return ScreenContext(screen: screen, notchGap: gap)
        }
        return nil
    }
}

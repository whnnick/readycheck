import AppKit
import QuartzCore
import ReadyCheckCore
import SwiftUI

@MainActor
final class AggregateCapsuleWindowController: NSObject, NSWindowDelegate {
    static let frameKey = "ReadyCheck.aggregateCapsuleFrame.v1"
    private(set) var rail: BubbleWidgetPanel?
    private(set) var detail: QuotaWidgetPanel?
    private(set) var service: ServiceSettingsTarget = .codex
    private let interaction = WidgetInteractionController()
    private weak var model: ReadyCheckAppModel?
    private var host: NSHostingController<AggregateCapsuleView>?
    private var detailHost: NSHostingController<AggregateCapsuleDetailView>?
    private var detailTargetFrame: CGRect?
    private var detailDismissal: UUID?
    private var dragOrigin: CGRect?
    private var outsideMonitor: Any?
    private var localMonitor: Any?
    private let visibleFrameProvider: @MainActor (CGRect?) -> CGRect
    private let pointerLocation: @MainActor () -> CGPoint
    private let reduceMotionProvider: @MainActor () -> Bool
    var onVisibilityChanged: ((Bool) -> Void)?
    var isPinned: Bool { interaction.state == .pinned }

    init(
        visibleFrameProvider: @escaping @MainActor (CGRect?) -> CGRect = AggregateCapsuleWindowController.screenVisibleFrame,
        pointerLocation: @escaping @MainActor () -> CGPoint = { NSEvent.mouseLocation },
        reduceMotionProvider: @escaping @MainActor () -> Bool = { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    ) {
        self.visibleFrameProvider = visibleFrameProvider
        self.pointerLocation = pointerLocation
        self.reduceMotionProvider = reduceMotionProvider
        super.init()
        interaction.containsPointer = { [weak self] in self?.containsPointer == true }
        interaction.onChange = { [weak self] _ in self?.updateDetail() }
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sessionActivated), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(spaceChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func show(model: ReadyCheckAppModel) {
        self.model = model
        if let rail { rail.orderFrontRegardless(); return }
        let saved = savedFrame()
        let visible = visibleFrame(for: saved)
        guard visible.width > 0, visible.height > 0 else { return }
        let panel = BubbleWidgetPanel(contentRect: AggregateCapsulePlacement.restoredFrame(from: saved, in: visible),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configure(panel, model: model)
        panel.title = "ReadyCheck · " + (model.language == .zhCN ? "聚合胶囊" : "Aggregate capsule")
        panel.delegate = self
        rail = panel
        panel.canStartDrag = { [weak panel] point in
            guard let panel else { return false }
            let radius = AggregateCapsuleView.cornerRadius
            let isGrip = point.y < AggregateCapsuleView.bottomGripHeight
                || point.y > panel.frame.height - AggregateCapsuleView.headerHeight
            return isGrip && NSBezierPath(roundedRect: CGRect(origin: .zero, size: panel.frame.size),
                                          xRadius: radius, yRadius: radius).contains(point)
        }
        panel.onPointerDown = { [weak self] in
            guard let self else { return }
            self.dragOrigin = self.rail?.frame
            self.interaction.beginDrag(); self.interaction.collapse()
        }
        panel.onPointerDrag = { [weak self] start, pointer in
            guard let self, let origin = self.dragOrigin else { return }
            self.rail?.setFrameOrigin(BubbleWidgetPlacement.draggedFrame(from: origin, pointerStart: start, pointerNow: pointer).origin)
        }
        panel.onPointerUp = { [weak self] moved in
            guard let self else { return }
            if moved { self.finishDrag() }
            self.dragOrigin = nil; self.interaction.endDrag()
        }
        updateRail()
        // Attaching a hosting controller can replace the initial content size.
        panel.setFrame(AggregateCapsulePlacement.restoredFrame(from: saved, in: visible), display: true)
        panel.orderFrontRegardless()
    }

    func select(_ service: ServiceSettingsTarget) {
        self.service = service
        if interaction.state == .collapsed { interaction.click() }
        else { updateDetail() }
    }

    func hover(_ service: ServiceSettingsTarget, inside: Bool) {
        if inside && interaction.state != .pinned {
            self.service = service
            if interaction.state == .preview { updateDetail() }
        }
        interaction.hoverChanged(inside)
    }

    func railPointerExited() { interaction.hoverChanged(false) }

    func togglePin() { interaction.togglePin() }
    func dismissFromExternalInteraction() {
        if interaction.state == .preview { interaction.collapse() }
    }

    func updateLevel(alwaysOnTop: Bool) {
        rail?.level = alwaysOnTop ? .floating : .normal
        detail?.level = alwaysOnTop ? .floating : .normal
    }

    func updateFullscreenBehavior(hideInFullscreen: Bool) {
        for panel in [rail, detail] { panel?.collectionBehavior = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: hideInFullscreen) }
    }

    func resetPosition(model: ReadyCheckAppModel) {
        show(model: model)
        guard let rail else { return }
        let visible = visibleFrame(for: rail.frame)
        guard visible.width > 0, visible.height > 0 else { return }
        rail.setFrame(AggregateCapsulePlacement.restoredFrame(from: nil, in: visible), display: true)
        persist(); updateDetail()
    }

    func close() {
        persist(); interaction.reset()
        hideDetail(animated: false)
        rail?.delegate = nil; rail?.close(); detail?.close()
        rail = nil; detail = nil; host = nil; detailHost = nil; model = nil
        detailTargetFrame = nil
    }

    func windowWillClose(_ notification: Notification) {
        guard let panel = notification.object as? NSWindow, panel === rail else { return }
        close(); onVisibilityChanged?(false)
    }

    private func configure(_ panel: QuotaWidgetPanel, model: ReadyCheckAppModel) {
        panel.backgroundColor = .clear; panel.isOpaque = false; panel.hasShadow = false
        panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
        panel.allowsToolTipsWhenApplicationIsInactive = true
        panel.level = model.widgetAlwaysOnTop ? .floating : .normal
        panel.collectionBehavior = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: model.widgetHideInFullscreen)
    }

    private func updateRail() {
        guard let model, let rail else { return }
        let view = AggregateCapsuleView(model: model, selected: interaction.state == .collapsed ? nil : service,
            isPinned: isPinned, onSelect: { [weak self] in self?.select($0) },
            onHover: { [weak self] in self?.hover($0, inside: $1) },
            onLeaveRail: { [weak self] in self?.railPointerExited() })
        if let host { host.rootView = view }
        else {
            let host = NSHostingController(rootView: view); host.sizingOptions = []
            rail.contentViewController = host; self.host = host
        }
    }

    private func updateDetail() {
        updateRail()
        guard interaction.state != .collapsed, let model, let rail else {
            hideDetail(animated: !interaction.isDragging)
            return
        }
        let visible = visibleFrame(for: rail.frame)
        guard visible.width > 0, visible.height > 0 else {
            hideDetail(animated: false)
            return
        }
        let frame = AggregateCapsulePlacement.detailFrame(beside: rail.frame, in: visible)
        guard frame.width > 0, frame.height > 0 else {
            hideDetail(animated: false)
            return
        }
        let panel = detail ?? QuotaWidgetPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configure(panel, model: model)
        panel.animationBehavior = .none
        panel.title = "ReadyCheck · " + service.rawValue
        let view = AggregateCapsuleDetailView(model: model, service: service, isPinned: isPinned,
            onTogglePin: { [weak self] in self?.togglePin() }, onHover: { [weak self] inside in
                guard let self, !inside || self.interaction.state != .collapsed else { return }
                self.interaction.hoverChanged(inside)
            })
        if let detailHost { detailHost.rootView = view }
        else {
            let host = NSHostingController(rootView: view); host.sizingOptions = []
            panel.contentViewController = host; detailHost = host
        }
        detail = panel
        presentDetail(panel, frame: frame, beside: rail.frame)
        startMonitors()
    }

    private func presentDetail(_ panel: QuotaWidgetPanel, frame: CGRect, beside railFrame: CGRect) {
        let isEntering = !panel.isVisible
        let isReopening = detailDismissal != nil
        let animate = !reduceMotionProvider() && (isEntering || isReopening)
        detailDismissal = nil
        panel.ignoresMouseEvents = false
        panel.allowsKeyboard = isPinned

        if isEntering {
            let towardRail: CGFloat = frame.midX < railFrame.midX ? 6 : -6
            panel.alphaValue = animate ? 0 : 1
            panel.setFrame(animate ? frame.offsetBy(dx: towardRail, dy: 0) : frame, display: true)
        } else if detailTargetFrame != frame {
            panel.setFrame(frame, display: true)
        }
        detailTargetFrame = frame

        if isPinned { panel.makeKeyAndOrderFront(nil) }
        else { panel.resignKey(); panel.orderFrontRegardless() }

        if animate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
                if isEntering { panel.animator().setFrame(frame, display: true) }
            }
        } else if isReopening {
            panel.alphaValue = 1
        }
    }

    private func hideDetail(animated: Bool) {
        stopMonitors()
        guard let panel = detail else { return }
        panel.allowsKeyboard = false
        if panel.isKeyWindow { panel.resignKey() }
        panel.ignoresMouseEvents = true

        guard panel.isVisible, animated, !reduceMotionProvider() else {
            finishDetailDismissal(panel)
            return
        }
        guard detailDismissal == nil else { return }

        let dismissal = UUID()
        detailDismissal = dismissal
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.10
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self, weak panel] in
            Task { @MainActor in
                // A new preview may have reused this panel before the fade finished.
                guard let self, let panel, self.detailDismissal == dismissal else { return }
                self.finishDetailDismissal(panel)
            }
        })
    }

    private func finishDetailDismissal(_ panel: QuotaWidgetPanel) {
        detailDismissal = nil
        panel.orderOut(nil)
        panel.alphaValue = 1
    }

    func finishDrag() {
        guard let rail else { return }
        let visible = visibleFrame(for: rail.frame)
        guard visible.width > 0, visible.height > 0 else { return }
        rail.setFrame(AggregateCapsulePlacement.snappedFrame(rail.frame, in: visible), display: true)
        persist()
    }

    private var containsPointer: Bool {
        [(rail as QuotaWidgetPanel?, AggregateCapsuleView.cornerRadius), (detail, CGFloat(24))].contains { panel, radius in
            guard let panel, panel.isVisible, !panel.ignoresMouseEvents else { return false }
            let rect = CGRect(origin: .zero, size: panel.frame.size)
            return NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
                .contains(panel.convertPoint(fromScreen: pointerLocation()))
        }
    }

    @objc private func sessionActivated() {
        guard let model, model.widgetVisible, model.widgetPresentation == .aggregate else { return }
        if rail == nil { show(model: model) } else { screenChanged() }
    }
    @objc private func screenChanged() {
        guard let rail else { sessionActivated(); return }
        let visible = visibleFrame(for: rail.frame)
        guard visible.width > 0, visible.height > 0 else { return }
        rail.setFrame(AggregateCapsulePlacement.restoredFrame(from: rail.frame, in: visible), display: true)
        persist(); updateDetail()
    }
    @objc private func spaceChanged() {
        hideDetail(animated: false)
        interaction.spaceChanged()
    }

    private func startMonitors() {
        stopMonitors()
        outsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, !self.containsPointer else { return }
            self.dismissFromExternalInteraction()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown, event.keyCode == 53, self.detail?.isKeyWindow == true {
                self.interaction.collapse(); return nil
            }
            if event.type != .keyDown, event.window !== self.rail, event.window !== self.detail { self.dismissFromExternalInteraction() }
            return event
        }
    }
    private func stopMonitors() {
        if let outsideMonitor { NSEvent.removeMonitor(outsideMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        outsideMonitor = nil; localMonitor = nil
    }
    private func visibleFrame(for frame: CGRect?) -> CGRect { visibleFrameProvider(frame) }
    private static func screenVisibleFrame(for frame: CGRect?) -> CGRect {
        (frame.flatMap { frame in NSScreen.screens.first { $0.frame.contains(CGPoint(x: frame.midX, y: frame.midY)) } }
            ?? NSScreen.main)?.visibleFrame ?? .zero
    }
    private func savedFrame() -> CGRect? {
        for key in [Self.frameKey, "ReadyCheck.bubbleWidgetFrame.v1"] {
            if let value = UserDefaults.standard.string(forKey: key) {
                let frame = NSRectFromString(value)
                if [frame.minX, frame.minY, frame.width, frame.height].allSatisfy(\.isFinite), frame.width > 0, frame.height > 0 { return frame }
            }
        }
        return nil
    }
    private func persist() {
        if let rail { UserDefaults.standard.set(NSStringFromRect(rail.frame), forKey: Self.frameKey) }
    }
}

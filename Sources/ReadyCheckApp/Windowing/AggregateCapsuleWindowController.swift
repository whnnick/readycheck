import AppKit
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
    private var dragOrigin: CGRect?
    private var outsideMonitor: Any?
    private var localMonitor: Any?
    private let visibleFrameProvider: @MainActor (CGRect?) -> CGRect
    var onVisibilityChanged: ((Bool) -> Void)?
    var isPinned: Bool { interaction.state == .pinned }

    init(visibleFrameProvider: @escaping @MainActor (CGRect?) -> CGRect = AggregateCapsuleWindowController.screenVisibleFrame) {
        self.visibleFrameProvider = visibleFrameProvider
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
            return (point.y < 32 || point.y > panel.frame.height - 38)
                && NSBezierPath(roundedRect: CGRect(origin: .zero, size: panel.frame.size), xRadius: 42, yRadius: 42).contains(point)
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
        persist(); interaction.reset(); stopMonitors()
        rail?.delegate = nil; rail?.close(); detail?.close()
        rail = nil; detail = nil; host = nil; detailHost = nil; model = nil
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
            onSelect: { [weak self] in self?.select($0) }, onHover: { [weak self] in self?.hover($0, inside: $1) })
        if let host { host.rootView = view }
        else {
            let host = NSHostingController(rootView: view); host.sizingOptions = []
            rail.contentViewController = host; self.host = host
        }
    }

    private func updateDetail() {
        updateRail()
        guard interaction.state != .collapsed, let model, let rail else {
            detail?.orderOut(nil); stopMonitors(); return
        }
        let visible = visibleFrame(for: rail.frame)
        guard visible.width > 0, visible.height > 0 else { detail?.orderOut(nil); stopMonitors(); return }
        let frame = AggregateCapsulePlacement.detailFrame(beside: rail.frame, in: visible)
        let panel = detail ?? QuotaWidgetPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configure(panel, model: model)
        panel.title = "ReadyCheck · " + service.rawValue
        let view = AggregateCapsuleDetailView(model: model, service: service, isPinned: isPinned,
            onTogglePin: { [weak self] in self?.togglePin() }, onHover: { [weak self] in self?.interaction.hoverChanged($0) })
        if let detailHost { detailHost.rootView = view }
        else {
            let host = NSHostingController(rootView: view); host.sizingOptions = []
            panel.contentViewController = host; detailHost = host
        }
        detail = panel
        panel.setFrame(frame, display: true)
        panel.allowsKeyboard = isPinned
        if isPinned { panel.makeKeyAndOrderFront(nil) }
        else { panel.resignKey(); panel.orderFrontRegardless() }
        startMonitors()
    }

    func finishDrag() {
        guard let rail else { return }
        let visible = visibleFrame(for: rail.frame)
        guard visible.width > 0, visible.height > 0 else { return }
        rail.setFrame(AggregateCapsulePlacement.snappedFrame(rail.frame, in: visible), display: true)
        persist()
    }

    private var containsPointer: Bool {
        [(rail as QuotaWidgetPanel?, CGFloat(42)), (detail, CGFloat(24))].contains { panel, radius in
            guard let panel, panel.isVisible else { return false }
            let rect = CGRect(origin: .zero, size: panel.frame.size)
            return NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
                .contains(panel.convertPoint(fromScreen: NSEvent.mouseLocation))
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
    @objc private func spaceChanged() { interaction.spaceChanged() }

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

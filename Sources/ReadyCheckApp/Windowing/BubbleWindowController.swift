import AppKit
import QuartzCore
import ReadyCheckCore
import SwiftUI

@MainActor
final class BubbleWindowController: NSObject, NSWindowDelegate {
    private let frameDefaultsKey = "ReadyCheck.bubbleWidgetFrame.v1"
    private var panel: QuotaWidgetPanel?
    private var hostingController: NSHostingController<BubbleWidgetView>?
    private var clippingView: BubbleClippingView?
    private weak var model: ReadyCheckAppModel?
    private var restingFrame: CGRect?
    private var edge: BubbleWidgetPlacement.Edge?
    private let interaction = WidgetInteractionController()
    private var isExpanded: Bool { interaction.state != .collapsed }
    private var dragStartFrame: CGRect?
    private var dragStartPointer: CGPoint?
    private var outsideClickMonitor: Any?
    private var escapeMonitor: Any?
    var onVisibilityChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        interaction.containsPointer = { [weak self] in
            self?.panel?.frame.contains(NSEvent.mouseLocation) == true
        }
        interaction.onChange = { [weak self] state in self?.applyInteraction(state) }
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func activeSpaceDidChange() {
        interaction.spaceChanged()
    }

    func show(model: ReadyCheckAppModel) {
        self.model = model
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let panel = BubbleWidgetPanel(
            contentRect: CGRect(origin: .zero, size: BubbleWidgetPlacement.bubbleSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.allowsToolTipsWhenApplicationIsInactive = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: model.widgetHideInFullscreen)
        panel.delegate = self
        panel.level = model.widgetAlwaysOnTop ? .floating : .normal
        self.panel = panel
        panel.canStartDrag = { [weak self] point in
            guard let self, let panel = self.panel else { return false }
            if !self.isExpanded {
                return (self.clippingView?.layer?.mask as? CAShapeLayer)?.path?.contains(point) == true
            }
            let diameter = BubbleWidgetPlacement.dialDiameter(in: panel.frame.size)
            let centerX = self.expansionSide == .left ? diameter / 2 : panel.frame.width - diameter / 2
            return hypot(point.x - centerX, point.y - panel.frame.height / 2) <= (diameter - 16) / 2
        }
        panel.onPointerDown = { [weak self] in self?.interaction.beginDrag() }
        panel.onPointerDrag = { [weak self] start, pointer in
            self?.dragChanged(pointerStart: start, pointer: pointer)
        }
        panel.onPointerUp = { [weak self] moved in
            guard let self else { return }
            if moved { self.dragEnded() }
            else { self.interaction.endDrag(); self.interaction.click() }
        }

        let view = makeView(model: model)
        let host = NSHostingController(rootView: view)
        host.sizingOptions = []
        let clip = BubbleClippingView()
        clip.autoresizingMask = [.width, .height]
        let container = NSViewController()
        container.view = clip
        container.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        clip.onPointerChange = { [weak self] in self?.interaction.hoverChanged($0) }
        clip.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: clip.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: clip.bottomAnchor)
        ])
        hostingController = host
        clippingView = clip
        panel.contentViewController = container

        let screen = targetScreen(savedFrame: savedFrame())
        let visible = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let frame = savedFrame().map { BubbleWidgetPlacement.restoredBubbleFrame(from: $0, in: visible) }
            ?? BubbleWidgetPlacement.defaultFrame(in: visible)
        placeResting(frame, visibleFrame: visible)
        panel.orderFrontRegardless()
        onVisibilityChanged?(true)
    }

    func updateFullscreenBehavior(hideInFullscreen: Bool) {
        panel?.collectionBehavior = WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: hideInFullscreen)
    }

    func close() {
        close(persistingPosition: true)
    }

    private func close(persistingPosition: Bool) {
        stopDismissMonitors()
        interaction.reset()
        guard let panel else { return }
        if persistingPosition, let restingFrame { persist(restingFrame) }
        panel.delegate = nil
        self.panel = nil
        hostingController = nil
        clippingView = nil
        panel.close()
        edge = nil
        restingFrame = nil
        dragStartFrame = nil
        dragStartPointer = nil
        onVisibilityChanged?(false)
    }

    func resetPosition(model: ReadyCheckAppModel) {
        close(persistingPosition: false)
        UserDefaults.standard.removeObject(forKey: frameDefaultsKey)
        show(model: model)
    }

    func updateLevel(alwaysOnTop: Bool) {
        panel?.level = alwaysOnTop ? .floating : .normal
        if alwaysOnTop { panel?.orderFrontRegardless() }
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === panel else { return }
        stopDismissMonitors()
        if !isExpanded, let restingFrame { persist(restingFrame) }
        panel = nil
        interaction.reset()
        hostingController = nil
        clippingView = nil
        onVisibilityChanged?(false)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, let panel, window === panel,
              panel.allowsKeyboard else { return }
        dismissFromExternalInteraction()
    }

    @objc private func screenParametersDidChange() {
        guard let panel, panel.isVisible, let restingFrame else { return }
        let visible = targetScreen(savedFrame: restingFrame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let clamped = BubbleWidgetPlacement.clamped(restingFrame, in: visible)
        if isExpanded {
            self.restingFrame = clamped
            panel.setFrame(BubbleWidgetPlacement.expandedFrame(from: clamped, edge: edge, in: visible), display: true)
        } else {
            placeResting(clamped, visibleFrame: visible)
        }
    }

    private func makeView(model: ReadyCheckAppModel) -> BubbleWidgetView {
        BubbleWidgetView(
            model: model,
            isExpanded: isExpanded,
            isPinned: interaction.state == .pinned,
            onPin: { [weak self] in self?.interaction.pinPreview() },
            onTogglePin: { [weak self] in self?.interaction.togglePin() },
            tabEdge: isExpanded ? nil : edge,
            expansionSide: expansionSide,
            onTap: { [weak self] in self?.interaction.click() },
            onDragChanged: { [weak self] translation in self?.dragChanged(translation) },
            onDragEnded: { [weak self] in self?.dragEnded() },
            onCollapse: { [weak self] in self?.collapse() }
        )
    }

    private func updateView() {
        guard let model else { return }
        clippingView?.orbOnLeft = expansionSide == .left
        clippingView?.silhouette = isExpanded ? .expanded : (edge == nil ? .circle : .edgeTab)
        hostingController?.rootView = makeView(model: model)
    }

    private var expansionSide: BubbleWidgetPlacement.Edge {
        guard let restingFrame else { return .right }
        let visible = targetScreen(savedFrame: restingFrame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        return BubbleWidgetPlacement.expansionEdge(from: restingFrame, edge: edge, in: visible)
    }

    private func applyInteraction(_ state: WidgetInteractionController.State) {
        guard let panel, let restingFrame else { return }
        if state == .collapsed {
            stopDismissMonitors()
            panel.allowsKeyboard = false
            panel.resignKey()
            if !interaction.isDragging {
                clippingView?.morph(from: .expanded, to: edge == nil ? .circle : .edgeTab,
                    fromWidth: BubbleWidgetPlacement.expandedSize.width, toWidth: restingFrame.width)
            }
            setFrame(restingFrame, animated: !interaction.isDragging)
        } else {
            let visible = targetScreen(savedFrame: restingFrame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
            let expandedFrame = BubbleWidgetPlacement.expandedFrame(from: restingFrame, edge: edge, in: visible)
            if panel.frame.size != expandedFrame.size {
                clippingView?.morph(from: edge == nil ? .circle : .edgeTab, to: .expanded,
                    fromWidth: restingFrame.width, toWidth: expandedFrame.width)
                setFrame(expandedFrame, animated: true)
            }
            panel.allowsKeyboard = state == .pinned
            if state == .pinned { panel.makeKeyAndOrderFront(nil) }
            else { panel.resignKey() }
            startDismissMonitors()
        }
        updateView()
    }

    private func collapse() { interaction.collapse() }

    func dismissFromExternalInteraction() {
        guard interaction.state == .preview else { return }
        collapse()
    }

    private func dragChanged(_ firstTranslation: CGSize) {
        let pointer = NSEvent.mouseLocation
        dragChanged(pointerStart: CGPoint(x: pointer.x - firstTranslation.width,
            y: pointer.y + firstTranslation.height), pointer: pointer)
    }

    private func dragChanged(pointerStart: CGPoint, pointer: CGPoint) {
        guard let panel else { return }
        interaction.beginDrag()
        if dragStartFrame == nil {
            if isExpanded { interaction.collapse() }
            dragStartFrame = panel.frame
            dragStartPointer = pointerStart
        }
        guard let start = dragStartFrame, let pointerStart = dragStartPointer else { return }
        panel.setFrameOrigin(BubbleWidgetPlacement.draggedFrame(from: start, pointerStart: pointerStart, pointerNow: pointer).origin)
    }

    private func dragEnded() {
        guard let panel, dragStartFrame != nil else { return }
        dragStartFrame = nil
        dragStartPointer = nil
        let visible = targetScreen(savedFrame: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let bubbleFrame = CGRect(
            x: panel.frame.midX - BubbleWidgetPlacement.bubbleSize.width / 2,
            y: panel.frame.midY - BubbleWidgetPlacement.bubbleSize.height / 2,
            width: BubbleWidgetPlacement.bubbleSize.width,
            height: BubbleWidgetPlacement.bubbleSize.height
        )
        placeResting(BubbleWidgetPlacement.clamped(bubbleFrame, in: visible), visibleFrame: visible, animated: true)
        interaction.endDrag()
    }

    private func placeResting(_ bubbleFrame: CGRect, visibleFrame: CGRect, animated: Bool = false) {
        guard panel != nil else { return }
        let nextEdge = BubbleWidgetPlacement.edge(for: bubbleFrame, in: visibleFrame)
        let shouldAnimate = animated && nextEdge == edge
        edge = nextEdge
        let frame = edge.map { BubbleWidgetPlacement.tabFrame(from: bubbleFrame, edge: $0, in: visibleFrame) }
            ?? bubbleFrame
        restingFrame = frame
        setFrame(frame, animated: shouldAnimate)
        updateView(animated: shouldAnimate)
        persist(frame)
    }

    private func setFrame(_ frame: CGRect, animated: Bool) {
        guard let panel else { return }
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            panel.setFrame(frame, display: true)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.30
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1)
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func updateView(animated: Bool) {
        guard animated else { updateView(); return }
        let animation: Animation = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.32, dampingFraction: 0.86)
        withAnimation(animation) { updateView() }
    }

    private func startDismissMonitors() {
        stopDismissMonitors()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) { self.dismissFromExternalInteraction() }
        }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel, self.isExpanded else { return event }
            if event.type == .keyDown {
                guard event.keyCode == 53, panel.isKeyWindow else { return event }
                self.collapse()
                return nil
            }
            if event.window !== panel { self.dismissFromExternalInteraction() }
            return event
        }
    }

    private func stopDismissMonitors() {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        outsideClickMonitor = nil
        escapeMonitor = nil
    }

    private func targetScreen(savedFrame: CGRect?) -> NSScreen? {
        if let savedFrame,
           let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: savedFrame.midX, y: savedFrame.midY)) }) {
            return screen
        }
        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(pointer) }) ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func savedFrame() -> CGRect? {
        guard let text = UserDefaults.standard.string(forKey: frameDefaultsKey) else { return nil }
        let frame = NSRectFromString(text)
        guard frame.minX.isFinite, frame.minY.isFinite, frame.width > 0, frame.height > 0 else { return nil }
        return frame
    }

    private func persist(_ frame: CGRect) {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: frameDefaultsKey)
    }
}

private final class BubbleClippingView: NSView {
    enum Silhouette: Equatable {
        case circle
        case edgeTab
        case expanded
    }

    var onPointerChange: ((Bool) -> Void)?
    var orbOnLeft = false { didSet { updateMask() } }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { onPointerChange?(true) }
    override func mouseExited(with event: NSEvent) { onPointerChange?(false) }

    var silhouette: Silhouette = .circle {
        didSet {
            if silhouette != oldValue { shapeMorph = nil }
            updateMask()
        }
    }

    private var shapeMorph: (from: Silhouette, to: Silhouette, fromWidth: CGFloat, toWidth: CGFloat)?
    private let maskLayer = CAShapeLayer()

    func morph(from: Silhouette, to: Silhouette, fromWidth: CGFloat, toWidth: CGFloat) {
        silhouette = to
        shapeMorph = (from, to, fromWidth, toWidth)
        updateMask()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.mask = maskLayer
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.mask = maskLayer
    }

    override func layout() {
        super.layout()
        updateMask()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateMask()
    }

    private func updateMask() {
        guard let layer else { return }
        let tabProgress: CGFloat
        if let shapeMorph, shapeMorph.fromWidth != shapeMorph.toWidth {
            let progress = min(1, max(0, (bounds.width - shapeMorph.fromWidth) / (shapeMorph.toWidth - shapeMorph.fromWidth)))
            tabProgress = (shapeMorph.from == .edgeTab ? 1 : 0) * (1 - progress)
                + (shapeMorph.to == .edgeTab ? 1 : 0) * progress
        } else {
            tabProgress = silhouette == .edgeTab ? 1 : 0
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        layer.contentsScale = scale
        // Supersample only the silhouette so curved edges keep fractional coverage.
        maskLayer.contentsScale = scale * 2
        maskLayer.shouldRasterize = true
        maskLayer.rasterizationScale = maskLayer.contentsScale
        maskLayer.frame = bounds
        maskLayer.path = OrbitalWidgetShape(orbOnLeft: orbOnLeft, tabProgress: tabProgress).path(in: bounds).cgPath
        layer.mask = maskLayer
        CATransaction.commit()
    }

}

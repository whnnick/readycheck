import AppKit
import QuartzCore
import ReadyCheckCore
import SwiftUI

@MainActor
final class BubbleWindowController: NSObject, NSWindowDelegate {
    private let frameDefaultsKey = "ReadyCheck.bubbleWidgetFrame.v1"
    private var panel: NSPanel?
    private var hostingController: NSHostingController<BubbleWidgetView>?
    private var clippingView: BubbleClippingView?
    private weak var model: ReadyCheckAppModel?
    private var restingFrame: CGRect?
    private var edge: BubbleWidgetPlacement.Edge?
    private var isExpanded = false
    private var dragStartFrame: CGRect?
    private var dragStartPointer: CGPoint?
    private var outsideClickMonitor: Any?
    private var escapeMonitor: Any?
    var onVisibilityChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func show(model: ReadyCheckAppModel) {
        self.model = model
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: BubbleWidgetPlacement.bubbleSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.delegate = self
        panel.level = model.widgetAlwaysOnTop ? .floating : .normal
        self.panel = panel

        let view = makeView(model: model)
        let host = NSHostingController(rootView: view)
        let clip = BubbleClippingView()
        let container = NSViewController()
        container.view = clip
        container.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
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

    func close() {
        close(persistingPosition: true)
    }

    private func close(persistingPosition: Bool) {
        stopDismissMonitors()
        guard let panel else { return }
        if persistingPosition, let restingFrame { persist(restingFrame) }
        panel.delegate = nil
        self.panel = nil
        hostingController = nil
        clippingView = nil
        panel.close()
        isExpanded = false
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
        hostingController = nil
        clippingView = nil
        onVisibilityChanged?(false)
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
            tabEdge: isExpanded ? nil : edge,
            onTap: { [weak self] in self?.toggleExpanded() },
            onDragChanged: { [weak self] translation in self?.dragChanged(translation) },
            onDragEnded: { [weak self] in self?.dragEnded() },
            onCollapse: { [weak self] in self?.collapse() }
        )
    }

    private func updateView() {
        guard let model else { return }
        clippingView?.silhouette = isExpanded ? .expanded : (edge == nil ? .circle : .edgeTab)
        hostingController?.rootView = makeView(model: model)
    }

    private func toggleExpanded() {
        if isExpanded { collapse(); return }
        guard let panel, let restingFrame else { return }
        isExpanded = true
        let visible = targetScreen(savedFrame: restingFrame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        setFrame(BubbleWidgetPlacement.expandedFrame(from: restingFrame, edge: edge, in: visible), animated: true)
        panel.makeKeyAndOrderFront(nil)
        updateView(animated: edge != nil)
        startDismissMonitors()
    }

    private func collapse() {
        guard isExpanded, panel != nil, let restingFrame else { return }
        stopDismissMonitors()
        isExpanded = false
        if edge == nil {
            updateView()
            setFrame(restingFrame, animated: true)
            return
        }
        setFrame(restingFrame, animated: true)
        updateView(animated: true)
    }

    private func dragChanged(_ firstTranslation: CGSize) {
        guard !isExpanded, let panel else { return }
        let pointer = NSEvent.mouseLocation
        if dragStartFrame == nil {
            dragStartFrame = panel.frame
            dragStartPointer = CGPoint(x: pointer.x - firstTranslation.width, y: pointer.y + firstTranslation.height)
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
            context.duration = 0.24
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
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) { self.collapse() }
        }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53, self?.isExpanded == true else { return event }
            self?.collapse()
            return nil
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
    enum Silhouette {
        case circle
        case edgeTab
        case expanded
    }

    var silhouette: Silhouette = .circle {
        didSet { updateMask() }
    }

    private let maskLayer = CAShapeLayer()

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

    private func updateMask() {
        guard let layer else { return }
        let path: CGPath
        switch silhouette {
        case .circle:
            path = CGPath(ellipseIn: bounds, transform: nil)
        case .edgeTab:
            path = CGPath(roundedRect: bounds, cornerWidth: 21, cornerHeight: 21, transform: nil)
        case .expanded:
            path = CGPath(roundedRect: bounds.insetBy(dx: 7, dy: 7), cornerWidth: 18, cornerHeight: 18, transform: nil)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.frame = bounds
        maskLayer.path = path
        layer.mask = maskLayer
        CATransaction.commit()
    }
}

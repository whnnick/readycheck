import AppKit
import QuartzCore
import ReadyCheckCore
import SwiftUI

@MainActor
final class EdgeRailWindowController: NSObject, NSWindowDelegate {
    private let frameDefaultsKey = "ReadyCheck.edgeRailFrame.v1"
    private var panel: NSPanel?
    private var hostingController: NSHostingController<EdgeRailWidgetView>?
    private var trackingView: EdgeRailTrackingView?
    private weak var model: ReadyCheckAppModel?
    private var edge: EdgeRailPlacement.Edge = .right
    private var centerY: CGFloat = 0
    private var mode: EdgeRailPlacement.Mode = .collapsed
    private var keepDockUntilHover = false
    private var expandTask: Task<Void, Never>?
    private var collapseTask: Task<Void, Never>?
    private var dragStartFrame: CGRect?
    private var dragStartPointer: CGPoint?
    var onVisibilityChanged: ((Bool) -> Void)?
    var onEdgeChanged: ((EdgeRailPlacement.Edge) -> Void)?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    func show(model: ReadyCheckAppModel) {
        self.model = model
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let saved = savedFrame()
        let screen = targetScreen(for: saved)
        let visible = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        edge = savedEdge()
        centerY = saved?.midY ?? EdgeRailPlacement.defaultCenterY(in: visible)
        mode = .dock
        keepDockUntilHover = true
        let frame = layoutFrame(in: visible)

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.level = model.widgetAlwaysOnTop ? .floating : .normal
        panel.delegate = self
        self.panel = panel

        let host = NSHostingController(rootView: makeView(model: model))
        let tracker = EdgeRailTrackingView()
        tracker.onPointerChange = { [weak self] in self?.hoverChanged($0) }
        let container = NSViewController()
        container.view = tracker
        container.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        tracker.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: tracker.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: tracker.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: tracker.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: tracker.bottomAnchor)
        ])
        hostingController = host
        trackingView = tracker
        panel.contentViewController = container
        panel.orderFrontRegardless()
        onVisibilityChanged?(true)
        onEdgeChanged?(edge)
    }

    func close() { close(persistingPosition: true) }

    private func close(persistingPosition: Bool) {
        expandTask?.cancel()
        expandTask = nil
        collapseTask?.cancel()
        collapseTask = nil
        guard let panel else { return }
        if persistingPosition { persist() }
        panel.delegate = nil
        self.panel = nil
        hostingController = nil
        trackingView = nil
        model = nil
        dragStartFrame = nil
        dragStartPointer = nil
        keepDockUntilHover = false
        panel.close()
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

    func savedEdge() -> EdgeRailPlacement.Edge {
        guard let saved = savedFrame() else { return .right }
        let visible = targetScreen(for: saved)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        return saved.midX < visible.midX ? .left : .right
    }

    func move(to newEdge: EdgeRailPlacement.Edge, model: ReadyCheckAppModel) {
        if panel == nil { show(model: model) }
        guard let panel else { return }
        edge = newEdge
        mode = .dock
        keepDockUntilHover = true
        expandTask?.cancel()
        expandTask = nil
        collapseTask?.cancel()
        let visible = targetScreen(for: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        panel.setFrame(layoutFrame(in: visible), display: true)
        updateView()
        panel.orderFrontRegardless()
        persist()
        onEdgeChanged?(edge)
    }

    func reveal(model: ReadyCheckAppModel) {
        if panel == nil { show(model: model) }
        keepDockUntilHover = true
        expandTask?.cancel()
        expandTask = nil
        collapseTask?.cancel()
        setMode(.dock)
        panel?.orderFrontRegardless()
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === panel else { return }
        expandTask?.cancel()
        expandTask = nil
        collapseTask?.cancel()
        persist()
        panel = nil
        hostingController = nil
        trackingView = nil
        model = nil
        onVisibilityChanged?(false)
    }

    @objc private func screenParametersDidChange() {
        guard let panel else { return }
        let visible = targetScreen(for: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        centerY = layoutFrame(in: visible).midY
        panel.setFrame(layoutFrame(in: visible), display: true)
        persist()
    }

    private func makeView(model: ReadyCheckAppModel) -> EdgeRailWidgetView {
        EdgeRailWidgetView(
            model: model,
            edge: edge,
            mode: mode,
            height: layoutHeight(in: targetScreen(for: panel?.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero),
            onHover: { [weak self] isInside in self?.hoverChanged(isInside) },
            onExpand: { [weak self] in self?.expandDock() },
            onToggleDetail: { [weak self] in self?.toggleDetail() },
            onDragChanged: { [weak self] translation in self?.dragChanged(translation) },
            onDragEnded: { [weak self] in self?.dragEnded() }
        )
    }

    private func layoutHeight(in visible: CGRect) -> CGFloat {
        let windows = model?.snapshots.first { $0.providerId == "codex-oauth" }?.windows ?? []
        return EdgeRailPlacement.contentHeight(for: EdgeRailPlacement.displayWindows(in: windows), maximum: visible.height, mode: mode)
    }

    private func layoutFrame(in visible: CGRect) -> CGRect {
        EdgeRailPlacement.frame(edge: edge, centerY: centerY, mode: mode, in: visible, height: layoutHeight(in: visible))
    }

    func updateQuotaLayout() {
        guard let panel, dragStartFrame == nil else { return }
        let visible = targetScreen(for: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let frame = layoutFrame(in: visible)
        if panel.frame.size != frame.size {
            panel.setFrame(frame, display: true)
            updateView()
        }
    }

    private func updateView() {
        guard let model else { return }
        hostingController?.rootView = makeView(model: model)
    }

    private func hoverChanged(_ isInside: Bool) {
        if isInside {
            if mode == .collapsed {
                keepDockUntilHover = false
                scheduleExpansion()
            } else if panel?.frame.contains(NSEvent.mouseLocation) == true {
                keepDockUntilHover = false
                scheduleCollapse()
            }
        } else {
            expandTask?.cancel()
            expandTask = nil
            if mode != .collapsed, !keepDockUntilHover { scheduleCollapse() }
        }
    }

    private func scheduleExpansion() {
        guard expandTask == nil else { return }
        expandTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard !Task.isCancelled, let self, let panel = self.panel else { return }
            self.expandTask = nil
            guard self.mode == .collapsed, self.dragStartFrame == nil,
                  panel.frame.contains(NSEvent.mouseLocation) else { return }
            self.expandDock()
        }
    }

    private func expandDock() {
        expandTask?.cancel()
        expandTask = nil
        keepDockUntilHover = true
        collapseTask?.cancel()
        setMode(.dock)
    }

    private func toggleDetail() {
        collapseTask?.cancel()
        setMode(mode == .detail ? .dock : .detail)
        scheduleCollapse()
    }

    private func scheduleCollapse() {
        collapseTask?.cancel()
        collapseTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled, let self, let panel = self.panel else { return }
                if self.dragStartFrame == nil, !panel.frame.contains(NSEvent.mouseLocation) {
                    self.setMode(.collapsed)
                    return
                }
            }
        }
    }

    private func setMode(_ newMode: EdgeRailPlacement.Mode) {
        guard let panel, mode != newMode else { return }
        if newMode != .collapsed {
            expandTask?.cancel()
            expandTask = nil
        }
        mode = newMode
        let visible = targetScreen(for: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let frame = layoutFrame(in: visible)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.setFrame(frame, display: true)
            updateView()
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.26
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1)
                panel.animator().setFrame(frame, display: true)
            }
            withAnimation(.spring(response: 0.30, dampingFraction: 1)) { updateView() }
        }
    }

    private func dragChanged(_ firstTranslation: CGSize) {
        guard let panel else { return }
        expandTask?.cancel()
        expandTask = nil
        keepDockUntilHover = false
        collapseTask?.cancel()
        if mode == .detail { setMode(.dock) }
        let pointer = NSEvent.mouseLocation
        if dragStartFrame == nil {
            dragStartFrame = panel.frame
            dragStartPointer = CGPoint(x: pointer.x - firstTranslation.width, y: pointer.y + firstTranslation.height)
        }
        guard let start = dragStartFrame, let pointerStart = dragStartPointer else { return }
        panel.setFrameOrigin(CGPoint(x: start.minX + pointer.x - pointerStart.x,
                                     y: start.minY + pointer.y - pointerStart.y))
    }

    private func dragEnded() {
        guard let panel, dragStartFrame != nil else { return }
        dragStartFrame = nil
        dragStartPointer = nil
        let visible = targetScreen(for: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        edge = EdgeRailPlacement.edge(for: CGPoint(x: panel.frame.midX, y: panel.frame.midY), in: visible)
        centerY = panel.frame.midY
        panel.setFrame(layoutFrame(in: visible), display: true)
        updateView()
        persist()
        onEdgeChanged?(edge)
        if !panel.frame.contains(NSEvent.mouseLocation) { scheduleCollapse() }
    }

    private func targetScreen(for frame: CGRect?) -> NSScreen? {
        if let frame, let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: frame.midX, y: frame.midY)) }) {
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

    private func persist() {
        guard let panel else { return }
        let visible = targetScreen(for: panel.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let resting = EdgeRailPlacement.frame(edge: edge, centerY: centerY, mode: .dock, in: visible, height: layoutHeight(in: visible))
        UserDefaults.standard.set(NSStringFromRect(resting), forKey: frameDefaultsKey)
    }
}

private final class EdgeRailTrackingView: NSView {
    var onPointerChange: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) { onPointerChange?(true) }
    override func mouseExited(with event: NSEvent) { onPointerChange?(false) }
}

import AppKit

/// Shared timing and intent for the bubble and edge rings.
@MainActor
final class WidgetInteractionController {
    enum State: Equatable { case collapsed, preview, pinned }

    private(set) var state: State = .collapsed
    private(set) var isDragging = false
    private var isInside = false
    private var requiresExit = false
    private var hoverTask: Task<Void, Never>?
    private var exitTask: Task<Void, Never>?
    private let hoverDelay: Duration
    private let exitDelay: Duration
    var onChange: ((State) -> Void)?
    var containsPointer: () -> Bool = { true }

    init(hoverDelay: Duration = .milliseconds(500), exitDelay: Duration = .milliseconds(200)) {
        self.hoverDelay = hoverDelay
        self.exitDelay = exitDelay
    }

    func hoverChanged(_ inside: Bool) {
        isInside = inside
        if inside {
            exitTask?.cancel()
            exitTask = nil
            guard state == .collapsed, !requiresExit, !isDragging, hoverTask == nil else { return }
            hoverTask = Task { [weak self, hoverDelay] in
                do { try await Task.sleep(for: hoverDelay) } catch { return }
                guard let self, !Task.isCancelled else { return }
                self.hoverTask = nil
                guard self.isInside, !self.isDragging, !self.requiresExit,
                      self.state == .collapsed, self.containsPointer() else { return }
                self.setState(.preview)
            }
        } else {
            requiresExit = false
            hoverTask?.cancel()
            hoverTask = nil
            guard state == .preview, !isDragging else { return }
            exitTask?.cancel()
            exitTask = Task { [weak self, exitDelay] in
                do { try await Task.sleep(for: exitDelay) } catch { return }
                guard let self, !Task.isCancelled else { return }
                self.exitTask = nil
                guard !self.isInside, !self.containsPointer(), self.state == .preview else { return }
                self.setState(.collapsed)
            }
        }
    }

    func click() {
        guard !isDragging else { return }
        if state == .pinned { collapse() }
        else { cancelTimers(); setState(.pinned) }
    }

    func pinPreview() {
        guard state == .preview, !isDragging else { return }
        cancelTimers()
        setState(.pinned)
    }

    func togglePin() {
        guard state != .collapsed, !isDragging else { return }
        cancelTimers()
        requiresExit = false
        if state == .preview { setState(.pinned) }
        else {
            setState(.preview)
            if !isInside { hoverChanged(false) }
        }
    }

    func showPreview() {
        cancelTimers()
        requiresExit = false
        setState(.preview)
    }

    func collapse() {
        cancelTimers()
        requiresExit = isInside
        setState(.collapsed)
    }

    func beginDrag() {
        cancelTimers()
        isDragging = true
    }

    func endDrag() {
        isDragging = false
        requiresExit = true
        if state == .preview, !containsPointer() { collapse() }
    }

    func spaceChanged() {
        reset()
        onChange?(.collapsed)
    }

    func reset() {
        cancelTimers()
        state = .collapsed
        isInside = false
        requiresExit = false
        isDragging = false
    }

    private func cancelTimers() {
        hoverTask?.cancel()
        exitTask?.cancel()
        hoverTask = nil
        exitTask = nil
    }

    private func setState(_ value: State) {
        guard value != state else { return }
        state = value
        onChange?(value)
    }
}

final class QuotaWidgetPanel: NSPanel {
    var allowsKeyboard = false
    override var canBecomeKey: Bool { allowsKeyboard }
    override var canBecomeMain: Bool { false }
}

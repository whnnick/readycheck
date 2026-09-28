import AppKit
import ReadyCheckCore
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let model: ReadyCheckAppModel
    private let openSettings: @MainActor () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var outsideClickMonitor: Any?

    init(model: ReadyCheckAppModel, openSettings: @escaping @MainActor () -> Void) {
        self.model = model
        self.openSettings = openSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
        configurePopover()
    }

    func closePopover() {
        popover.performClose(nil)
        stopOutsideClickMonitoring()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = makeMenuBarMark()
        button.imagePosition = .imageOnly
        button.toolTip = "ReadyCheck"
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func makeMenuBarMark() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20))
        image.lockFocus()

        let mark = NSBezierPath()
        mark.lineWidth = 2.8
        mark.lineCapStyle = .round
        mark.appendArc(
            withCenter: NSPoint(x: 10, y: 10),
            radius: 6.3,
            startAngle: 32,
            endAngle: 328
        )
        NSColor.black.setStroke()
        mark.stroke()

        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "ReadyCheck"
        return image
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 340, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarQuotaView(
                model: model,
                openSettings: { [weak self] in
                    self?.closePopover()
                    self?.openSettings()
                }
            )
        )
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
            return
        }

        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        DispatchQueue.main.async { [weak self] in
            self?.keepPopoverInsideVisibleScreen()
        }
        startOutsideClickMonitoring()
    }

    private func keepPopoverInsideVisibleScreen() {
        guard popover.isShown,
              let window = popover.contentViewController?.view.window,
              let screen = window.screen
        else {
            return
        }

        let frame = FloatingWidgetPlacement.clampedFrame(
            currentFrame: window.frame,
            visibleFrame: screen.visibleFrame,
            margin: 0
        )
        guard frame != window.frame else { return }
        window.setFrame(frame, display: true)
    }

    func popoverDidClose(_ notification: Notification) {
        stopOutsideClickMonitoring()
    }

    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard self?.popover.isShown == true else { return }
                self?.closePopover()
            }
        }
    }

    private func stopOutsideClickMonitoring() {
        guard let outsideClickMonitor else { return }
        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }
}

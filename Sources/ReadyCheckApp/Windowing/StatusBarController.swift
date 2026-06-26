import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let model: ReadyCheckAppModel
    private let openSettings: @MainActor () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()

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
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(
            systemSymbolName: "gauge.with.dots.needle.67percent",
            accessibilityDescription: "ReadyCheck"
        )
        button.image?.isTemplate = true
        button.imagePosition = .imageOnly
        button.toolTip = "ReadyCheck"
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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
    }
}

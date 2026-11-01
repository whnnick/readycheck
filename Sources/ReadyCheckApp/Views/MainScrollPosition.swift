import AppKit
import SwiftUI

// Keep the existing SwiftUI scroll view while restoring its exact desktop offset.
struct MainScrollPosition: NSViewRepresentable {
    let identity: String
    @Binding var offset: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ view: NSView, context: Context) {
        let coordinator = context.coordinator
        let position = $offset
        DispatchQueue.main.async {
            guard let scroll = view.enclosingScrollView else { return }
            coordinator.attach(scroll, identity: identity, position: position)
        }
    }
    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) { coordinator.stop() }

    @MainActor final class Coordinator: NSObject {
        private weak var scroll: NSScrollView?
        private var identity: String?
        private var position: Binding<CGFloat>?
        private var restoring = false

        func attach(_ scroll: NSScrollView, identity: String, position: Binding<CGFloat>) {
            guard self.scroll !== scroll || self.identity != identity else { self.position = position; return }
            stop()
            self.scroll = scroll
            self.identity = identity
            self.position = position
            restoring = true
            scroll.contentView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(self, selector: #selector(changed), name: NSView.boundsDidChangeNotification, object: scroll.contentView)
            DispatchQueue.main.async { [weak self, weak scroll] in
                guard let self, let scroll, self.identity == identity else { return }
                let maximum = max(0, (scroll.documentView?.bounds.height ?? 0) - scroll.contentView.bounds.height)
                scroll.contentView.scroll(to: NSPoint(x: 0, y: min(maximum, max(0, position.wrappedValue))))
                scroll.reflectScrolledClipView(scroll.contentView)
                self.restoring = false
            }
        }
        @objc private func changed() {
            guard !restoring, let scroll, let position else { return }
            let y = scroll.contentView.bounds.minY
            DispatchQueue.main.async { position.wrappedValue = y }
        }
        func stop() {
            NotificationCenter.default.removeObserver(self)
            scroll = nil
            identity = nil
        }
        deinit { NotificationCenter.default.removeObserver(self) }
    }
}

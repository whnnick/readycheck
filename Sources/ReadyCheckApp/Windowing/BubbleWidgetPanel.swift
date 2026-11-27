import AppKit

final class BubbleWidgetPanel: QuotaWidgetPanel {
    private static let dragThreshold: CGFloat = 4
    var canStartDrag: (CGPoint) -> Bool = { _ in false }
    var onPointerDown: () -> Void = {}
    var onPointerPress: ((CGPoint) -> Void)?
    var onPointerDrag: (CGPoint, CGPoint) -> Void = { _, _ in }
    var onPointerUp: (Bool) -> Void = { _ in }
    var onPointerClick: (() -> Void)?
    private var pointerStart: (window: CGPoint, screen: CGPoint)?
    private var didDrag = false

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown where canStartDrag(event.locationInWindow):
            let point = event.locationInWindow
            pointerStart = (point, convertPoint(toScreen: point))
            didDrag = false
            onPointerDown()
            onPointerPress?(point)
            return
        case .leftMouseDragged:
            if let pointerStart {
                let pointer = convertPoint(toScreen: event.locationInWindow)
                if didDrag || hypot(pointer.x - pointerStart.screen.x, pointer.y - pointerStart.screen.y) >= Self.dragThreshold {
                    didDrag = true
                    onPointerDrag(pointerStart.screen, pointer)
                }
                return
            }
        case .leftMouseUp:
            if let start = pointerStart {
                let moved = didDrag
                pointerStart = nil
                didDrag = false
                onPointerUp(moved)
                let end = event.locationInWindow
                if !moved, hypot(end.x - start.window.x, end.y - start.window.y) < Self.dragThreshold {
                    onPointerClick?()
                }
                return
            }
        default:
            break
        }
        super.sendEvent(event)
    }
}

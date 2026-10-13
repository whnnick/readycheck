import AppKit

final class BubbleWidgetPanel: QuotaWidgetPanel {
    var canStartDrag: (CGPoint) -> Bool = { _ in false }
    var onPointerDown: () -> Void = {}
    var onPointerDrag: (CGPoint, CGPoint) -> Void = { _, _ in }
    var onPointerUp: (Bool) -> Void = { _ in }
    private var pointerStart: CGPoint?
    private var didDrag = false

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown where canStartDrag(event.locationInWindow):
            pointerStart = convertPoint(toScreen: event.locationInWindow)
            didDrag = false
            onPointerDown()
            return
        case .leftMouseDragged:
            if let pointerStart {
                let pointer = convertPoint(toScreen: event.locationInWindow)
                if didDrag || hypot(pointer.x - pointerStart.x, pointer.y - pointerStart.y) >= 4 {
                    didDrag = true
                    onPointerDrag(pointerStart, pointer)
                }
                return
            }
        case .leftMouseUp:
            if pointerStart != nil {
                let moved = didDrag
                pointerStart = nil
                didDrag = false
                onPointerUp(moved)
                return
            }
        default:
            break
        }
        super.sendEvent(event)
    }
}

import CoreGraphics

public enum BubbleWidgetPlacement {
    public enum Edge: String, Codable, Sendable {
        case left
        case right
    }

    public static let bubbleSize = CGSize(width: 92, height: 92)
    public static let tabSize = CGSize(width: 28, height: 144)
    public static let expandedSize = CGSize(width: 380, height: 304)
    public static let snapDistance: CGFloat = 34

    public static func defaultFrame(in visibleFrame: CGRect) -> CGRect {
        CGRect(
            x: max(visibleFrame.minX, visibleFrame.maxX - bubbleSize.width - 48),
            y: max(visibleFrame.minY, visibleFrame.minY + 90),
            width: bubbleSize.width,
            height: bubbleSize.height
        )
    }

    public static func restoredBubbleFrame(from savedFrame: CGRect, in visibleFrame: CGRect) -> CGRect {
        let centerY = savedFrame.midY - bubbleSize.height / 2
        let x: CGFloat
        if savedFrame.width < bubbleSize.width,
           let edge = edge(for: savedFrame, in: visibleFrame) {
            x = edge == .left ? visibleFrame.minX : visibleFrame.maxX - bubbleSize.width
        } else {
            x = savedFrame.midX - bubbleSize.width / 2
        }
        return clamped(CGRect(x: x, y: centerY, width: bubbleSize.width, height: bubbleSize.height), in: visibleFrame)
    }

    public static func draggedFrame(from startFrame: CGRect, pointerStart: CGPoint, pointerNow: CGPoint) -> CGRect {
        startFrame.offsetBy(dx: pointerNow.x - pointerStart.x, dy: pointerNow.y - pointerStart.y)
    }

    public static func edge(for frame: CGRect, in visibleFrame: CGRect) -> Edge? {
        if frame.minX - visibleFrame.minX <= snapDistance { return .left }
        if visibleFrame.maxX - frame.maxX <= snapDistance { return .right }
        return nil
    }

    public static func tabFrame(from bubbleFrame: CGRect, edge: Edge, in visibleFrame: CGRect) -> CGRect {
        let x = edge == .left ? visibleFrame.minX : visibleFrame.maxX - tabSize.width
        let y = clamp(bubbleFrame.midY - tabSize.height / 2,
                      lower: visibleFrame.minY,
                      upper: visibleFrame.maxY - tabSize.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: tabSize)
    }

    public static func expandedFrame(from restingFrame: CGRect, edge: Edge?, in visibleFrame: CGRect) -> CGRect {
        let size = CGSize(width: min(expandedSize.width, visibleFrame.width),
                          height: min(expandedSize.height, visibleFrame.height))
        let side = expansionEdge(from: restingFrame, edge: edge, in: visibleFrame)
        let proposedX: CGFloat
        if let edge {
            proposedX = edge == .left ? visibleFrame.minX : visibleFrame.maxX - size.width
        } else {
            let radius = min(bubbleSize.width, size.width) / 2
            proposedX = side == .left ? restingFrame.midX - radius
                : restingFrame.midX + radius - size.width
        }
        let x = clamp(proposedX, lower: visibleFrame.minX, upper: visibleFrame.maxX - size.width)
        let y = clamp(restingFrame.midY - size.height / 2,
                      lower: visibleFrame.minY,
                      upper: visibleFrame.maxY - size.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    public static func expansionEdge(from restingFrame: CGRect, edge: Edge?, in visibleFrame: CGRect) -> Edge {
        edge ?? (restingFrame.midX < visibleFrame.midX ? .left : .right)
    }

    public static func clamped(_ frame: CGRect, in visibleFrame: CGRect) -> CGRect {
        CGRect(
            x: clamp(frame.minX, lower: visibleFrame.minX, upper: visibleFrame.maxX - frame.width),
            y: clamp(frame.minY, lower: visibleFrame.minY, upper: visibleFrame.maxY - frame.height),
            width: frame.width,
            height: frame.height
        )
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

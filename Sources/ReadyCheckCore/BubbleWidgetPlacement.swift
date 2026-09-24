import CoreGraphics

public enum BubbleWidgetPlacement {
    public enum Edge: String, Codable, Sendable {
        case left
        case right
    }

    public static let bubbleSize = CGSize(width: 76, height: 76)
    public static let tabSize = CGSize(width: 66, height: 114)
    public static let expandedSize = CGSize(width: 282, height: 156)
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
        let proposedX = edge == .left ? visibleFrame.minX : restingFrame.maxX - expandedSize.width
        let x = clamp(proposedX, lower: visibleFrame.minX, upper: visibleFrame.maxX - expandedSize.width)
        let y = clamp(restingFrame.midY - expandedSize.height / 2,
                      lower: visibleFrame.minY,
                      upper: visibleFrame.maxY - expandedSize.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: expandedSize)
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

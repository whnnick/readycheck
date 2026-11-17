import CoreGraphics

public enum AggregateCapsulePlacement {
    public static let rowHeight: CGFloat = 54
    public static let rowSpacing: CGFloat = 4
    public static let size = size(serviceCount: 3)

    public static func size(serviceCount: Int) -> CGSize {
        let rows = CGFloat(max(1, serviceCount))
        return CGSize(width: 48, height: 34 + rows * rowHeight + (rows - 1) * rowSpacing)
    }
    public static let detailSize = CGSize(width: 360, height: 400)
    public static let gap: CGFloat = 10

    public static func restoredFrame(from saved: CGRect?, in visible: CGRect, size: CGSize = size) -> CGRect {
        let size = CGSize(width: min(size.width, visible.width), height: min(size.height, visible.height))
        let seed = saved ?? BubbleWidgetPlacement.defaultFrame(in: visible, size: size)
        let x: CGFloat
        if abs(seed.minX - visible.minX) < 0.5 { x = visible.minX }
        else if abs(seed.maxX - visible.maxX) < 0.5 { x = visible.maxX - size.width }
        else { x = seed.midX - size.width / 2 }
        return BubbleWidgetPlacement.clamped(CGRect(x: x, y: seed.midY - size.height / 2,
            width: size.width, height: size.height), in: visible)
    }

    public static func snappedFrame(_ frame: CGRect, in visible: CGRect) -> CGRect {
        var frame = BubbleWidgetPlacement.clamped(frame, in: visible)
        if frame.minX - visible.minX <= BubbleWidgetPlacement.snapDistance { frame.origin.x = visible.minX }
        else if visible.maxX - frame.maxX <= BubbleWidgetPlacement.snapDistance { frame.origin.x = visible.maxX - frame.width }
        return frame
    }

    public static func detailFrame(beside rail: CGRect, in visible: CGRect) -> CGRect {
        let left = max(0, rail.minX - visible.minX - gap)
        let right = max(0, visible.maxX - rail.maxX - gap)
        let opensLeft = left >= right
        let width = min(detailSize.width, opensLeft ? left : right)
        let height = min(detailSize.height, visible.height)
        let proposed = CGRect(x: opensLeft ? rail.minX - gap - width : rail.maxX + gap,
            y: rail.midY - height / 2, width: width, height: height)
        return BubbleWidgetPlacement.clamped(proposed, in: visible)
    }
}

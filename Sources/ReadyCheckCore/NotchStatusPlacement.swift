import CoreGraphics

public enum NotchStatusPlacement {
    public static let defaultHeight: CGFloat = 42

    public static func shouldDetach(pointerStart: CGPoint, pointerNow: CGPoint) -> Bool {
        pointerStart.y - pointerNow.y >= 32
    }

    public static func shouldAttach(bubbleFrame: CGRect, notchGap: CGRect?, screenFrame: CGRect) -> Bool {
        guard let notchGap, notchGap.width > 0, notchGap.height > 0 else { return false }
        let center = CGPoint(x: bubbleFrame.midX, y: bubbleFrame.midY)
        let target = frame(notchGap: notchGap, screenFrame: screenFrame)
            .union(notchGap).insetBy(dx: -24, dy: -32)
        return screenFrame.contains(center) && target.contains(center)
    }

    public static func notchGap(leftArea: CGRect, rightArea: CGRect) -> CGRect? {
        let width = rightArea.minX - leftArea.maxX
        guard width > 0 else { return nil }

        let minY = min(leftArea.minY, rightArea.minY)
        let maxY = max(leftArea.maxY, rightArea.maxY)
        return CGRect(x: leftArea.maxX, y: minY, width: width, height: maxY - minY)
    }

    public static func frame(
        notchGap: CGRect,
        screenFrame: CGRect,
        height: CGFloat = defaultHeight,
        width: CGFloat? = nil
    ) -> CGRect {
        let safeHeight = min(max(1, height), max(1, screenFrame.height))
        let safeWidth = min(max(1, width ?? notchGap.width), max(1, screenFrame.width))
        let preferredX = notchGap.midX - safeWidth / 2
        let x = min(max(preferredX, screenFrame.minX), screenFrame.maxX - safeWidth)
        let preferredY = notchGap.minY - safeHeight + 1
        let y = min(max(preferredY, screenFrame.minY), screenFrame.maxY - safeHeight)

        return CGRect(x: x, y: y, width: safeWidth, height: safeHeight)
    }
}

import CoreGraphics

public enum NotchStatusPlacement {
    public static let defaultHeight: CGFloat = 42

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
        height: CGFloat = defaultHeight
    ) -> CGRect {
        let safeHeight = min(max(1, height), max(1, screenFrame.height))
        let safeWidth = min(max(1, notchGap.width), max(1, screenFrame.width))
        let preferredX = notchGap.midX - safeWidth / 2
        let x = min(max(preferredX, screenFrame.minX), screenFrame.maxX - safeWidth)
        let preferredY = notchGap.minY - safeHeight + 1
        let y = min(max(preferredY, screenFrame.minY), screenFrame.maxY - safeHeight)

        return CGRect(x: x, y: y, width: safeWidth, height: safeHeight)
    }
}

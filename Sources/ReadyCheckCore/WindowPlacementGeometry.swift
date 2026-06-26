import CoreGraphics

public enum FloatingWidgetPlacement {
    public static let defaultMargin: CGFloat = 28
    public static let defaultSize = CGSize(width: 376, height: 360)

    public static func frame(
        preferredSize: CGSize,
        visibleFrame: CGRect,
        margin: CGFloat = defaultMargin
    ) -> CGRect {
        let safeMargin = max(0, margin)
        let width = dimension(preferred: preferredSize.width, visible: visibleFrame.width, margin: safeMargin)
        let height = dimension(preferred: preferredSize.height, visible: visibleFrame.height, margin: safeMargin)
        let x = clamped(
            visibleFrame.maxX - width - safeMargin,
            lower: visibleFrame.minX,
            upper: visibleFrame.maxX - width
        )
        let y = clamped(
            visibleFrame.minY + safeMargin,
            lower: visibleFrame.minY,
            upper: visibleFrame.maxY - height
        )

        return CGRect(x: x, y: y, width: width, height: height)
    }

    public static func clampedFrame(
        currentFrame: CGRect,
        visibleFrame: CGRect,
        margin: CGFloat = defaultMargin
    ) -> CGRect {
        let safeMargin = max(0, margin)
        let width = dimension(preferred: currentFrame.width, visible: visibleFrame.width, margin: safeMargin)
        let height = dimension(preferred: currentFrame.height, visible: visibleFrame.height, margin: safeMargin)
        let x = clamped(
            currentFrame.minX,
            lower: visibleFrame.minX,
            upper: visibleFrame.maxX - width
        )
        let y = clamped(
            currentFrame.minY,
            lower: visibleFrame.minY,
            upper: visibleFrame.maxY - height
        )

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func dimension(preferred: CGFloat, visible: CGFloat, margin: CGFloat) -> CGFloat {
        guard visible > 0 else { return max(1, preferred) }

        let insetVisible = visible - margin * 2
        if insetVisible > 0 {
            return min(max(1, preferred), insetVisible)
        }

        return max(1, visible)
    }

    private static func clamped(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

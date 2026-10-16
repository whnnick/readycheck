import ReadyCheckCore
import SwiftUI

/// Shared by the SwiftUI shell and the supersampled native mask.
struct WidgetPanelShape: InsettableShape {
    var tabProgress: CGFloat = 0
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let expansion = min(1, max(0, (rect.width - BubbleWidgetPlacement.bubbleSize.width)
            / (BubbleWidgetPlacement.expandedSize.width - BubbleWidgetPlacement.bubbleSize.width)))
        let base = min(rect.width, rect.height) / 2
        let collapsed = base + (min(14, base) - base) * tabProgress
        let radius = collapsed + (min(20, base) - collapsed) * expansion
        return Path(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    }
}

import CoreGraphics

public enum EdgeRailPlacement {
    public enum Edge: String, Codable, Sendable {
        case left
        case right
    }

    public enum Mode: Equatable, Sendable {
        case collapsed
        case dock
        case detail
    }

    public static let height: CGFloat = 176
    public static let collapsedWidth: CGFloat = 32
    public static let dockWidth: CGFloat = 84
    public static let detailWidth: CGFloat = 354

    public static func frame(edge: Edge, centerY: CGFloat, mode: Mode, in visible: CGRect) -> CGRect {
        let width: CGFloat
        switch mode {
        case .collapsed: width = collapsedWidth
        case .dock: width = dockWidth
        case .detail: width = detailWidth
        }
        let x = edge == .left ? visible.minX : visible.maxX - width
        let y = clamp(centerY - height / 2, lower: visible.minY, upper: visible.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public static func edge(for pointer: CGPoint, in visible: CGRect) -> Edge {
        pointer.x < visible.midX ? .left : .right
    }

    public static func defaultCenterY(in visible: CGRect) -> CGFloat {
        visible.minY + min(visible.height * 0.6, visible.height - height / 2)
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

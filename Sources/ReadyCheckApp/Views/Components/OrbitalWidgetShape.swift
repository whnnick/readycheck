import ReadyCheckCore
import SwiftUI

/// Shared by the visible shell and the native window mask.
struct OrbitalWidgetShape: InsettableShape {
    var orbOnLeft = false
    var tabProgress: CGFloat = 0
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let w = rect.width
        let h = rect.height
        guard w > h + 1 else {
            let radius = min(w, h) / 2
            return RoundedRectangle(cornerRadius: radius + (min(14, radius) - radius) * tabProgress,
                style: .continuous).path(in: rect)
        }
        let reveal = min(1, max(0, (w - h) /
            (BubbleWidgetPlacement.expandedSize.width - BubbleWidgetPlacement.expandedSize.height)))
        let r = BubbleWidgetPlacement.dialDiameter(in: rect.size) / 2
        let cy = h / 2
        let cx = w - r
        let corner = cy + (min(48, cy) - cy) * reveal
        let shoulder = max(corner, cx - r * (1 + 0.25 * reveal))
        let joinAngle = 90 + 36 * reveal
        let radians = joinAngle * .pi / 180
        let joinX = cx + r * cos(radians)
        let joinY = cy - r * sin(radians)
        let neckX = shoulder + (joinX - shoulder) * 0.68
        let neckY = joinY + 9 * reveal
        var path = Path()
        path.move(to: CGPoint(x: corner, y: 0))
        path.addLine(to: CGPoint(x: shoulder, y: 0))
        path.addCurve(to: CGPoint(x: neckX, y: neckY),
            control1: CGPoint(x: shoulder + (joinX - shoulder) * 0.40, y: 0),
            control2: CGPoint(x: neckX - 14 * reveal, y: neckY))
        path.addCurve(to: CGPoint(x: joinX, y: joinY),
            control1: CGPoint(x: neckX + 10 * reveal, y: neckY),
            control2: CGPoint(x: joinX - sin(radians) * 8 * reveal, y: joinY - cos(radians) * 8 * reveal))
        path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                    startAngle: .degrees(-Double(joinAngle)), endAngle: .degrees(Double(joinAngle)), clockwise: false)
        path.addCurve(to: CGPoint(x: neckX, y: h - neckY),
            control1: CGPoint(x: joinX - sin(radians) * 8 * reveal, y: h - joinY + cos(radians) * 8 * reveal),
            control2: CGPoint(x: neckX + 10 * reveal, y: h - neckY))
        path.addCurve(to: CGPoint(x: shoulder, y: h),
            control1: CGPoint(x: neckX - 14 * reveal, y: h - neckY),
            control2: CGPoint(x: shoulder + (joinX - shoulder) * 0.40, y: h))
        path.addLine(to: CGPoint(x: corner, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - corner), control: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: corner))
        path.addQuadCurve(to: CGPoint(x: corner, y: 0), control: .zero)
        path.closeSubpath()
        if orbOnLeft { path = path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: w, ty: 0)) }
        return path.applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }
}

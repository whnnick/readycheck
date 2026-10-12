import SwiftUI

struct QuotaMiniTrendChart: View {
    let values: [Double?]

    var body: some View {
        Canvas { context, size in
            let color = Color(red: 0.60, green: 0.76, blue: 0.90)
            for segment in Self.segments(values: values, size: size) {
                guard let first = segment.first, let last = segment.last else { continue }
                if segment.count == 1 {
                    context.fill(Path(ellipseIn: CGRect(x: first.x - 1.3, y: first.y - 1.3,
                        width: 2.6, height: 2.6)), with: .color(color))
                } else {
                    var line = Path()
                    line.addLines(segment)
                    var area = line
                    area.addLine(to: CGPoint(x: last.x, y: size.height - 1.5))
                    area.addLine(to: CGPoint(x: first.x, y: size.height - 1.5))
                    area.closeSubpath()
                    context.fill(area, with: .linearGradient(Gradient(colors: [color.opacity(0.20), .clear]),
                        startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                    context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.4,
                        lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    /// Keep gaps and exact samples; straight interpolation cannot introduce false peaks.
    static func segments(values: [Double?], size: CGSize) -> [[CGPoint]] {
        guard !values.isEmpty, size.width > 0, size.height > 3 else { return [] }
        let maximum = max(0.01, values.compactMap { $0 }.filter { $0.isFinite && $0 >= 0 }.max() ?? 0)
        var segments: [[CGPoint]] = []
        var current: [CGPoint] = []
        for (index, value) in values.enumerated() {
            guard let value, value.isFinite, value >= 0 else {
                if !current.isEmpty { segments.append(current); current = [] }
                continue
            }
            current.append(CGPoint(x: (CGFloat(index) + 0.5) * size.width / CGFloat(values.count),
                y: size.height - 1.5 - CGFloat(value / maximum) * (size.height - 3)))
        }
        if !current.isEmpty { segments.append(current) }
        return segments
    }
}

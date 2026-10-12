import SwiftUI

struct QuotaMiniTrendChart: View {
    let values: [Double?]

    struct Bar {
        let rect: CGRect
        let isZero: Bool
    }

    var body: some View {
        Canvas { context, size in
            let color = Color(red: 0.60, green: 0.76, blue: 0.90)
            for bar in Self.bars(values: values, size: size) {
                let path = Path(roundedRect: bar.rect, cornerRadius: 1.5)
                if bar.isZero {
                    context.fill(path, with: .color(color.opacity(0.28)))
                } else {
                    context.fill(path, with: .linearGradient(Gradient(colors: [color, color.opacity(0.55)]),
                        startPoint: CGPoint(x: bar.rect.midX, y: bar.rect.minY),
                        endPoint: CGPoint(x: bar.rect.midX, y: bar.rect.maxY)))
                }
            }
        }
    }

    /// One bar per observed five-minute bin; zero uses a marker and missing data stays blank.
    static func bars(values: [Double?], size: CGSize) -> [Bar] {
        guard !values.isEmpty, size.width > 0, size.height > 3 else { return [] }
        let maximum = max(0.01, values.compactMap { $0 }.filter { $0.isFinite && $0 >= 0 }.max() ?? 0)
        let slotWidth = size.width / CGFloat(values.count)
        let barWidth = min(10, slotWidth * 0.5)
        let baseline = size.height - 1
        return values.enumerated().compactMap { index, value in
            guard let value, value.isFinite, value >= 0 else { return nil }
            let isZero = value == 0
            let width = isZero ? min(3, barWidth) : barWidth
            let height = isZero ? 1 : CGFloat(value / maximum) * (size.height - 2)
            return Bar(rect: CGRect(x: (CGFloat(index) + 0.5) * slotWidth - width / 2,
                y: baseline - height, width: width, height: height), isZero: isZero)
        }
    }
}

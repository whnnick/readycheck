import ReadyCheckCore
import SwiftUI

struct OrbitalQuotaDial: View {
    let windows: [QuotaWindow]
    let canShow: Bool
    let expansion: CGFloat
    let recoveryHighlight: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let progress = min(1, max(0, expansion))
            let ringWidth = 3 + (diameter * 0.056 - 3) * progress
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(red: 0.24, green: 0.28, blue: 0.34),
                    Color(red: 0.08, green: 0.10, blue: 0.13), Color(red: 0.21, green: 0.25, blue: 0.31)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.65), .white.opacity(0.05),
                        .white.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
                    .overlay(Circle().fill(Color(red: 0.07, green: 0.09, blue: 0.11)).padding(diameter * 0.035)
                        .shadow(color: .black.opacity(0.6), radius: 4, y: 2))
                    .opacity(progress)
                ForEach(0..<60, id: \.self) { index in
                    Capsule().fill(Color(red: 0.48, green: 0.60, blue: 0.69).opacity(index.isMultiple(of: 5) ? 0.65 : 0.24))
                        .frame(width: 1, height: index.isMultiple(of: 5) ? 6 : 3)
                            .offset(y: -(diameter / 2 - diameter * 0.07))
                        .rotationEffect(.degrees(Double(index) * 6))
                        .opacity(progress)
                }
                if windows.isEmpty {
                    Circle().stroke(Color.white.opacity(0.17), lineWidth: ringWidth)
                        .padding(6 + (diameter * 0.17 - 6) * progress)
                }
                ForEach(Array(windows.prefix(2).enumerated()), id: \.element.id) { index, window in
                    let ratio = canShow ? window.remainingRatio : nil
                    let inset = 6 + (diameter * 0.17 - 6) * progress
                        + CGFloat(index) * (8 + (diameter * 0.12 - 8) * progress)
                    Circle().stroke(Color(red: 0.26, green: 0.29, blue: 0.33), lineWidth: ringWidth)
                        .padding(inset)
                    Circle().trim(from: 0, to: max(0, min(ratio ?? 0, 1)))
                        .stroke(color(for: ratio), style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(inset)
                        .shadow(color: color(for: ratio).opacity(0.16 * progress), radius: 3)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: ratio)
                }
                ZStack {
                    cMark.frame(width: 18 + (diameter * 0.18 - 18) * progress,
                        height: 18 + (diameter * 0.18 - 18) * progress)
                        .offset(y: -10 * (1 - progress))
                        .accessibilityHidden(true)
                    Text(QuotaFormatters.percentageText(for: canShow ? windows.first?.remainingRatio : nil))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit().foregroundStyle(.white)
                        .offset(y: 8).opacity(1 - progress)
                }
                if recoveryHighlight {
                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 1).padding(2)
                }
            }
            .frame(width: diameter, height: diameter)
        }
        .accessibilityElement(children: .ignore)
    }

    private var cMark: some View {
        GeometryReader { geometry in
            let stroke = geometry.size.width * 0.19
            ZStack {
                Circle().trim(from: 0.09, to: 0.91)
                    .stroke(.white, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                Circle().trim(from: 0.79, to: 0.91)
                    .stroke(AngularGradient(colors: [.white, .cyan, .blue], center: .center,
                        startAngle: .degrees(284), endAngle: .degrees(328)),
                        style: StrokeStyle(lineWidth: stroke, lineCap: .round))
            }.padding(stroke / 2)
        }
    }

    static func color(for ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: Color(red: 0.13, green: 0.84, blue: 0.36)
        case .warning: .orange
        case .critical, .exhausted: Color(red: 1, green: 0.25, blue: 0.28)
        case .unknown: .gray
        }
    }

    private func color(for ratio: Double?) -> Color { Self.color(for: ratio) }
}

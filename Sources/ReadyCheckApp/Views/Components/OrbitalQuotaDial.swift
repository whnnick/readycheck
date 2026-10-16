import ReadyCheckCore
import SwiftUI

struct OrbitalQuotaDial: View {
    let windows: [QuotaWindow]
    let primaryLabel: String
    let canShow: Bool
    let recoveryHighlight: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            ZStack {
                ForEach(0..<2, id: \.self) { index in
                    let ratio = canShow && windows.indices.contains(index) ? windows[index].displayableRemainingRatio : nil
                    let inset = 6 + CGFloat(index) * 8
                    Circle().stroke(Color.white.opacity(0.16), lineWidth: 4).padding(inset)
                    Circle().trim(from: 0, to: max(0, min(ratio ?? 0, 1)))
                        .stroke(Self.color(for: ratio), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90)).padding(inset)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: ratio)
                }
                Text(primaryLabel).font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65)).offset(y: -12)
                Text(QuotaFormatters.percentageText(for: canShow ? windows.first?.displayableRemainingRatio : nil))
                    .font(.system(size: 17, weight: .bold, design: .rounded)).monospacedDigit()
                    .minimumScaleFactor(0.75).lineLimit(1).frame(width: diameter * 0.58)
                    .foregroundStyle(.white).offset(y: 9)
                if recoveryHighlight {
                    Circle().stroke(.white.opacity(0.35), lineWidth: 1).padding(2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
    }

    static func color(for ratio: Double?) -> Color {
        switch QuotaUrgency(remainingRatio: ratio) {
        case .normal: Color(red: 0.13, green: 0.84, blue: 0.36)
        case .warning: .orange
        case .critical, .exhausted: Color(red: 1, green: 0.25, blue: 0.28)
        case .unknown: .gray
        }
    }
}

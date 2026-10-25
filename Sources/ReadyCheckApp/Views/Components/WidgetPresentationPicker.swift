import ReadyCheckCore
import SwiftUI

struct WidgetPresentationPicker: View {
    @Binding var selection: WidgetPresentation
    let localization: LocalizationService

    var body: some View {
        HStack(spacing: 6) {
            option(.bubble)
            option(.card)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(localization.text("settings.widgetStyle"))
    }

    private func option(_ style: WidgetPresentation) -> some View {
        Button { selection = style } label: {
            VStack(spacing: 6) {
                preview(style)
                    .frame(height: 42)
                    .accessibilityHidden(true)
                Text(localization.text("widgetPresentation.\(style.rawValue)"))
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(localization.text(style == .bubble ? "widgetPreview.adaptive" : "widgetPreview.free"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 102, alignment: .top)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .background(selection == style ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selection == style ? Color.accentColor : Color.primary.opacity(0.10), lineWidth: selection == style ? 1.5 : 0.7))
        .accessibilityAddTraits(selection == style ? .isSelected : [])
        .help(localization.text(style == .bubble ? "widgetPreview.adaptiveHelp" : "widgetPreview.freeHelp"))
    }

    @ViewBuilder
    private func preview(_ style: WidgetPresentation) -> some View {
        switch style {
        case .bubble:
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(Color.secondary.opacity(0.25), lineWidth: 3)
                    Circle().trim(from: 0, to: 0.72).stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("72%").font(.system(size: 9, weight: .semibold)).monospacedDigit()
                }.frame(width: 36, height: 36)
                Image(systemName: "arrow.left.arrow.right").font(.caption2).foregroundStyle(.secondary)
                Capsule().fill(Color.primary.opacity(0.12)).frame(width: 12, height: 36)
                    .overlay(Capsule().fill(Color.accentColor).frame(width: 3, height: 24))
            }
        case .card:
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.5)).frame(width: 25, height: 4)
                Capsule().fill(Color.accentColor.opacity(0.65)).frame(height: 4)
                Capsule().fill(Color.secondary.opacity(0.3)).frame(height: 4)
            }
            .padding(8)
            .frame(width: 58, height: 36)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

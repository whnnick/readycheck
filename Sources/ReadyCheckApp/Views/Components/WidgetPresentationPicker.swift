import ReadyCheckCore
import SwiftUI

struct WidgetPresentationPicker: View {
    @Binding var selection: WidgetPresentation
    let localization: LocalizationService

    var body: some View {
        HStack(spacing: 6) {
            option(.bubble)
            option(.card)
            option(.edgeRail)
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
                Text(localization.text(style == .edgeRail ? "widgetPreview.edge" : "widgetPreview.free"))
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
        .help(localization.text(style == .edgeRail ? "widgetPreview.edgeHelp" : "widgetPreview.freeHelp"))
    }

    @ViewBuilder
    private func preview(_ style: WidgetPresentation) -> some View {
        switch style {
        case .bubble:
            Circle().stroke(Color.accentColor, lineWidth: 3).frame(width: 36, height: 36)
                .overlay(Image(systemName: "chevron.left.forwardslash.chevron.right").font(.system(size: 11, weight: .semibold)))
        case .card:
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.5)).frame(width: 25, height: 4)
                Capsule().fill(Color.accentColor.opacity(0.65)).frame(height: 4)
                Capsule().fill(Color.secondary.opacity(0.3)).frame(height: 4)
            }
            .padding(8)
            .frame(width: 58, height: 36)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        case .edgeRail:
            VStack(spacing: 4) {
                Circle().stroke(Color.accentColor, lineWidth: 2).frame(width: 13, height: 13)
                Circle().stroke(Color.secondary.opacity(0.6), lineWidth: 2).frame(width: 13, height: 13)
            }
            .frame(width: 23, height: 40)
            .background(Color.primary.opacity(0.07), in: Capsule())
        }
    }
}

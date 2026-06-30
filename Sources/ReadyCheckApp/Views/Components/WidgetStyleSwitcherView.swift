import ReadyCheckCore
import SwiftUI

struct WidgetStyleSwitcherView: View {
    @Binding var selection: WidgetDisplayMode
    let localization: LocalizationService

    var body: some View {
        HStack(spacing: 0) {
            styleButton(.minimal)
            styleButton(.detailed)
        }
        .padding(2)
        .background(Color.primary.opacity(0.10), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(localization.text("settings.widgetStyle"))
    }

    private func styleButton(_ mode: WidgetDisplayMode) -> some View {
        let isSelected = selection == mode

        return Button {
            selection = mode
        } label: {
            Text(styleTitle(for: mode))
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.72))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.accentColor)
            }
        }
        .help(styleTitle(for: mode))
    }

    private func styleTitle(for mode: WidgetDisplayMode) -> String {
        switch mode {
        case .minimal:
            localization.text("widgetStyle.minimal")
        case .detailed:
            localization.text("widgetStyle.detailed")
        }
    }
}

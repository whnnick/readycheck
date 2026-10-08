import ReadyCheckCore
import SwiftUI

struct WidgetSnoozeMenu: View {
    @Bindable var model: ReadyCheckAppModel

    var body: some View {
        if model.widgetSnoozedUntil != nil {
            Button(model.localization.text("widgetSnooze.resume")) { model.showFloatingWidget() }
        } else {
            Menu(model.localization.text("widgetSnooze.title")) {
                Button(model.localization.text("widgetSnooze.thirty")) { model.snoozeFloatingWidget(minutes: 30) }
                Button(model.localization.text("widgetSnooze.sixty")) { model.snoozeFloatingWidget(minutes: 60) }
            }
            .disabled(!model.widgetVisible)
        }
    }
}

struct WidgetSnoozeStatusView: View {
    @Bindable var model: ReadyCheckAppModel

    var body: some View {
        if let deadline = model.widgetSnoozedUntil {
            VStack(alignment: .leading, spacing: 6) {
                Label(String(format: model.localization.text("widgetSnooze.until"), timeText(deadline)), systemImage: "moon.zzz")
                    .font(.caption)
                Text(model.localization.text("widgetSnooze.help"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: model.localization.language.rawValue)
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

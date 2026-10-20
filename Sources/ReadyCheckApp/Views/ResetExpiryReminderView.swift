import ReadyCheckCore
import SwiftUI

struct ResetExpiryReminderView: View {
    @Bindable var model: ReadyCheckAppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(model.localization.text("resetExpiry.setting"), isOn: Binding(
                get: { model.resetExpiryReminderEnabled },
                set: { enabled in Task { await model.setResetExpiryReminderEnabled(enabled) } }
            )).toggleStyle(.switch).disabled(model.isUpdatingResetExpiryReminder)
            Text(model.localization.text("resetExpiry.help"))
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if model.resetExpiryReminderSaveFailed {
                Text(model.localization.text("recovery.saveFailed")).font(.caption).foregroundStyle(.red)
            }
        }
    }
}

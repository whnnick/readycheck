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
            Text(model.localization.text("resetExpiry.nodes")).font(.caption).foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { milestoneChoices }
                VStack(alignment: .leading, spacing: 8) { milestoneChoices }
            }
            .disabled(!model.resetExpiryReminderEnabled || model.isUpdatingResetExpiryReminder)
            if model.resetExpiryLeadHours.count == 1 && model.resetExpiryReminderEnabled {
                Text(model.localization.text("resetExpiry.minimum"))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if model.resetExpiryReminderSaveFailed {
                Text(model.localization.text("recovery.saveFailed")).font(.caption).foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder private var milestoneChoices: some View {
        ForEach(QuotaReminderEvaluator.manualResetLeadHours.reversed(), id: \.self) { hours in
            Toggle(String(format: model.localization.text("resetExpiry.hours"), hours), isOn: Binding(
                get: { model.resetExpiryLeadHours.contains(hours) },
                set: { selected in
                    var next = model.resetExpiryLeadHours.filter { $0 != hours }
                    if selected { next.append(hours) }
                    Task { await model.setResetExpiryLeadHours(next) }
                }
            ))
            .toggleStyle(.checkbox)
            .disabled(model.resetExpiryLeadHours.count == 1 && model.resetExpiryLeadHours.contains(hours))
        }
    }
}

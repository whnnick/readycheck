import ReadyCheckCore
import SwiftUI

struct QuotaRecoveryReminderView: View {
    @Bindable var model: ReadyCheckAppModel
    let now: Date

    private var notificationsBlocked: Bool {
        model.notificationReadiness == .denied || model.notificationReadiness == .alertsDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Toggle(isOn: Binding(
                get: { model.automaticRecoveryEnabled },
                set: { enabled in Task { await model.setAutomaticRecoveryEnabled(enabled) } }
            )) {
                Text(model.localization.text("recovery.automatic"))
                    .font(.subheadline.weight(.medium))
            }
            .toggleStyle(.switch)
            .disabled(model.isUpdatingRecoveryReminder)

            Text(model.localization.text(model.recoveryStatusKey(now: now)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if model.automaticRecoveryEnabled {
                Text(model.localization.text("recovery.automaticHelp"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if notificationsBlocked {
                    Label(model.localization.text("recovery.blocked"), systemImage: "bell.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(model.localization.text("recovery.notificationsDisabled")) {
                        model.openNotificationSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }
            if model.recoveryReminderSaveFailed {
                Text(model.localization.text("recovery.saveFailed"))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

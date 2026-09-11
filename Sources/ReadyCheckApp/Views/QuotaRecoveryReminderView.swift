import ReadyCheckCore
import SwiftUI

struct QuotaRecoveryReminderView: View {
    @Bindable var model: ReadyCheckAppModel
    let snapshot: ProviderQuotaSnapshot
    let now: Date

    var body: some View {
        if snapshot.providerId == "codex-oauth" {
            VStack(alignment: .leading, spacing: 5) {
                if model.recoveryReminderRequest != nil {
                    Label(model.localization.text("recovery.waiting"), systemImage: "bell.badge")
                        .font(.caption)
                    Button(model.localization.text("recovery.cancel")) {
                        Task { await model.cancelRecoveryReminder() }
                    }
                    .disabled(model.isUpdatingRecoveryReminder)
                    Text(model.localization.text("recovery.help"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if model.notificationReadiness == .denied || model.notificationReadiness == .alertsDisabled {
                        Button(model.localization.text("recovery.notificationsDisabled")) {
                            model.openNotificationSettings()
                        }
                    }
                } else if model.canArmRecoveryReminder(snapshot, now: now) {
                    Button {
                        Task { await model.armRecoveryReminder() }
                    } label: {
                        Label(model.localization.text("recovery.arm"), systemImage: "bell")
                    }
                    .disabled(model.isRefreshing || model.isUpdatingRecoveryReminder)
                }
                if model.recoveryReminderSaveFailed {
                    Text(model.localization.text("recovery.saveFailed"))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

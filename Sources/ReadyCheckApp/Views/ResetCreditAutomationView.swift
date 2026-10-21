import ReadyCheckCore
import SwiftUI

struct ResetCreditAutomationView: View {
    @Bindable var model: ReadyCheckAppModel
    @State private var confirm = false
    @State private var confirmationAccount: String?
    @State private var confirmationEmail = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(model.localization.text("resetAuto.title"), isOn: Binding(
                get: { model.resetCreditStatus.enabled },
                set: { enabled in
                    if enabled {
                        confirmationAccount = model.resetCreditAuthorizationAccount
                        confirmationEmail = model.codexOAuthLoginEmail ?? "Codex"
                        confirm = true
                    }
                    else { Task { await model.setResetCreditAutomationEnabled(false) } }
                }))
                .toggleStyle(.switch)
                .disabled(model.isUpdatingResetCreditAutomation || (!model.resetCreditStatus.enabled && (model.resetCreditStatus.status == .storageFailed || !model.canEnableResetCredits)))
            Text(model.localization.text("resetAuto.help")).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(model.localization.text("resetAuto." + model.resetCreditStatus.status.rawValue))
                .font(.caption).foregroundStyle(model.resetCreditStatus.status == .pending || model.resetCreditStatus.status == .storageFailed || model.resetCreditSaveFailed ? .orange : .secondary)
            if let date = model.resetCreditStatus.updatedAt {
                HStack {
                    Text(model.localization.text("resetAuto.lastAttempt"))
                    Text(date, format: Date.FormatStyle(date: .abbreviated, time: .shortened)
                        .locale(Locale(identifier: model.language.rawValue)))
                }.font(.caption2).foregroundStyle(.secondary)
            }
            if model.resetCreditSaveFailed {
                Text(model.localization.text("resetAuto.storageFailed")).font(.caption).foregroundStyle(.orange)
            }
        }
        .alert(model.localization.text("resetAuto.confirmTitle"), isPresented: $confirm) {
            Button(model.localization.text("resetAuto.enable"), role: .destructive) {
                Task { await model.setResetCreditAutomationEnabled(true, confirmedAccount: confirmationAccount) }
            }
            Button(model.localization.text("resetAuto.cancel"), role: .cancel) {}
        } message: {
            Text(confirmationEmail + "\n\n" + model.localization.text("resetAuto.confirm"))
        }
    }
}

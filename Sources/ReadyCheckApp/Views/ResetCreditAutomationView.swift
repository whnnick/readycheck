import ReadyCheckCore
import SwiftUI

struct ResetCreditAutomationView: View {
    @Bindable var model: ReadyCheckAppModel
    @State private var confirm = false
    @State private var confirmationAccount: String?
    @State private var confirmationEmail = ""
    var authorizationIsUnknown: Bool {
        model.resetCreditStatus.status == .storageFailed || model.codexOAuthStatus == .credentialStorageFailed
            || (model.resetCreditStatus.enabled && !model.canEnableResetCredits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if authorizationIsUnknown {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.localization.text("resetAuto.title"))
                    Spacer(minLength: 12)
                    Label(model.localization.text("resetAuto.authorizationUnknown"), systemImage: "questionmark.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Text(model.localization.text("resetAuto.title")).font(.subheadline.weight(.medium))
                    Spacer(minLength: 12)
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
                        .labelsHidden().toggleStyle(.switch).controlSize(.small)
                        .disabled(model.isUpdatingResetCreditAutomation || (!model.resetCreditStatus.enabled && (model.resetCreditStatus.status == .storageFailed || !model.canEnableResetCredits)))
                }
            }
            Text(model.localization.text(authorizationIsUnknown ? "resetAuto.authorizationUnknownHelp"
                : model.resetCreditStatus.enabled ? "resetAuto.onSummary" : "resetAuto.offSummary"))
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text(model.localization.text("resetAuto.availabilityLimit"))
                .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            DisclosureGroup(model.localization.text("resetAuto.rules")) {
                Text(model.localization.text("resetAuto.help")).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 4)
            }.font(.caption)
            Text(model.localization.text(authorizationIsUnknown && model.resetCreditStatus.status != .storageFailed
                ? "resetAuto.authorizationUnknownHelp" : "resetAuto." + model.resetCreditStatus.status.rawValue))
                .font(.caption).foregroundStyle(model.resetCreditStatus.status == .pending || model.resetCreditStatus.status == .storageFailed || model.resetCreditSaveFailed ? .orange : .secondary)
            if let date = model.resetCreditStatus.updatedAt {
                HStack {
                    Text(model.localization.text("resetAuto.lastAttempt"))
                    Text(date.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue))
                        .year().month().day().hour().minute()))
                }.font(.caption2).foregroundStyle(.secondary)
            }
            if model.resetCreditSaveFailed {
                Text(model.localization.text("resetAuto.storageFailed")).font(.caption).foregroundStyle(.orange)
            }
            if let check = model.resetCreditChecks.first {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.localization.text("resetCheck.lastCheck"))
                    Text(check.lastAt.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue)).year().month().day().hour().minute()))
                }.font(.caption2).foregroundStyle(.secondary)
                if check.reason != .checked {
                    Text(model.localization.text("resetCheck." + check.reason.rawValue)).font(.caption).foregroundStyle(.orange)
                }
            }
            ResetCreditHistoryView(model: model)
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

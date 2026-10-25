import ReadyCheckCore
import SwiftUI

struct ResetCreditHistoryView: View {
    @Bindable var model: ReadyCheckAppModel
    var body: some View {
        DisclosureGroup(model.localization.text("card.history")) {
            VStack(alignment: .leading, spacing: 12) {
                if model.resetCreditHistoryUnavailable || model.resetCreditChecksUnavailable {
                    Text(model.localization.text("card.recordUnavailable")).font(.caption).foregroundStyle(.orange)
                }
                if model.currentResetCreditRecords.isEmpty && !model.resetCreditHistoryUnavailable {
                    Text(model.localization.text("card.noAttempts")).font(.caption).foregroundStyle(.secondary)
                }
                ForEach(model.currentResetCreditRecords) { record in
                    Button { model.resetCreditDetailSelection = .record(record.id) } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.expiresAt.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue)).year().month().day().hour().minute()))
                                Text(model.localization.text(record.isHistoricalReminder ? "card.historyIncomplete" : "resetAuto." + record.status.rawValue)).font(.caption).foregroundStyle(.secondary)
                                if record.reminderOnly { Text(model.localization.text("card.reminderOnly")).font(.caption2).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Text(model.localization.text("next.detailAction")).font(.caption)
                        }.padding(.vertical, 6)
                    }.buttonStyle(.plain)
                }
                if !model.resetCreditChecks.isEmpty {
                    Divider()
                    Text(model.localization.text("resetCheck.history")).font(.caption.weight(.semibold))
                    ForEach(model.resetCreditChecks.prefix(12)) { check in
                        let recovered = check.recovered(in: model.resetCreditChecks)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(model.localization.text(recovered ? "resetCheck.serviceHistory" : "resetCheck." + check.reason.rawValue))
                                .foregroundStyle(check.reason == .checked || recovered ? Color.secondary : .orange)
                            HStack {
                                Text(check.firstAt.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue)).year().month().day().hour().minute()))
                                if check.count > 1 {
                                    Text("–")
                                    Text(check.lastAt.formatted(Calendar.current.isDate(check.firstAt, inSameDayAs: check.lastAt)
                                        ? .dateTime.locale(Locale(identifier: model.language.rawValue)).hour().minute()
                                        : .dateTime.locale(Locale(identifier: model.language.rawValue)).year().month().day().hour().minute()))
                                    Text(String(format: model.localization.text("resetCheck.count"), check.count))
                                }
                            }.foregroundStyle(.secondary)
                            if check.warningSubmitted { Text(model.localization.text("resetCheck.warningSubmitted")).foregroundStyle(.secondary) }
                            if recovered {
                                Text(model.localization.text("resetCheck.recovered")).foregroundStyle(.secondary)
                            }
                        }.font(.caption).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }.padding(.top, 8)
        }.font(.subheadline)
    }
}

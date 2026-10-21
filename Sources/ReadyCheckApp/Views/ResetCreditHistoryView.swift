import ReadyCheckCore
import SwiftUI

struct ResetCreditHistoryView: View {
    @Bindable var model: ReadyCheckAppModel
    var body: some View {
        DisclosureGroup(model.localization.text("card.history")) {
            if model.resetCreditHistoryUnavailable {
                Text(model.localization.text("card.recordUnavailable")).font(.caption).foregroundStyle(.orange)
            }
            ForEach(model.currentResetCreditRecords) { record in
                Button { model.resetCreditDetailSelection = .record(record.id) } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.expiresAt, format: .dateTime.locale(Locale(identifier: model.language.rawValue)).month().day().hour().minute())
                            Text(model.localization.text("resetAuto." + record.status.rawValue)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(model.localization.text("next.detailAction")).font(.caption)
                    }.padding(.vertical, 6)
                }.buttonStyle(.plain)
            }
        }.font(.subheadline)
    }
}

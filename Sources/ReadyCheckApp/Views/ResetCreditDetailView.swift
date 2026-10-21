import ReadyCheckCore
import SwiftUI

enum ResetCreditDetailSelection: Hashable, Identifiable {
    case available(Date), record(String)
    var id: String { switch self { case .available(let date): "available-\(date.timeIntervalSince1970)"; case .record(let id): "record-\(id)" } }
}

struct ResetCreditDetailView: View {
    @Bindable var model: ReadyCheckAppModel
    let selection: ResetCreditDetailSelection
    let now: Date
    @Environment(\.dismiss) private var dismiss
    @State private var showNotices = false
    private var record: ResetCreditExecutionRecord? {
        if case .record(let id) = selection { return model.currentResetCreditRecords.first { $0.id == id } }
        return nil
    }
    private var expiry: Date? { if case .available(let date) = selection { return date }; return record?.expiresAt }
    private var notice: QuotaReminderHistoryRecord? {
        guard let record else { return nil }
        return model.reminderHistoryRecords.first { $0.id == "reset-used:\(record.id)" && $0.kind == .resetCreditUsed }
    }
    private var canShowWindow: Bool {
        guard case .available(let date) = selection,
              let snapshot = model.snapshots.first(where: { $0.providerId == "codex-oauth" }),
              !snapshot.isStale(now: now), snapshot.status == .available,
              snapshot.details?.hasCurrentManualResetDetails(now: now) == true, snapshot.details?.manualResetCount != 0,
              snapshot.details?.manualResetExpirations.contains(date) == true, date > now else { return false }
        return true
    }
    private var resultText: String {
        if let record { return model.localization.text("resetAuto." + record.status.rawValue) }
        if case .record = selection { return model.localization.text("card.recordUnavailable") }
        if model.resetCreditStatus.status == .storageFailed { return model.localization.text("resetAuto.storageFailed") }
        guard canShowWindow else { return model.localization.text("next.conditionsUnknown.detail") }
        return model.localization.text(model.resetCreditStatus.enabled ? "card.waiting" : "resetAuto.off")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(model.localization.text("card.title")).font(.title3.weight(.semibold))
                Spacer()
                Button(model.localization.text("notification.history.close")) { dismiss() }.keyboardShortcut(.cancelAction)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section("card.facts") {
                        if let expiry {
                            Text(model.localization.text("card.expiry") + " (GMT+8)").font(.caption).foregroundStyle(.secondary)
                            Text(dateText(expiry)).font(.subheadline.weight(.semibold)).monospacedDigit()
                        }
                        if record == nil, let readAt = model.snapshots.first(where: { $0.providerId == "codex-oauth" })?.details?.manualResetDetailsReadAt {
                            Text(model.localization.text("card.readAt") + " " + dateText(readAt)).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(model.localization.text(model.resetCreditStatus.status == .storageFailed ? "card.authorizationUnknown" : model.resetCreditStatus.enabled ? "card.authorized" : "resetAuto.off")).font(.caption)
                        if record != nil { Text(model.localization.text("card.historical")).font(.caption).foregroundStyle(.secondary) }
                    }
                    section("card.result") {
                        Text(resultText).foregroundStyle(record?.confirmedUsed == true ? Color.green : Color.primary)
                        if record == nil, let expiry, canShowWindow, model.resetCreditStatus.enabled {
                            Text(model.localization.text("card.conditional") + " · " + dateText(expiry.addingTimeInterval(-3600)))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let record {
                            Text(model.localization.text("card.updated") + " " + dateText(record.updatedAt)).font(.caption).foregroundStyle(.secondary)
                            Text(model.localization.text("card.unrecorded")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    section("card.notification") {
                        Text(model.localization.text("card.notice." + (record?.notificationState(history: model.reminderHistoryRecords).rawValue ?? "notApplicable")))
                        Text(model.localization.text("card.notificationHelp")).font(.caption).foregroundStyle(.secondary)
                        if let notice { Button(model.localization.text("card.showNotice")) { showNotices = true }.disabled(notice.kind != .resetCreditUsed) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            Button(model.localization.text("next.rulesAction")) {
                model.mainWindowPage = .settings; model.mainSettingsSection = .reminders; dismiss()
            }
        }
        .padding(20).frame(width: 540, height: 530)
        .sheet(isPresented: $showNotices) {
            ReminderHistoryListView(records: notice.map { [$0] } ?? [], localization: model.localization)
        }
    }
    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: model.language.rawValue)
        formatter.timeZone = TimeZone(secondsFromGMT: 28800); formatter.dateStyle = .medium; formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.localization.text(title)).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            content()
            Divider().padding(.top, 6)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

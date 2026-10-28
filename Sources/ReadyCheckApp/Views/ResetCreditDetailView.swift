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
    private var isHistoricalReminder: Bool { record?.isHistoricalReminder == true }
    private var notice: QuotaReminderHistoryRecord? {
        guard let record else { return nil }
        return CardEvidenceTimeline.notice(record: record, history: model.reminderHistoryRecords)
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
        if let record { return model.localization.text(record.isHistoricalReminder ? "card.historyIncomplete" : "resetAuto." + record.status.rawValue) }
        if case .record = selection { return model.localization.text("card.recordUnavailable") }
        if model.resetCreditStatus.status == .storageFailed { return model.localization.text("resetAuto.storageFailed") }
        guard canShowWindow else { return model.localization.text("card.conditionsUnknown") }
        return model.localization.text(model.resetCreditStatus.enabled ? "card.waiting" : "resetAuto.off")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(model.localization.text(isHistoricalReminder ? "card.legacyTitle" : "card.title")).font(.title3.weight(.semibold))
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
                        if !isHistoricalReminder {
                            Text(model.localization.text(model.resetCreditStatus.status == .storageFailed ? "card.authorizationUnknown" : model.resetCreditStatus.enabled ? "card.authorized" : "resetAuto.off")).font(.caption)
                        }
                        if let record {
                            Text(model.localization.text(record.reminderOnly ? "card.reminderOnly" : record.observedOnly ? "card.observedOnly" : "card.historical")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    section("card.result") {
                        if record == nil || isHistoricalReminder {
                            Text(resultText)
                        }
                        if record == nil, let expiry, canShowWindow, model.resetCreditStatus.enabled {
                            Text(model.localization.text("card.conditional") + " · " + dateText(expiry.addingTimeInterval(-3600)))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let record {
                            if record.isHistoricalReminder {
                                Text(model.localization.text("card.legacyOutcome")).font(.caption).foregroundStyle(.secondary)
                            } else {
                                CardEvidenceTimelineView(record: record, history: model.reminderHistoryRecords, localization: model.localization)
                                if record.startedAt == nil || record.requestCount == nil {
                                    Text(model.localization.text(record.observedOnly ? "card.noLocalRequest" : "card.unrecorded")).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    section("card.notification", showsDivider: false) {
                        Text(model.localization.text(isHistoricalReminder ? "card.legacyNotice" : "card.notice." + (record?.notificationState(history: model.reminderHistoryRecords).rawValue ?? "notApplicable")))
                        Text(model.localization.text(isHistoricalReminder ? "card.legacyReadOnly" : "card.notificationHelp")).font(.caption).foregroundStyle(.secondary)
                        if let notice { Button(model.localization.text("card.showNotice")) { showNotices = true }.disabled(notice.kind != .resetCreditUsed) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20).frame(width: 540, height: 400)
        .sheet(isPresented: $showNotices) {
            ReminderHistoryListView(records: notice.map { [$0] } ?? [], localization: model.localization)
        }
    }
    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: model.language.rawValue)
        formatter.timeZone = TimeZone(secondsFromGMT: 28800); formatter.dateStyle = .medium; formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    private func section<Content: View>(_ title: String, showsDivider: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.localization.text(title)).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            content()
            if showsDivider { Divider().padding(.top, 6) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

import Foundation
import ReadyCheckCore
import SwiftUI

/// Read-only evidence from the account-scoped card projection, not a new event ledger.
enum CardEvidenceTimeline {
    enum Kind: Int { case prepared, observation, result, noticeAttempt, noticeVerified }
    struct Event: Identifiable {
        let kind: Kind
        let date: Date
        var id: Kind { kind }
        var titleKey: String {
            switch kind {
            case .prepared: "card.timeline.prepared"
            case .observation: "card.timeline.observation"
            case .result: "card.timeline.result"
            case .noticeAttempt: "card.timeline.noticeAttempt"
            case .noticeVerified: "card.timeline.noticeVerified"
            }
        }
    }

    static func notice(record: ResetCreditExecutionRecord, history: [QuotaReminderHistoryRecord]) -> QuotaReminderHistoryRecord? {
        guard record.confirmedUsed, !record.observedOnly, !record.reminderOnly else { return nil }
        return history.first {
            $0.id == "reset-used:\(record.id)" && $0.kind == .resetCreditUsed && $0.expiresAt == record.expiresAt
        }
    }

    static func events(record: ResetCreditExecutionRecord, history: [QuotaReminderHistoryRecord]) -> [Event] {
        guard !record.reminderOnly else { return [] }
        var events: [Event] = []
        if !record.observedOnly, let date = record.startedAt {
            events.append(Event(kind: .prepared, date: date))
        }
        events.append(Event(kind: record.observedOnly ? .observation : .result, date: record.updatedAt))
        if let notice = notice(record: record, history: history) {
            if let date = notice.lastAttemptAt { events.append(Event(kind: .noticeAttempt, date: date)) }
            if notice.status == .delivered, let date = notice.deliveredAt {
                events.append(Event(kind: .noticeVerified, date: date))
            }
        }
        return events.sorted { $0.date == $1.date ? $0.kind.rawValue < $1.kind.rawValue : $0.date < $1.date }
    }
}

struct CardEvidenceTimelineView: View {
    let record: ResetCreditExecutionRecord
    let history: [QuotaReminderHistoryRecord]
    let localization: LocalizationService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.text("card.timeline.title")).font(.caption.weight(.semibold))
            ForEach(CardEvidenceTimeline.events(record: record, history: history)) { event in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill").font(.system(size: 6))
                        .foregroundStyle(.secondary).frame(width: 12, height: 16)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localization.text(event.titleKey)).font(.caption.weight(.medium))
                        Text(dateText(event.date)).font(.caption).foregroundStyle(.secondary)
                        if event.kind == .prepared {
                            Text(localization.text("card.timeline.preparedHelp"))
                                .font(.caption).foregroundStyle(.secondary)
                            if let count = record.requestCount {
                                Text(String(format: localization.text("card.timeline.attemptCount"), count))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } else if event.kind == .result || event.kind == .observation {
                            Text(localization.text("resetAuto." + record.status.rawValue))
                                .font(.caption).foregroundStyle(record.confirmedUsed ? Color.green : .secondary)
                        } else if event.kind == .noticeAttempt,
                                  let notice = CardEvidenceTimeline.notice(record: record, history: history) {
                            Text(localization.text(NotificationHistoryPresentation.statusKey(notice)))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            Text(localization.text("card.timeline.scope"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.language.rawValue)
        formatter.timeZone = TimeZone(secondsFromGMT: 28800)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date) + " (GMT+8)"
    }
}

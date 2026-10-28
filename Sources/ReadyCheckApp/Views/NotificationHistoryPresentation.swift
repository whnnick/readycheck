import Foundation
import ReadyCheckCore

enum NotificationHistoryFilter: String, CaseIterable, Identifiable {
    case all, quotaLow, quotaRecovered, manualResetExpiring, cardsUsed, creditsStarted
    var id: Self { self }
    var labelKey: String { "notification.history.filter." + rawValue }

    func select(_ records: [QuotaReminderHistoryRecord]) -> [QuotaReminderHistoryRecord] {
        records.filter { record in
            switch self {
            case .all: true
            case .quotaLow: record.kind == .quotaLow
            case .quotaRecovered: record.kind == .quotaRecovered
            case .manualResetExpiring: record.kind == .manualResetExpiring
            case .cardsUsed: record.kind == .resetCreditUsed
            case .creditsStarted: record.kind == .creditsStarted
            }
        }
    }
}

enum NotificationHistoryPresentation {
    struct DayGroup: Identifiable {
        let day: Date?
        let records: [QuotaReminderHistoryRecord]
        var id: Date? { day }
    }

    static func timestamp(_ record: QuotaReminderHistoryRecord) -> Date? {
        record.lastAttemptAt ?? record.deliveredAt
    }

    static func statusKey(_ record: QuotaReminderHistoryRecord) -> String {
        if record.submissionAccepted == true && record.status != .delivered {
            return "notification.history.submitted"
        }
        switch record.status {
        case .delivered: return "notification.history.delivered"
        case .failed: return "notification.history.failed"
        case .automaticallyWithdrawn: return "notification.history.withdrawn"
        case .withdrawalPending: return "notification.history.withdrawalPending"
        case .legacyUnknown: return "notification.history.legacyUnknown"
        }
    }

    static func groups(_ records: [QuotaReminderHistoryRecord], calendar: Calendar = .current) -> [DayGroup] {
        let grouped = Dictionary(grouping: records) { record in
            timestamp(record).map { calendar.startOfDay(for: $0) }
        }
        return grouped.map { day, records in
            DayGroup(day: day, records: records.sorted { lhs, rhs in
                let a = timestamp(lhs), b = timestamp(rhs)
                if a == b { return lhs.id < rhs.id }
                return (a ?? .distantPast) > (b ?? .distantPast)
            })
        }.sorted { ($0.day ?? .distantPast) > ($1.day ?? .distantPast) }
    }
}

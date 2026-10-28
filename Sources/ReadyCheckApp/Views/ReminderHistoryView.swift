import ReadyCheckCore
import SwiftUI

struct ReminderHistoryPageView: View {
    let records: [QuotaReminderHistoryRecord]
    let localization: LocalizationService
    @State private var filter: NotificationHistoryFilter = .all

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(localization.text("notification.history.local"), systemImage: "internaldrive")
                .font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Text(localization.text("notification.history.subtitle"))
                .font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Text(localization.text("notification.history.disclaimer"))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Picker(localization.text("notification.history.filterLabel"), selection: $filter) {
                ForEach(NotificationHistoryFilter.allCases) { option in
                    Text(localization.text(option.labelKey)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
            Divider()
            if records.isEmpty {
                ReminderHistoryEmptyView(localization: localization).padding(.vertical, 16)
            } else if filter.select(records).isEmpty {
                Text(localization.text("notification.history.noMatches"))
                    .foregroundStyle(.secondary).padding(.vertical, 16)
            } else {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(NotificationHistoryPresentation.groups(filter.select(records))) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.day.map { dayText($0) } ?? localization.text("notification.history.unknownDate"))
                                .font(.headline)
                            ReminderHistoryRowsView(records: group.records, localization: localization)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.language.rawValue)
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

private struct ReminderHistoryRowsView: View {
    let records: [QuotaReminderHistoryRecord]
    let localization: LocalizationService

    var body: some View {
        if records.isEmpty {
            ReminderHistoryEmptyView(localization: localization).padding(.vertical, 16)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    ReminderHistoryRow(record: record, localization: localization)
                    if index < records.count - 1 { Divider().padding(.leading, 34) }
                }
            }
        }
    }
}

struct ReminderHistoryListView: View {
    let records: [QuotaReminderHistoryRecord]
    let localization: LocalizationService

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(localization.text("notification.history.title"), systemImage: "bell.badge")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(localization.text("notification.history.close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            Text(localization.text("notification.history.disclaimer"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            if records.isEmpty {
                ReminderHistoryEmptyView(localization: localization)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    ReminderHistoryRowsView(records: records, localization: localization)
                }
            }
        }
        .padding(20)
        .frame(width: 620, height: 500)
    }
}

private struct ReminderHistoryRow: View {
    let record: QuotaReminderHistoryRecord
    let localization: LocalizationService

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .frame(width: 24, height: 24)
                .background(statusColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if record.status == .legacyUnknown && record.submissionAccepted != true {
                    Text(localization.text("notification.history.legacyExplanation"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let timestamp = NotificationHistoryPresentation.timestamp(record) {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            Text(relativeText(timestamp, now: context.date))
                        }
                        Text(Self.dateFormatter(language: localization.language).string(from: timestamp))
                    } else {
                        Text(localization.text("notification.history.unknownDate"))
                    }
                    if record.attemptCount > 1 {
                        Text(String(format: localization.text("notification.history.attempts"), record.attemptCount))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(statusText)
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.11), in: Capsule())
        }
        .padding(.vertical, 9)
    }

    private var title: String {
        switch record.kind {
        case .resetCreditUsed:
            return localization.text("notification.resetUsed.title")
        case .quotaLow:
            return localization.text("notification.lowQuota.title")
        case .manualResetExpiring:
            guard let resetIndex = record.resetIndex else {
                return String(
                    format: localization.text("notification.history.legacyResetTitle"),
                    record.leadHours ?? 0
                )
            }
            return String(
                format: localization.text("notification.history.resetTitle"),
                resetIndex,
                record.leadHours ?? 0
            )
        case .quotaRecovered:
            return localization.text("notification.recovered.title")
        case .creditsStarted:
            return localization.text("notification.history.creditsTitle")
        }
    }

    private func relativeText(_ timestamp: Date, now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: localization.language.rawValue)
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: timestamp, relativeTo: now)
    }

    private var detail: String? {
        if record.kind == .quotaLow, let remaining = record.remainingPercent {
            return String(format: localization.text("notification.lowQuota.body"), record.quotaDisplayLabel ?? localization.text(record.quotaLabelKey ?? "quota.window"), remaining)
        }
        guard let expiresAt = record.expiresAt else { return nil }
        return String(
            format: localization.text("notification.history.expires"),
            Self.dateFormatter(language: localization.language).string(from: expiresAt)
        )
    }

    private var statusText: String {
        localization.text(NotificationHistoryPresentation.statusKey(record))
    }

    private var statusColor: Color {
        switch record.status {
        case .delivered: .green
        case .failed: .red
        case .automaticallyWithdrawn: .blue
        case .withdrawalPending: .orange
        case .legacyUnknown: .secondary
        }
    }

    private var statusIcon: String {
        if record.submissionAccepted == true && record.status != .delivered { return "paperplane" }
        return switch record.status {
        case .delivered: "checkmark"
        case .failed: "exclamationmark"
        case .automaticallyWithdrawn: "bell.slash.fill"
        case .withdrawalPending: "arrow.clockwise"
        case .legacyUnknown: "questionmark"
        }
    }

    private static func dateFormatter(language: AppLanguage) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

private struct ReminderHistoryEmptyView: View {
    let localization: LocalizationService

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.text("notification.history.emptyTitle"))
                    .font(.subheadline.weight(.semibold))
                Text(localization.text("notification.history.emptyMessage"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}

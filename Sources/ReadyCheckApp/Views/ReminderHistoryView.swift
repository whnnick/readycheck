import ReadyCheckCore
import SwiftUI

struct ReminderHistorySummaryView: View {
    let records: [QuotaReminderHistoryRecord]
    let localization: LocalizationService
    let showAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(localization.text("notification.history.title"), systemImage: "bell.badge")
                    .font(.headline)

                Text(localization.text("notification.history.local"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.07), in: Capsule())

                Spacer()

                if records.count > 3 {
                    Button(localization.text("notification.history.viewAll"), action: showAll)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            Text(localization.text("notification.history.subtitle"))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(localization.text("notification.history.disclaimer"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            if records.isEmpty {
                ReminderHistoryEmptyView(localization: localization)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.prefix(3)).indices, id: \.self) { index in
                        ReminderHistoryRow(record: records[index], localization: localization)
                        if index < min(records.count, 3) - 1 {
                            Divider().padding(.leading, 34)
                        }
                    }
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
                    LazyVStack(spacing: 0) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            ReminderHistoryRow(record: record, localization: localization)
                            if index < records.count - 1 {
                                Divider().padding(.leading, 34)
                            }
                        }
                    }
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

                HStack(spacing: 6) {
                    if let timestamp = record.lastAttemptAt {
                        Text(Self.dateFormatter(language: localization.language).string(from: timestamp))
                    }
                    if record.attemptCount > 1 {
                        Text("·")
                        Text(String(format: localization.text("notification.history.attempts"), record.attemptCount))
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 12)

            Text(statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.11), in: Capsule())
        }
        .padding(.vertical, 9)
    }

    private var title: String {
        switch record.kind {
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
        case .creditsStarted:
            return localization.text("notification.history.creditsTitle")
        }
    }

    private var detail: String? {
        guard let expiresAt = record.expiresAt else { return nil }
        return String(
            format: localization.text("notification.history.expires"),
            Self.dateFormatter(language: localization.language).string(from: expiresAt)
        )
    }

    private var statusText: String {
        switch record.status {
        case .delivered:
            localization.text("notification.history.delivered")
        case .failed:
            localization.text("notification.history.failed")
        case .legacyUnknown:
            localization.text("notification.history.legacyUnknown")
        }
    }

    private var statusColor: Color {
        switch record.status {
        case .delivered: .green
        case .failed: .red
        case .legacyUnknown: .secondary
        }
    }

    private var statusIcon: String {
        switch record.status {
        case .delivered: "checkmark"
        case .failed: "exclamationmark"
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

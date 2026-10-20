import ReadyCheckCore
import SwiftUI

struct QuotaPaceView: View {
    let pace: QuotaPace
    let localization: LocalizationService
    let now: Date
    var compact = false

    var body: some View {
        Group {
            if compact {
                Text(compactSummary)
                    .font(.caption2).lineLimit(2)
                    .foregroundStyle(pace.state == .risk ? Color.orange : Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 2)
                    .accessibilityLabel(localization.text("pace.title") + " " + headline + " " + (comparison ?? "")
                        + (pace.reminderEnabled ? "" : " " + localization.text("pace.off")))

            } else {
                expandedContent
            }
        }.help(localization.text("pace.help"))
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(localization.text("pace.title"), systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(headline)
                .font(.headline)
                .foregroundStyle(pace.state == .risk ? Color.orange : Color.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let comparison {
                Text(comparison).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !pace.reminderEnabled {
                Text(localization.text("pace.off")).font(.caption2).foregroundStyle(.secondary)
            }
            if let rate = pace.ratePointsPerHour {
                Text(String(format: localization.text("pace.rate"), duration(pace.observedDuration), rate))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(localization.text("pace.assumption")).font(.caption).foregroundStyle(.secondary)
            DisclosureGroup(localization.text("pace.basis")) {
                Text(localization.text("pace.help")).font(.caption)
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }.font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
        .help(localization.text("pace.help"))
    }

    private var compactSummary: String {
        let text: String
        if pace.state == .safe, let remaining = pace.remainingAtReset {
            text = String(format: localization.text("pace.compactSafe"), Int((remaining * 100).rounded()))
        } else if let seconds = pace.secondsToThreshold, let reset = pace.resetAt {
            text = String(format: localization.text("pace.compactCompare"), duration(seconds), pace.thresholdPercent,
                duration(reset.timeIntervalSince(now)))
        } else {
            text = localization.text("pace.compactTitle") + ": " + headline
        }
        return text + (pace.reminderEnabled ? "" : " · " + localization.text("pace.referenceOnly"))
    }

    var headline: String {
        let key = "pace." + pace.state.rawValue
        if pace.state == .risk || pace.state == .atThreshold {
            return String(format: localization.text(key), pace.thresholdPercent)
        }
        return localization.text(key)
    }

    var comparison: String? {
        guard let reset = pace.resetAt, let seconds = pace.secondsToThreshold else { return nil }
        if pace.state == .safe, let remaining = pace.remainingAtReset {
            return String(format: localization.text("pace.safeCompare"), duration(reset.timeIntervalSince(now)), Int((remaining * 100).rounded()))
        }
        return String(format: localization.text("pace.compare"), duration(seconds), pace.thresholdPercent, duration(reset.timeIntervalSince(now)))
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: localization.language.rawValue)
        formatter.calendar = calendar
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: max(300, (seconds / 300).rounded() * 300)) ?? "—"
    }
}

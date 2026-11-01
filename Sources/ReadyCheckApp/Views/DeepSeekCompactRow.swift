import SwiftUI
import ReadyCheckCore

enum DeepSeekHistoryWindow {
    static func range(now: Date, lastObservedAt: Date?, days: Int) -> ClosedRange<Date> {
        let end = max(now, lastObservedAt ?? now)
        return end.addingTimeInterval(-Double(days) * 86400)...end
    }

    static func ticks(in range: ClosedRange<Date>) -> [Date] {
        let span = range.upperBound.timeIntervalSince(range.lowerBound)
        return (0...4).map { range.lowerBound.addingTimeInterval(span * Double($0) / 4) }
    }
}

enum DeepSeekReadingStatus {
    static func isStale(observedAt: Date?, hasError: Bool, now: Date) -> Bool {
        hasError || (observedAt.map { now.timeIntervalSince($0) > 300 } ?? true)
    }
}

@MainActor
enum DeepSeekDisplay {
    static func balanceText(connection: DeepSeekConnection, now: Date) -> String {
        guard !DeepSeekReadingStatus.isStale(observedAt: connection.observedAt,
            hasError: connection.error != nil || connection.credentialError, now: now),
              let balance = connection.snapshot?.balances.first else { return "—" }
        return balance.currency + " " + balance.total.formatted(.number.precision(.fractionLength(2...4)))
    }
}

struct DeepSeekBalancePanel: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    let now: Date
    var open: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeepSeekCompactRow(connection: connection, language: language, now: now, open: open)
            DeepSeekRefreshFeedback(connection: connection, language: language)
            if connection.snapshot != nil {
                Divider()
                Text(language == .zhCN ? "最近一小时 · 每 5 分钟" : "Last hour · five-minute bins")
                    .font(.caption).foregroundStyle(.secondary)
                DeepSeekConsumptionView(connection: connection, language: language,
                    range: now.addingTimeInterval(-3600)...now, interval: 300, height: 60)
                Text(language == .zhCN ? "本机余额减少，非官方费用。" : "Local balance decrease, not billed cost.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct DeepSeekCompactRow: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    let now: Date
    let open: () -> Void
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }

    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("DeepSeek").font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                }
                if let snapshot = connection.snapshot {
                    ForEach(snapshot.balances, id: \.currency) { balance in
                        HStack {
                            Text(text("总余额", "Total balance") + " · " + balance.currency)
                            Spacer()
                            Text(balance.total.formatted(.number.precision(.fractionLength(2...8)))).monospacedDigit()
                        }.font(.callout)
                        Text(text("赠送余额 ", "Granted ") + balance.granted.formatted(.number.precision(.fractionLength(2...8))) + " · " + text("充值余额 ", "Topped up ") + balance.toppedUp.formatted(.number.precision(.fractionLength(2...8))) + " " + balance.currency)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if DeepSeekReadingStatus.isStale(observedAt: connection.observedAt, hasError: connection.error != nil || connection.credentialError, now: now) {
                        Label(text("上次读取，可能已过期", "Last reading may be stale"), systemImage: "clock.badge.exclamationmark")
                            .font(.caption).foregroundStyle(.orange)
                    }
                } else {
                    Text(connection.isBusy ? text("正在读取余额…", "Reading balance…") : text("暂无余额，请打开查看", "No balance available; open to inspect"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("DeepSeek · " + text("余额详情", "balance details"))
    }
}

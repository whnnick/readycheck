import SwiftUI
import ReadyCheckCore

struct DeepSeekAlertControls: View {
    @Bindable var model: ReadyCheckAppModel
    @State private var inputs: [String: String] = [:]
    @State private var invalidCurrency: String?
    private func text(_ zh: String, _ en: String) -> String { model.language == .zhCN ? zh : en }
    private var currencies: [String] {
        Array(Set((model.deepSeek.snapshot?.balances.map(\.currency) ?? []) + model.deepSeekAlertRules.map(\.currency))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text("DeepSeek 余额提醒", "DeepSeek balance alerts")).font(.headline)
            Text(text("余额低于或等于所设金额时提醒；按连接和币种分别设置。余额回升后可再次提醒。", "Alert when the balance is at or below your threshold. Each connection and currency has its own setting; the alert rearms after the balance rises."))
                .font(.footnote).foregroundStyle(.secondary)
            if currencies.isEmpty {
                Text(text("先成功读取余额，再设置对应币种的提醒。", "Read a balance before setting an alert for that currency."))
                    .font(.callout).foregroundStyle(.secondary)
            }
            ForEach(currencies, id: \.self) { currency in
                let rule = model.deepSeekAlertRules.first { $0.currency == currency }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(currency).frame(width: 42, alignment: .leading)
                        TextField(text("金额", "Amount"), text: Binding(get: { inputs[currency] ?? rule.map { NSDecimalNumber(decimal: $0.threshold).stringValue } ?? "" }, set: { inputs[currency] = $0 }))
                            .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                            .accessibilityLabel(currency + " " + text("余额提醒金额", "balance alert threshold"))
                        Button(text("保存并开启", "Save and enable")) { save(currency: currency) }
                        if let rule, rule.enabled {
                            Button(text("关闭", "Disable")) { Task { await model.configureDeepSeekAlert(currency: currency, threshold: rule.threshold, enabled: false) } }
                        }
                        Spacer()
                        Text(rule?.enabled == true ? text("已开启", "On") : text("未开启", "Off"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if invalidCurrency == currency {
                        Text(text("请输入非负数字，例如 10.50。", "Enter a nonnegative amount, for example 10.50."))
                            .font(.caption).foregroundStyle(.orange)
                    }
                    if let rule, let submitted = rule.lastSubmittedAt {
                        Text((rule.lastDeliveredAt == nil ? text("最近已提交系统，送达未确认：", "Last submitted, delivery unverified: ") : text("最近已确认送达：", "Last verified delivery: ")) + submitted.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if model.deepSeekAlertStorageError {
                Text(text("提醒设置暂时无法读写，请检查本机存储。", "Alert settings are unavailable. Check local storage."))
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .task(id: model.deepSeek.connectionID) { await model.loadDeepSeekAlertRules() }
    }

    private func save(currency: String) {
        let rule = model.deepSeekAlertRules.first { $0.currency == currency }
        let input = (inputs[currency] ?? rule.map { NSDecimalNumber(decimal: $0.threshold).stringValue } ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard input.range(of: #"^[0-9]+(\.[0-9]+)?$"#, options: .regularExpression) != nil,
              let amount = Decimal(string: input, locale: Locale(identifier: "en_US_POSIX")), !amount.isNaN, amount >= 0 else {
            invalidCurrency = currency
            return
        }
        invalidCurrency = nil
        Task { await model.configureDeepSeekAlert(currency: currency, threshold: amount, enabled: true) }
    }
}

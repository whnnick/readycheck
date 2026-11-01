import SwiftUI
import ReadyCheckCore

struct DeepSeekOverview: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    let now: Date
    @Binding var days: Int
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DeepSeek").font(.title2.weight(.semibold))
                    if let date = connection.observedAt {
                        Text(text("官方余额 · 更新于 ", "Official balance · Updated ") + date.formatted(date: .abbreviated, time: .standard))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            DeepSeekRefreshFeedback(connection: connection, language: language)
            if let error = connection.error {
                Label(errorText(error), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange).font(.callout)
            }
            if connection.credentialError {
                Label(text("无法访问钥匙串，请检查权限后重试。", "Cannot access Keychain. Check access and try again."), systemImage: "key")
                    .foregroundStyle(.orange).font(.callout)
            }
            if let snapshot = connection.snapshot {
                if DeepSeekReadingStatus.isStale(observedAt: connection.observedAt, hasError: connection.error != nil || connection.credentialError, now: now) {
                    Text(text("显示上次读取的余额，可能已过期。", "Showing the last reading, which may be stale."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                ForEach(snapshot.balances, id: \.currency) { balance in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(text("总余额", "Total balance") + " · " + balance.currency).font(.headline)
                        Text(balance.total.formatted(.number.precision(.fractionLength(2...8))))
                            .font(.system(size: 34, weight: .semibold, design: .rounded)).monospacedDigit()
                        HStack(alignment: .top, spacing: 24) {
                            balanceDetail(text("赠送余额", "Granted balance"), amount: balance.granted, currency: balance.currency)
                            balanceDetail(text("充值余额", "Topped-up balance"), amount: balance.toppedUp, currency: balance.currency)
                        }
                        .padding(.top, 4)
                    }
                }
                Text(snapshot.isAvailable ? text("API 余额：可用", "API balance: available") : text("API 余额：不足", "API balance: insufficient"))
                    .font(.caption).foregroundStyle(.secondary)
            } else if connection.isBusy {
                ProgressView(text("正在读取余额…", "Reading balance…"))
            } else {
                Text(text("尚无可显示的余额，请重试读取。", "No balance is available. Try refreshing."))
                    .foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Text(text("余额减少", "Balance decrease")).font(.headline)
                Spacer()
                Picker(text("时间范围", "Time range"), selection: $days) {
                    Text(text("24 小时", "24 hours")).tag(1)
                    Text(text("7 天", "7 days")).tag(7)
                    Text(text("30 天", "30 days")).tag(30)
                }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 220)
            }
            if connection.historyError {
                Label(text("本机余额记录暂时不可用。", "Local balance history is unavailable."), systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            } else if visibleHistory.isEmpty {
                Text(text("这个时间范围暂无余额记录。", "No readings in this period."))
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                DeepSeekConsumptionView(connection: connection, language: language, range: historyRange,
                    interval: days == 1 ? 3600 : days == 7 ? 21600 : 86400)
                DisclosureGroup(text("原始余额记录", "Original balance readings")) {
                    ForEach(Array(visibleHistory.suffix(8))) { point in
                        HStack {
                            Text(point.observedAt.formatted(date: .abbreviated, time: .standard))
                            Spacer()
                            Text(point.total.formatted(.number.precision(.fractionLength(2...8))) + " " + point.currency)
                                .monospacedDigit()
                        }.font(.caption).padding(.vertical, 3)
                    }
                }
            }
            Text(text("本机观测的余额减少，不是官方费用或 Token 账单。充值、退款或余额分项增加的区间不计入；超过 10 分钟的记录缺口留空，赠送余额到期也可能造成减少。", "Locally observed balance decreases, not official cost or Token billing. Intervals with increases or top-ups are excluded, gaps over 10 minutes stay blank, and granted-fund expiry can also reduce balance."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var historyRange: ClosedRange<Date> {
        DeepSeekHistoryWindow.range(now: now, lastObservedAt: connection.observedAt, days: days)
    }

    private func balanceDetail(_ title: String, amount: Decimal, currency: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            Text(amount.formatted(.number.precision(.fractionLength(2...8))) + " " + currency)
                .font(.headline).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var visibleHistory: [DeepSeekBalanceObservation] {
        connection.history.filter { historyRange.contains($0.observedAt) }
    }

    private func errorText(_ error: DeepSeekBalanceError) -> String {
        switch error {
        case .unauthorized: text("Key 无效或未获授权，请在连接设置中检查。", "Key rejected. Check it in connection settings.")
        case .rateLimited: text("请求过于频繁，请稍后重试。", "Rate limited. Try again later.")
        case .server: text("服务暂时不可用，请稍后重试。", "Service unavailable. Try again later.")
        case .network: text("网络读取失败，请检查网络后重试。", "Network request failed. Check your connection.")
        case .invalidResponse: text("余额数据无法识别，请稍后重试。", "The balance response could not be read.")
        }
    }
}

struct DeepSeekConnectionControls: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    @State private var editing = false
    @FocusState private var connectFocused: Bool
    @State private var confirmingDisconnect = false
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("DeepSeek API", systemImage: "key.horizontal").font(.headline)
            Text(text("通过 API Key 读取官方 API 账户的总余额、赠送与充值分项。网页版和 App 的聊天用量不在此接入范围。", "Uses an API key to read official API account balances, including granted and topped-up funds. Website and app chat usage is outside this connection's scope."))
                .font(.footnote).foregroundStyle(.secondary)
            Link(text("创建或管理 API Key", "Create or manage API key"), destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                .font(.callout)
            Text(text("Key 保存在本机钥匙串。应用运行时约每 5 分钟刷新，不发送模型请求。", "The key is stored in Keychain. Refreshes about every five minutes while the app runs; no model request is sent."))
                .font(.footnote).foregroundStyle(.secondary)
            HStack {
                Text(connection.credentialError ? text("需要系统授权", "System access required") : connection.isConnected ? text("已保存 API 连接", "API connection saved") : text("未连接", "Not connected"))
                Spacer()
                if connection.credentialError {
                    Button(text("重试读取凭据", "Retry credential access")) { Task { await connection.retryCredentialRead() } }
                }
                Button(connection.isConnected ? text("更换 Key", "Replace key") : text("连接 DeepSeek API", "Connect DeepSeek API")) { editing = true }.focusable().focused($connectFocused)
                if connection.isConnected {
                    Button(text("断开", "Disconnect")) { confirmingDisconnect = true }
                }
            }.disabled(connection.isBusy)
            if connection.credentialError {
                Text(text("已有凭据暂时无法访问，不代表账号已退出。请重试并在系统提示中允许访问。", "Saved credentials are temporarily inaccessible; this does not mean you signed out. Retry and allow access in the system prompt."))
                    .font(.caption).foregroundStyle(.orange)
            }
            if connection.error != nil && connection.isConnected {
                Button(text("重试刷新余额", "Retry balance refresh")) { Task { await connection.refresh() } }.disabled(connection.isBusy)
            }
        }
        .sheet(isPresented: $editing, onDismiss: { connectFocused = true }) { DeepSeekKeySheet(connection: connection, language: language) }
        .alert(text("断开 DeepSeek API？", "Disconnect DeepSeek API?"), isPresented: $confirmingDisconnect) {
            Button(text("取消", "Cancel"), role: .cancel) { }
            Button(text("断开", "Disconnect"), role: .destructive) { Task { await connection.disconnect() } }
        } message: {
            Text(text("只移除当前 DeepSeek API 连接；保留本机历史和提醒规则，不影响 Codex。", "Only the current DeepSeek API connection is removed. Local history and alert rules are kept; Codex is unaffected."))
        }
    }
}

struct DeepSeekKeySheet: View {
    let connection: DeepSeekConnection
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var submissionError: String?
    @FocusState private var keyFocused: Bool
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text("连接 DeepSeek API", "Connect DeepSeek API")).font(.headline)
            Text(text("用于监控 API 账户余额；网页版和 App 的聊天用量不在此接入范围。", "Monitors API account balances. Website and app chat usage is outside this connection's scope."))
                .font(.callout).foregroundStyle(.secondary)
            Text(text("在开放平台创建或使用已有 API Key，无需编程。验证余额读取成功后保存到本机钥匙串。", "Create or use an existing API key on the platform; no coding is needed. It is saved in Keychain after a successful balance read."))
                .font(.callout).foregroundStyle(.secondary)
            Link(text("创建或管理 API Key", "Create or manage API key"), destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                .font(.callout)
            SecureField("API Key", text: $key).textFieldStyle(.roundedBorder).focused($keyFocused)
                .onChange(of: key) { submissionError = nil }
            if let submissionError { Text(submissionError).foregroundStyle(.orange).font(.caption) }
            if connection.isBusy { ProgressView(text("正在验证余额读取…", "Verifying balance access…")).controlSize(.small) }
            HStack {
                Spacer()
                Button(text("取消", "Cancel")) { dismiss() }.keyboardShortcut(.cancelAction).disabled(connection.isBusy)
                Button(text("验证并连接", "Verify and connect")) {
                    submissionError = nil
                    Task {
                        await connection.connect(key: key)
                        if connection.credentialError {
                            submissionError = text("本次保存未完成，请检查钥匙串权限后重试。原有连接保留。", "Saving did not complete. Check Keychain access and retry. The previous connection is kept.")
                        } else if connection.connectError != nil {
                            submissionError = text("验证读取失败，请检查 Key 和网络后重试。原有连接保留。", "Verification failed. Check the key and network, then retry. The previous connection is kept.")
                        } else if connection.isConnected { key = ""; dismiss() }
                    }
                }.keyboardShortcut(.defaultAction).disabled(connection.isBusy || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(24).frame(width: 420)
        .task { keyFocused = true }
        .onDisappear { key = "" }
    }
}

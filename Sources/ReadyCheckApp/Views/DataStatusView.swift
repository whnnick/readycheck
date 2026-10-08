import ReadyCheckCore
import SwiftUI

struct DataStatusButton: View {
    @Bindable var model: ReadyCheckAppModel
    @State private var isPresented = false

    var body: some View {
        Button { isPresented = true } label: {
            Label(model.localization.text("dataStatus.title"), systemImage: "info.circle")
        }
        .popover(isPresented: $isPresented) {
            DataStatusView(model: model, close: { isPresented = false })
        }
    }
}

struct DataStatusView: View {
    @Bindable var model: ReadyCheckAppModel
    let close: () -> Void
    @State private var now = Date()

    private var snapshot: ProviderQuotaSnapshot? { model.snapshots.first { $0.providerId == "codex-oauth" } }
    private var localization: LocalizationService { model.localization }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.text("dataStatus.title")).font(.headline)
                Spacer()
                Button(action: close) { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
                    .help(localization.text("dataStatus.close"))
                    .keyboardShortcut(.cancelAction)
            }
            LabeledContent(localization.text("dataStatus.source"), value: sourceText)
            LabeledContent(localization.text("dataStatus.lastSuccess"), value: dateText(model.lastSuccessfulRefreshAt))
            LabeledContent(localization.text("dataStatus.lastAttempt"), value: dateText(model.lastRefreshAt))
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    let issues = QuotaDataDiagnostics.issueKeys(snapshot: snapshot, now: now)
                    if let snapshot, snapshot.status == .available, !snapshot.isStale(now: now),
                       snapshot.windows.contains(where: { $0.confidence == .verified && $0.remainingRatio != nil }) {
                        Label(localization.text("dataStatus.fresh"), systemImage: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                    if model.codexOAuthStatus == .credentialStorageFailed {
                        Label(localization.text("dataStatus.credentials"), systemImage: "key")
                    }
                    ForEach(issues, id: \.self) { key in
                        Text(localization.text(key)).fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(snapshot?.errors ?? [], id: \.self) { key in
                        if localization.text(key) != key {
                            Text(localization.text(key)).foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(width: 354, alignment: .leading)
            }
            .frame(maxHeight: 240)
            HStack {
                Button(localization.text("action.refresh")) {
                    Task { await model.refresh(reason: .manual); now = Date() }
                }
                .disabled(model.isRefreshing || model.codexOAuthStatus != .connected)
                if model.codexOAuthStatus == .credentialStorageFailed {
                    Button(localization.text("dataStatus.retryCredentials")) {
                        Task { await model.retryCredentialRead(); now = Date() }
                    }.disabled(model.isRetryingCredentialRead)
                } else if model.codexOAuthStatus != .connected || snapshot?.recoveryAction == .reconnect {
                    Button(localization.text("action.settings")) {
                        close()
                        model.openMainWindowFromWidget()
                    }
                }
            }
            .controlSize(.small)
        }
        .font(.callout)
        .padding(18)
        .frame(width: 390)
        .task {
            while !Task.isCancelled {
                now = Date()
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
            }
        }
    }

    private var sourceText: String {
        guard let source = snapshot?.source else { return localization.text("dataStatus.none") }
        switch source {
        case .appServer: return localization.text("dataStatus.sourceAppServer")
        case .oauthAPI: return localization.text("dataStatus.sourceOAuth")
        case .mock: return localization.text("source.mock")
        case .local: return localization.text("source.local")
        case .usageAPI: return localization.text("source.usageAPI")
        case .costAPI: return localization.text("source.costAPI")
        case .manual: return localization.text("source.manual")
        }
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else { return localization.text("dataStatus.none") }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.language.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

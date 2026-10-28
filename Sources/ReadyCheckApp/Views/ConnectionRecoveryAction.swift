import ReadyCheckCore
import SwiftUI

enum ConnectionRecoveryAction: Equatable {
    case retryCredentials, connection, refresh, checkUpdates, waiting

    static func resolve(status: CodexOAuthConnectionStatus, snapshot: ProviderQuotaSnapshot?) -> Self {
        if status == .waitingForCallback || status == .exchanging { return .waiting }
        if status == .credentialStorageFailed || snapshot?.errors.contains("oauth.error.keychainReadFailed") == true {
            return .retryCredentials
        }
        guard status == .connected else { return .connection }
        switch snapshot?.recoveryAction {
        case .connect, .reconnect: return .connection
        case .checkForUpdates: return .checkUpdates
        case .some(.none) where snapshot?.errors.isEmpty == false: return .connection
        default: return .refresh
        }
    }

    var titleKey: String {
        switch self {
        case .retryCredentials: "dataStatus.retryCredentials"
        case .connection: "recovery.openConnection"
        case .refresh: "recovery.refreshReading"
        case .checkUpdates: "action.checkForUpdates"
        case .waiting: "oauth.status.waitingForCallback"
        }
    }
}

struct ConnectionRecoveryButton: View {
    @Bindable var model: ReadyCheckAppModel
    var beforeNavigation: () -> Void = {}
    var afterAction: () -> Void = {}

    private var action: ConnectionRecoveryAction { model.connectionRecoveryAction }

    var body: some View {
        Button(model.localization.text(action.titleKey)) {
            if action == .connection { beforeNavigation() }
            Task { await model.performConnectionRecovery(action); afterAction() }
        }
        .disabled(isDisabled)
    }

    private var isDisabled: Bool {
        switch action {
        case .waiting: true
        case .retryCredentials: model.isRetryingCredentialRead
        case .refresh: model.isRefreshing
        case .checkUpdates: model.updateStatus == .checking
        case .connection: false
        }
    }
}

extension ReadyCheckAppModel {
    var connectionRecoveryAction: ConnectionRecoveryAction {
        .resolve(status: codexOAuthStatus, snapshot: snapshots.first { $0.providerId == "codex-oauth" })
    }

    func performConnectionRecovery(_ action: ConnectionRecoveryAction) async {
        guard action == connectionRecoveryAction else { return }
        switch action {
        case .retryCredentials: await retryCredentialRead()
        case .refresh: await refresh(reason: .manual)
        case .checkUpdates: await checkForUpdates(isManual: true)
        case .connection:
            mainWindowPage = .settings
            mainSettingsSection = .connection
            openMainWindowFromWidget()
        case .waiting: break
        }
    }
}

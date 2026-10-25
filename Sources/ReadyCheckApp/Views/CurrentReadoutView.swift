import ReadyCheckCore
import SwiftUI

enum CurrentReadoutState: String {
    case waiting, refreshing, credentials, unavailable, cached, stale, current

    init(snapshot: ProviderQuotaSnapshot?, refreshing: Bool, credentialsUnavailable: Bool, now: Date) {
        if credentialsUnavailable { self = .credentials }
        else if refreshing { self = .refreshing }
        else if let snapshot {
            if snapshot.isCached == true { self = .cached }
            else if snapshot.status != .available { self = .unavailable }
            else if snapshot.isStale(now: now) { self = .stale }
            else { self = .current }
        } else { self = .waiting }
    }
}

struct CurrentReadoutView: View {
    @Bindable var model: ReadyCheckAppModel
    let now: Date

    var body: some View {
        let state = CurrentReadoutState(snapshot: model.snapshots.first { $0.providerId == "codex-oauth" },
            refreshing: model.isRefreshing, credentialsUnavailable: model.codexOAuthStatus == .credentialStorageFailed, now: now)
        HStack(alignment: .top, spacing: 8) {
            if state == .refreshing { ProgressView().controlSize(.small) }
            else {
                Image(systemName: state == .current ? "checkmark.circle" : state == .waiting ? "clock" : "exclamationmark.circle")
                    .foregroundStyle(state == .current || state == .waiting ? Color.secondary : .orange)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(model.localization.text("readout." + state.rawValue)).font(.subheadline.weight(.medium))
                    Text(lastSuccess).font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.localization.text("readout." + state.rawValue)).font(.subheadline.weight(.medium))
                    Text(lastSuccess).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .help(model.localization.text("dashboard.refreshCadence"))
    }

    private var lastSuccess: String {
        guard let date = model.lastSuccessfulRefreshAt else { return model.localization.text("status.notUpdatedYet") }
        let format: Date.FormatStyle = Calendar.current.isDate(date, inSameDayAs: now)
            ? .dateTime.locale(Locale(identifier: model.language.rawValue)).hour().minute()
            : .dateTime.locale(Locale(identifier: model.language.rawValue)).month().day().hour().minute()
        let formatted = date.formatted(format)
        return model.localization.text("dataStatus.lastSuccess") + " " + formatted
    }
}

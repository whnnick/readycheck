import ReadyCheckCore
import AppKit
import SwiftUI

struct MenuBarQuotaView: View {
    @Bindable var model: ReadyCheckAppModel
    let openSettings: @MainActor () -> Void

    @State private var now = Date()

    private var localization: LocalizationService {
        model.localization
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if model.snapshots.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(model.snapshots) { snapshot in
                        QuotaCardView(
                            snapshot: snapshot,
                            localization: localization,
                            now: now
                        )
                    }
                }
            }

            footer
        }
        .padding(14)
        .frame(width: 340)
        .task {
            await refreshOnOpenIfNeeded()
        }
        .task {
            await updateNowWhileVisible()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title3)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.text("app.name"))
                    .font(.headline)

                Text(refreshSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(accountSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if model.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(localization.text("status.autoUpdate"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
        }
    }

    private var emptyState: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: 6) {
                Text(localization.text("empty.quota.title"))
                    .font(.subheadline.weight(.medium))

                Text(model.isRefreshing ? localization.text("status.refreshing") : emptyStateMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(localization.text("status.safeRefresh"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if model.codexOAuthStatus != .connected {
                    Button {
                        openSettings()
                    } label: {
                        Label(localization.text("action.connectCodex"), systemImage: "key.horizontal")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    Task {
                        await model.refresh(reason: .manual)
                        now = Date()
                    }
                } label: {
                    Label(localization.text("action.refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(model.isRefreshing)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Label(localization.text("action.settings"), systemImage: "gearshape")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $model.widgetVisible) {
                    Label(localization.text("action.pinWidget"), systemImage: "macwindow.on.rectangle")
                }
                .toggleStyle(.switch)

                Toggle(isOn: $model.widgetAlwaysOnTop) {
                    Label(localization.text("settings.widgetAlwaysOnTop"), systemImage: "rectangle.on.rectangle")
                }
                .toggleStyle(.switch)

                Button {
                    model.resetFloatingWidgetPosition()
                } label: {
                    Label(localization.text("action.resetWidgetPosition"), systemImage: "arrow.down.forward.and.arrow.up.backward")
                }
            }

            Divider()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label(localization.text("action.quit"), systemImage: "power")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    @MainActor
    private func refreshOnOpenIfNeeded() async {
        let currentNow = Date()
        now = currentNow
        await model.reloadCodexOAuthConnectionStatus()

        guard model.codexOAuthStatus == .connected || !model.snapshots.isEmpty else {
            return
        }

        guard model.snapshots.isEmpty || model.hasStaleSnapshots(now: currentNow) else {
            return
        }

        await model.refresh(reason: .openedPanel)
        now = Date()
    }

    @MainActor
    private func updateNowWhileVisible() async {
        while !Task.isCancelled {
            let currentNow = Date()
            now = currentNow

            if model.shouldAutomaticallyRefresh(now: currentNow) {
                await model.refresh(reason: .automatic)
                now = Date()
            }

            try? await Task.sleep(for: .seconds(1))
        }
    }

    private var refreshSummary: String {
        guard let lastRefreshAt = model.lastRefreshAt else {
            return localization.text("status.notUpdatedYet")
        }

        let time = DateFormatter.localizedString(from: lastRefreshAt, dateStyle: .none, timeStyle: .short)
        return "\(localization.text("status.lastUpdated")) \(time)"
    }

    private var emptyStateMessage: String {
        if model.codexOAuthStatus == .connected {
            return localization.text("empty.quota.connectedMessage")
        }

        return localization.text("empty.quota.codexMessage")
    }

    private var accountSummary: String {
        if let email = model.codexOAuthLoginEmail, !email.isEmpty {
            return "\(localization.text("oauth.account.connectedAs")) \(email)"
        }

        return localization.text("oauth.status.notConnected")
    }
}

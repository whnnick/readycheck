import ReadyCheckCore
import SwiftUI

struct FloatingWidgetView: View {
    @Bindable var model: ReadyCheckAppModel

    @State private var now = Date()

    private var localization: LocalizationService {
        model.localization
    }

    private var visibleSnapshots: ArraySlice<ProviderQuotaSnapshot> {
        model.snapshots.prefix(2)
    }

    var body: some View {
        GlassSurface(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if model.snapshots.isEmpty {
                    emptyState
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.openMainWindowFromWidget()
                        }
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(visibleSnapshots)) { snapshot in
                            QuotaCardView(
                                snapshot: snapshot,
                                localization: localization,
                                now: now,
                                displayMode: quotaCardDisplayMode
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.openMainWindowFromWidget()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(width: 352)
        .background(.clear)
        .task {
            await updateNowWhileVisible()
        }
    }

    private var quotaCardDisplayMode: QuotaCardView.DisplayMode {
        switch model.widgetDisplayMode {
        case .minimal:
            .compact
        case .detailed:
            .widgetDetailed
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.text("app.name"))
                        .font(.headline)

                    Text(refreshSummary)
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }

                Text(localization.text("status.autoUpdate"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.78))
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.10), in: Capsule())

                Spacer()

                Button {
                    Task {
                        await model.refresh(reason: .manual)
                        now = Date()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(model.isRefreshing)
                .help(localization.text("action.refresh"))

                Button {
                    model.hideFloatingWidget()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help(localization.text("action.hideWidget"))
            }

            HStack(spacing: 8) {
                Label(localization.text("settings.widgetStyle"), systemImage: "rectangle.split.2x1")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                WidgetStyleSwitcherView(selection: $model.widgetDisplayMode, localization: localization)

                Spacer(minLength: 0)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text("empty.quota.title"))
                .font(.subheadline.weight(.medium))

            Text(localization.text("empty.quota.message"))
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))

            Text(localization.text("status.safeRefresh"))
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
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
}

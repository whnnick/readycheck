import AppKit
import ReadyCheckCore
import SwiftUI

struct FloatingWidgetView: View {
    @Bindable var model: ReadyCheckAppModel

    @State private var now = Date()

    private var localization: LocalizationService {
        model.localization
    }

    private var visibleSnapshots: ArraySlice<ProviderQuotaSnapshot> {
        model.snapshots.filter { $0.providerId == "codex-oauth" }.prefix(2)
    }

    var body: some View {
        GlassSurface(cornerRadius: 22, renderingMode: .liquidGlass) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if model.quickDisplayService == nil {
                    Button(localization.text("settings.quickDisplay"), action: model.showQuickDisplaySettings)
                } else if model.quickDisplayService == .muse {
                    MuseUsageView(connection: model.muse, language: model.language, now: now)
                        .contentShape(Rectangle()).onTapGesture { model.openQuickDisplayOverview() }
                } else if model.quickDisplayService == .deepSeek {
                    DeepSeekBalancePanel(connection: model.deepSeek, language: model.language, now: now) {
                        model.openQuickDisplayOverview()
                    }
                } else if visibleSnapshots.isEmpty {
                    emptyState
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.openQuickDisplayOverview()
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
                        model.openQuickDisplayOverview()
                    }
                    NextEventsView(model: model, now: now, compact: true, openMain: model.openMainWindowFromWidget)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(width: 352)
        .background(.clear)
        .contextMenu { WidgetSnoozeMenu(model: model) }
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
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.text("app.name"))
                            .font(.headline)

                        if model.quickDisplayService != nil {
                            Text(refreshSummary).font(.caption2).foregroundStyle(Color.primary.opacity(0.72))
                        }
                    }

                    Text(localization.text("status.autoUpdate"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.78))
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.10), in: Capsule())

                    Spacer()
                }
                .overlay { WidgetDragRegion() }
                .help(localization.text("widget.dragHint"))

                Button {
                    Task {
                        if let service = model.quickDisplayService { await model.refreshService(service) }
                        now = Date()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(model.quickDisplayService == nil || model.quickDisplayServiceBusy)
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
            now = Date()

            try? await Task.sleep(for: .seconds(1))
        }
    }

    private var refreshSummary: String {
        if model.quickDisplayService == .muse { return model.muse.statusText(language: model.language, now: now) }
        if model.quickDisplayService == .deepSeek {
            return model.deepSeek.observedAt.map {
                "DeepSeek · " + $0.formatted(date: .omitted, time: .standard)
            } ?? (model.language == .zhCN ? "DeepSeek 尚未更新" : "DeepSeek has not updated yet")
        }
        guard let lastRefreshAt = model.lastRefreshAt else {
            return localization.text("status.notUpdatedYet")
        }

        let time = DateFormatter.localizedString(from: lastRefreshAt, dateStyle: .none, timeStyle: .short)
        return "\(localization.text("status.lastUpdated")) \(time)"
    }
}

private struct WidgetDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> WidgetDragView { WidgetDragView() }
    func updateNSView(_ nsView: WidgetDragView, context: Context) {}
}

final class WidgetDragView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

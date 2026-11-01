import ReadyCheckCore
import SwiftUI

struct NotchDetailsView: View {
    @Bindable var model: ReadyCheckAppModel
    let now: Date
    var onDismiss: () -> Void = {}

    private var snapshot: ProviderQuotaSnapshot? { model.snapshots.first { $0.providerId == "codex-oauth" } }
    private var windows: [QuotaWindow] { snapshot?.windows ?? [] }

    var body: some View {
        Group {
            if model.selectedDeepSeek {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView {
                        DeepSeekBalancePanel(connection: model.deepSeek, language: model.language, now: now) {
                            model.mainWindowPage = .overview
                            model.openMainWindowFromWidget()
                            onDismiss()
                        }
                    }
                    Button(model.localization.text("bubble.openMainWindow")) {
                        model.mainWindowPage = .overview
                        model.openMainWindowFromWidget()
                        onDismiss()
                    }.buttonStyle(.plain).foregroundStyle(.cyan).font(.caption)
                }
            } else {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ReadyCheck").font(.subheadline.weight(.semibold))
                Spacer()
                if model.notchShowsBothQuotas {
                    Text("5h · 7d").font(.caption).foregroundStyle(.secondary)
                } else {
                Picker(model.localization.text("settings.quotaWindow"), selection: Binding(
                    get: { model.notchQuotaSelection.pickerSelection(in: windows) },
                    set: { model.notchQuotaSelection = $0 }
                )) {
                    Text(model.localization.text("settings.quotaWindowAutomatic")).tag(NotchQuotaSelection.automatic)
                    if !model.notchQuotaSelection.hasPreferredWindow(in: windows) {
                        Text(model.localization.text("settings.quotaWindowMissing")).tag(model.notchQuotaSelection)
                    }
                    ForEach(windows) { window in
                        Text(QuotaWindowDisplay.shortLabel(for: window)).tag(NotchQuotaSelection.window(window.id))
                    }
                }.labelsHidden().frame(maxWidth: 160).controlSize(.small)
                }
            }
            ScrollView(.vertical) {
                if let snapshot {
                    VStack(spacing: 6) {
                        ForEach(Self.orderedWindows(windows, primary: model.notchQuotaSelection,
                                                   showsBoth: model.notchShowsBothQuotas)) { window in
                            CompactQuotaRow(window: window, snapshot: snapshot, localization: model.localization, now: now)
                        }
                    }
                } else {
                    Text(model.localization.text("empty.quota.title")).font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                Text(snapshot?.isCached == true ? model.localization.text("status.stale") : snapshot.map {
                    DateFormatter.localizedString(from: $0.refreshedAt, dateStyle: .none, timeStyle: .short)
                } ?? "—").font(.caption2).foregroundStyle(.secondary)
                if let snapshot, snapshot.ordinaryUsageAllowed == false {
                    Text(model.localization.text("status.ordinaryUsageBlocked")).font(.caption2).foregroundStyle(.orange).lineLimit(2)
                }
                Spacer()
                Button(model.localization.text("bubble.openMainWindow")) {
                    model.mainWindowPage = .overview
                    model.openMainWindowFromWidget()
                    onDismiss()
                }.buttonStyle(.plain).foregroundStyle(.cyan).font(.caption)
            }
        }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .environment(\.colorScheme, .dark)
    }

    static func orderedWindows(_ windows: [QuotaWindow], primary: NotchQuotaSelection, showsBoth: Bool) -> [QuotaWindow] {
        guard showsBoth else { return primary.displayWindows(in: windows) }
        let fixed = NotchStatusView.dualWindows(in: windows).compactMap { $0 }
        let ids = Set(fixed.map(\.id))
        return fixed + windows.filter { !ids.contains($0.id) }
    }
}

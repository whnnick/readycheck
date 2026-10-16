import ReadyCheckCore
import SwiftUI

struct NotchDetailsView: View {
    @Bindable var model: ReadyCheckAppModel
    let now: Date
    var onDismiss: () -> Void = {}

    private var snapshot: ProviderQuotaSnapshot? { model.snapshots.first { $0.providerId == "codex-oauth" } }
    private var windows: [QuotaWindow] { snapshot?.windows ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ReadyCheck").font(.subheadline.weight(.semibold))
                Spacer()
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
            ScrollView(.vertical) {
                if let snapshot {
                    VStack(spacing: 6) {
                        ForEach(model.notchQuotaSelection.displayWindows(in: windows)) { window in
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
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(Color.black, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 22,
            bottomTrailingRadius: 22, topTrailingRadius: 20))
        .environment(\.colorScheme, .dark)
    }
}

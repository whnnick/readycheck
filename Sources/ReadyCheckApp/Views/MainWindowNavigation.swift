import AppKit
import ReadyCheckCore
import SwiftUI

enum MainWindowPage: String, CaseIterable, Identifiable {
    case overview, usage, settings
    var id: String { rawValue }
    var titleKey: String { "navigation.\(rawValue)" }
    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .usage: "chart.xyaxis.line"
        case .settings: "gearshape"
        }
    }
}

enum MainSettingsSection: String, CaseIterable, Identifiable {
    case reminders, display, connection, general
    var id: String { rawValue }
    var titleKey: String { "navigation.\(rawValue)" }
}

struct MainWindowSidebar: View {
    @Bindable var model: ReadyCheckAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().frame(width: 30, height: 30).accessibilityHidden(true)
                Text("ReadyCheck").font(.headline)
            }
            .padding(.horizontal, 14).padding(.top, 18)
            VStack(spacing: 5) {
                ForEach(MainWindowPage.allCases) { page in
                    Button { model.mainWindowPage = page } label: {
                        Label(model.localization.text(page.titleKey), systemImage: page.symbol)
                            .font(.system(size: 13, weight: model.mainWindowPage == page ? .semibold : .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .foregroundStyle(model.mainWindowPage == page ? Color.accentColor : Color.secondary)
                            .background(model.mainWindowPage == page ? Color.accentColor.opacity(0.12) : .clear,
                                in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                }
            }.padding(.horizontal, 10)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 6) {
                Text("Codex").font(.caption.weight(.semibold))
                Text(model.localization.text(model.codexConnectionMode == .localCodex ? "codex.connectionMode.local" : "codex.connectionMode.oauth"))
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                Text(ReadyCheckCore.version).font(.caption2.monospacedDigit()).foregroundStyle(.tertiary)
                Button { model.showAboutWindow() } label: {
                    Label(model.localization.text("about.menuItem"), systemImage: "info.circle")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .padding(.top, 6)
            }
            .padding(14)
        }
        .frame(width: 158)
        .background(.bar)
    }
}

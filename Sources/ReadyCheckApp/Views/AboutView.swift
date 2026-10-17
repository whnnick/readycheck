import AppKit
import ReadyCheckCore
import SwiftUI

struct AboutView: View {
    let localization: LocalizationService

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 72, height: 72)

                VStack(spacing: 5) {
                    Text(localization.text("app.name"))
                        .font(.title2.weight(.semibold))

                    Text("\(localization.text("about.version")) \(ReadyCheckCore.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(localization.text("about.safeRefresh"), systemImage: "checkmark.shield")
                    Label(localization.text("about.source"), systemImage: "network")
                    Label(localization.text("about.precision"), systemImage: "scope")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                ReleaseHighlightsView(localization: localization)
                Link(localization.text("release.readNotes"),
                     destination: URL(string: ReadyCheckCore.version.contains("-")
                        ? "https://github.com/whnnick/readycheck/releases/latest"
                        : "https://github.com/whnnick/readycheck/releases/tag/v\(ReadyCheckCore.version)")!)
                    .font(.caption)

                Text(localization.text("about.copyright"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(24)
        }
        .defaultScrollAnchor(.top)
        .frame(minWidth: 420, minHeight: 420)
        .background(.regularMaterial)
    }
}

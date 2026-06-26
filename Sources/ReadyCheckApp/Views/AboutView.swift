import ReadyCheckCore
import SwiftUI

struct AboutView: View {
    let localization: LocalizationService

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

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

            Text(localization.text("about.copyright"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 360)
        .background(.regularMaterial)
    }
}

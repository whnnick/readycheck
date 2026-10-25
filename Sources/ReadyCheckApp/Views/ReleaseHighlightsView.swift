import ReadyCheckCore
import SwiftUI

struct ReleaseHighlightsView: View {
    let localization: LocalizationService

    private let features = [
        ("rectangle", "release.compactCardDetails", "release.compactCardDetailsDetail"),
        ("square.grid.2x2", "release.focusedOverview", "release.focusedOverviewDetail"),
        ("square.stack", "release.retained", "release.retainedDetail")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(format: localization.text("release.highlights"), ReadyCheckCore.version))
                .font(.headline)
            ForEach(features.indices, id: \.self) { index in
                let feature = features[index]
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: feature.0)
                        .foregroundStyle(.tint)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localization.text(feature.1)).font(.subheadline.weight(.semibold))
                        Text(localization.text(feature.2)).font(.caption).foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

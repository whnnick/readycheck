import Foundation

public enum QuotaFormatters {
    public static func percentageText(for ratio: Double?) -> String {
        guard let ratio,
              ratio.isFinite,
              ratio >= 0,
              ratio <= 1
        else {
            return "—"
        }

        return "\(Int((ratio * 100).rounded()))%"
    }

    public static func sourceText(_ source: ProviderSource) -> String {
        switch source {
        case .mock:
            "Mock"
        case .local:
            "Local"
        case .usageAPI:
            "Usage API"
        case .costAPI:
            "Cost API"
        case .oauthAPI:
            "OAuth API"
        case .manual:
            "Manual"
        }
    }
}

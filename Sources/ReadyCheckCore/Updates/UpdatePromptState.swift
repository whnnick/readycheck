import Foundation

public struct UpdatePromptState: Equatable, Sendable {
    private var dismissedVersion: String?

    public init(dismissedVersion: String? = nil) {
        self.dismissedVersion = dismissedVersion.map(Self.canonicalVersion)
    }

    public func shouldShowBanner(for update: AppUpdate) -> Bool {
        dismissedVersion != Self.canonicalVersion(update.version)
    }

    public mutating func dismiss(_ update: AppUpdate) {
        dismissedVersion = Self.canonicalVersion(update.version)
    }

    private static func canonicalVersion(_ version: String) -> String {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }
}

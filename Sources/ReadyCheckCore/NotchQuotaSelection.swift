import Foundation

public enum NotchQuotaSelection: String, CaseIterable, Sendable {
    case fiveHour
    case sevenDay

    public var labelKey: String {
        switch self {
        case .fiveHour: "quota.window.codex.5h"
        case .sevenDay: "quota.window.codex.7d"
        }
    }

    public var shortLabel: String { self == .fiveHour ? "5h" : "7d" }

    public func matches(labelKey: String) -> Bool {
        labelKey == self.labelKey ||
            labelKey == (self == .fiveHour ? "quota.fiveHour" : "quota.sevenDay")
    }

    public static func value(defaults: UserDefaults = .standard) -> Self {
        defaults.string(forKey: defaultsKey).flatMap(Self.init(rawValue:)) ?? .sevenDay
    }

    public func persist(defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.defaultsKey)
    }

    private static let defaultsKey = "ReadyCheck.notchQuotaSelection.v1"
}

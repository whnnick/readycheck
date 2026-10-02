import Foundation

public enum NotchQuotaSelection: Hashable, Sendable {
    case automatic
    case window(String)
    case fiveHour
    case sevenDay

    public func hasPreferredWindow(in windows: [QuotaWindow]) -> Bool {
        switch self {
        case .automatic: return true
        case let .window(id): return windows.contains { $0.id == id }
        case .fiveHour: return windows.contains { $0.labelKey == "quota.window.codex.5h" || $0.labelKey == "quota.fiveHour" }
        case .sevenDay: return windows.contains { $0.labelKey == "quota.window.codex.7d" || $0.labelKey == "quota.sevenDay" }
        }
    }

    public func resolve(in windows: [QuotaWindow]) -> QuotaWindow? {
        let preferred: QuotaWindow?
        switch self {
        case .automatic:
            preferred = nil
        case let .window(id):
            preferred = windows.first { $0.id == id }
        case .fiveHour:
            preferred = windows.first { $0.labelKey == "quota.window.codex.5h" || $0.labelKey == "quota.fiveHour" }
        case .sevenDay:
            preferred = windows.first { $0.labelKey == "quota.window.codex.7d" || $0.labelKey == "quota.sevenDay" }
        }
        return preferred ?? windows.first
    }

    public func pickerSelection(in windows: [QuotaWindow]) -> Self {
        guard self != .automatic, hasPreferredWindow(in: windows),
              let selected = resolve(in: windows) else { return self }
        return .window(selected.id)
    }

    public static func value(defaults: UserDefaults = .standard) -> Self {
        if let stored = defaults.string(forKey: currentDefaultsKey) {
            return stored.isEmpty ? .automatic : .window(stored)
        }
        switch defaults.string(forKey: legacyDefaultsKey) {
        case "fiveHour": return .fiveHour
        case "sevenDay": return .sevenDay
        default: return .sevenDay
        }
    }

    public func persist(defaults: UserDefaults = .standard) {
        switch self {
        case .automatic:
            defaults.set("", forKey: Self.currentDefaultsKey)
        case let .window(id):
            defaults.set(id, forKey: Self.currentDefaultsKey)
        case .fiveHour:
            defaults.set("fiveHour", forKey: Self.legacyDefaultsKey)
            defaults.removeObject(forKey: Self.currentDefaultsKey)
        case .sevenDay:
            defaults.set("sevenDay", forKey: Self.legacyDefaultsKey)
            defaults.removeObject(forKey: Self.currentDefaultsKey)
        }
    }

    private static let currentDefaultsKey = "ReadyCheck.quotaWindowSelection.v2"
    private static let legacyDefaultsKey = "ReadyCheck.notchQuotaSelection.v1"
}

public enum QuotaWindowDisplay {
    public static func shortLabel(for window: QuotaWindow) -> String {
        if let minutes = window.durationMinutes, minutes > 0 {
            if minutes % 1_440 == 0 { return "\(minutes / 1_440)d" }
            if minutes % 60 == 0 { return "\(minutes / 60)h" }
            return "\(minutes)m"
        }
        switch window.labelKey {
        case "quota.window.codex.5h", "quota.fiveHour": return "5h"
        case "quota.window.codex.7d", "quota.sevenDay": return "7d"
        default: return window.displayLabel ?? "—"
        }
    }

    public static func title(for window: QuotaWindow, localization: LocalizationService) -> String {
        if let label = window.displayLabel, !label.isEmpty {
            if window.durationMinutes != nil {
                return "\(label) · \(shortLabel(for: window))"
            }
            if window.labelKey == "quota.window.codex.secondary" {
                return "\(label) · \(localization.text("quota.window.secondarySuffix"))"
            }
            return label
        }
        if window.durationMinutes != nil,
           window.labelKey != "quota.window.codex.5h",
           window.labelKey != "quota.window.codex.7d" {
            return String(format: localization.text("quota.window.dynamic"), shortLabel(for: window))
        }
        return localization.text(window.labelKey)
    }
}

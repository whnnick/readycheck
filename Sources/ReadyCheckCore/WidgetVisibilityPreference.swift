import Foundation

public enum WidgetVisibilityPreference {
    public static let defaultsKey = "ReadyCheck.widgetVisible.v3"

    public static func value(defaults _: UserDefaults = .standard) -> Bool {
        true
    }
}

public enum WidgetDisplayMode: String, CaseIterable, Codable, Equatable, Sendable {
    case minimal
    case detailed
}

public enum WidgetPresentation: String, CaseIterable, Codable, Equatable, Sendable {
    case card
    case bubble
}

public enum WidgetPresentationPreference {
    public static let defaultsKey = "ReadyCheck.widgetPresentation.v1"

    public static func value(defaults: UserDefaults = .standard) -> WidgetPresentation {
        guard let rawValue = defaults.string(forKey: defaultsKey),
              let presentation = WidgetPresentation(rawValue: rawValue)
        else {
            return .bubble
        }
        return presentation
    }

    public static func set(_ presentation: WidgetPresentation, defaults: UserDefaults = .standard) {
        defaults.set(presentation.rawValue, forKey: defaultsKey)
    }
}

public enum WidgetDisplayModePreference {
    public static let defaultsKey = "ReadyCheck.widgetDisplayMode.v1"

    public static func value(defaults: UserDefaults = .standard) -> WidgetDisplayMode {
        guard let rawValue = defaults.string(forKey: defaultsKey),
              let mode = WidgetDisplayMode(rawValue: rawValue)
        else {
            return .minimal
        }

        return mode
    }

    public static func set(_ mode: WidgetDisplayMode, defaults: UserDefaults = .standard) {
        defaults.set(mode.rawValue, forKey: defaultsKey)
    }
}

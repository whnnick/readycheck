import Foundation

public enum WidgetVisibilityPreference {
    public static let defaultsKey = "ReadyCheck.widgetVisible.v3"

    public static func value(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: defaultsKey) as? Bool ?? true
    }

    public static func set(_ visible: Bool, defaults: UserDefaults = .standard) {
        defaults.set(visible, forKey: defaultsKey)
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
        if defaults.string(forKey: defaultsKey) == "edgeRail" {
            let frameKey = "ReadyCheck.bubbleWidgetFrame.v1"
            let backupKey = "ReadyCheck.bubbleWidgetFrame.beforeUnified.v1"
            if let legacy = defaults.string(forKey: "ReadyCheck.edgeRailFrame.v1") {
                let frame = NSRectFromString(legacy)
                if [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height].allSatisfy(\.isFinite),
                   frame.size.width > 0, frame.size.height > 0 {
                    if defaults.object(forKey: backupKey) == nil,
                       let previous = defaults.object(forKey: frameKey) {
                        defaults.set(previous, forKey: backupKey)
                    }
                    defaults.set(legacy, forKey: frameKey)
                }
            }
            defaults.set(WidgetPresentation.bubble.rawValue, forKey: defaultsKey)
            return .bubble
        }
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

import Foundation

public enum WidgetVisibilityPreference {
    public static let defaultsKey = "ReadyCheck.widgetVisible.v3"

    public static func value(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: defaultsKey) as? Bool ?? true
    }
}

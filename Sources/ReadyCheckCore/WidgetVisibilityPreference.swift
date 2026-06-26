import Foundation

public enum WidgetVisibilityPreference {
    public static let defaultsKey = "ReadyCheck.widgetVisible.v3"

    public static func value(defaults _: UserDefaults = .standard) -> Bool {
        true
    }
}

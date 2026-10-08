import Foundation

public enum WidgetSnoozePreference {
    public static let defaultsKey = "ReadyCheck.widgetSnoozedUntil.v1"

    public static func deadline(minutes: Int, now: Date = Date()) -> Date? {
        guard [30, 60].contains(minutes) else { return nil }
        return now.addingTimeInterval(TimeInterval(minutes * 60))
    }

    public static func value(defaults: UserDefaults = .standard) -> Date? {
        guard let timestamp = defaults.object(forKey: defaultsKey) as? Double,
              timestamp.isFinite, timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    public static func set(_ deadline: Date?, defaults: UserDefaults = .standard) {
        if let deadline {
            defaults.set(deadline.timeIntervalSince1970, forKey: defaultsKey)
        } else {
            defaults.removeObject(forKey: defaultsKey)
        }
    }

    public static func isActive(_ deadline: Date?, now: Date = Date()) -> Bool {
        deadline.map { $0 > now } ?? false
    }
}

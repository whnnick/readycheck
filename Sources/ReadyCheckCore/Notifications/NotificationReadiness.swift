import UserNotifications

public enum NotificationReadiness: Equatable, Sendable {
    case checking
    case ready
    case temporary
    case alertsDisabled
    case denied

    public static func evaluate(
        authorization: UNAuthorizationStatus,
        alerts: UNNotificationSetting,
        style: UNAlertStyle
    ) -> Self {
        switch authorization {
        case .notDetermined: return .checking
        case .authorized:
            guard alerts == .enabled else { return .alertsDisabled }
            switch style {
            case .alert: return .ready
            case .banner: return .temporary
            default: return .alertsDisabled
            }
        case .provisional: return .alertsDisabled
        default: return .denied
        }
    }
}

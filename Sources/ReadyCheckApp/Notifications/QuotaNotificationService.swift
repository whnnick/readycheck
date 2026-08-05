import Foundation
import ReadyCheckCore
import UserNotifications

@MainActor
final class QuotaNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter

    override init() {
        self.center = .current()
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func deliver(_ events: [QuotaReminderEvent], localization: LocalizationService) async {
        guard !events.isEmpty, await canDeliverNotifications() else { return }

        for event in events {
            let content = UNMutableNotificationContent()
            content.sound = .default

            switch event {
            case let .manualResetExpiring(index, expiresAt):
                content.title = localization.text("notification.resetExpiry.title")
                content.body = String(
                    format: localization.text("notification.resetExpiry.body"),
                    index,
                    Self.dateFormatter(language: localization.language).string(from: expiresAt)
                )
            case .creditsStarted:
                content.title = localization.text("notification.creditsStarted.title")
                content.body = localization.text("notification.creditsStarted.body")
            }

            let request = UNNotificationRequest(
                identifier: identifier(for: event),
                content: content,
                trigger: nil
            )
            try? await center.add(request)
        }
    }

    private func canDeliverNotifications() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            await requestAuthorizationIfNeeded()
            let updatedSettings = await center.notificationSettings()
            return updatedSettings.authorizationStatus == .authorized
                || updatedSettings.authorizationStatus == .provisional
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func identifier(for event: QuotaReminderEvent) -> String {
        switch event {
        case let .manualResetExpiring(_, expiresAt):
            return "readycheck.reset-expiry.\(Int64(expiresAt.timeIntervalSince1970.rounded()))"
        case .creditsStarted:
            return "readycheck.credits-started.\(UUID().uuidString)"
        }
    }

    private static func dateFormatter(language: AppLanguage) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

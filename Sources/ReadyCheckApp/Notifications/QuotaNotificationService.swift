import Foundation
import OSLog
import ReadyCheckCore
import UserNotifications

enum NotificationReadiness: Equatable {
    case checking
    case ready
    case alertsDisabled
    case denied
}

enum TestNotificationResult: Equatable {
    case idle
    case sending
    case delivered
    case failed
}

@MainActor
final class QuotaNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private static let logger = Logger(subsystem: "com.readycheck.app", category: "quota-notifications")
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

    func readiness() async -> NotificationReadiness {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return settings.alertSetting == .enabled ? .ready : .alertsDisabled
        case .notDetermined:
            return .checking
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func sendTestNotification(localization: LocalizationService) async -> Bool {
        guard await canDeliverNotifications() else { return false }

        let content = UNMutableNotificationContent()
        content.title = localization.text("notification.test.title")
        content.body = localization.text("notification.test.body")
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "readycheck.test.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        return await addAndVerify(request)
    }

    func deliver(
        _ events: [QuotaReminderEvent],
        localization: LocalizationService
    ) async -> [QuotaReminderEvent] {
        guard !events.isEmpty, await canDeliverNotifications() else { return [] }

        var deliveredEvents: [QuotaReminderEvent] = []

        for event in events {
            let content = UNMutableNotificationContent()
            content.sound = .default

            switch event {
            case let .manualResetExpiring(index, expiresAt, leadHours):
                content.title = localization.text("notification.resetExpiry.title")
                content.body = String(
                    format: localization.text("notification.resetExpiry.body"),
                    index,
                    leadHours,
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
            if await addAndVerify(request) {
                deliveredEvents.append(event)
            }
        }

        return deliveredEvents
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

    private func addAndVerify(_ request: UNNotificationRequest) async -> Bool {
        do {
            try await center.add(request)
        } catch {
            Self.logger.error("Failed to add quota notification: \(String(describing: error), privacy: .public)")
            return false
        }

        for delay in [150, 350, 700, 1_200] {
            try? await Task.sleep(for: .milliseconds(delay))
            let identifiers = await deliveredNotificationIdentifiers()
            if identifiers.contains(request.identifier) {
                return true
            }
        }

        Self.logger.error("Notification was accepted but not found in Notification Center: \(request.identifier, privacy: .public)")
        return false
    }

    private func deliveredNotificationIdentifiers() async -> Set<String> {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                continuation.resume(returning: Set(notifications.map { $0.request.identifier }))
            }
        }
    }

    private func identifier(for event: QuotaReminderEvent) -> String {
        switch event {
        case let .manualResetExpiring(_, expiresAt, leadHours):
            return "readycheck.reset-expiry.\(Int64(expiresAt.timeIntervalSince1970.rounded())).\(leadHours)"
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

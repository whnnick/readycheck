import Foundation
import OSLog
import ReadyCheckCore
import UserNotifications

enum TestNotificationResult: Equatable {
    case idle
    case sending
    case delivered
    case failed
}

struct NotificationCenterConfiguration {
    let authorizationStatus: UNAuthorizationStatus
    let alertSetting: UNNotificationSetting
    let alertStyle: UNAlertStyle
}

@MainActor
protocol NotificationCenterClient: AnyObject {
    func configuration() async -> NotificationCenterConfiguration
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func deliveredIdentifiers() async -> Set<String>
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

@MainActor
private final class SystemNotificationCenterClient: NotificationCenterClient {
    let center = UNUserNotificationCenter.current()

    func configuration() async -> NotificationCenterConfiguration {
        let settings = await center.notificationSettings()
        return NotificationCenterConfiguration(
            authorizationStatus: settings.authorizationStatus,
            alertSetting: settings.alertSetting,
            alertStyle: settings.alertStyle
        )
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func deliveredIdentifiers() async -> Set<String> {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                continuation.resume(returning: Set(notifications.map { $0.request.identifier }))
            }
        }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

@MainActor
final class QuotaNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private static let logger = Logger(subsystem: "com.readycheck.app", category: "quota-notifications")
    private let client: any NotificationCenterClient
    private let verificationDelays: [Duration]
    private var expiryInFlight: Set<String> = []
    private var submittedExpiryIdentifiers: Set<String> = []
    var onOpenNotification: (() -> Void)?

    override init() {
        let client = SystemNotificationCenterClient()
        self.client = client
        self.verificationDelays = [.milliseconds(150), .milliseconds(350), .milliseconds(700), .milliseconds(1_200)]
        super.init()
        client.center.delegate = self
    }

    init(client: any NotificationCenterClient, verificationDelays: [Duration]) {
        self.client = client
        self.verificationDelays = verificationDelays
        super.init()
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await client.configuration()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await client.requestAuthorization(options: [.alert, .sound])
    }

    func readiness() async -> NotificationReadiness {
        let settings = await client.configuration()
        return NotificationReadiness.evaluate(
            authorization: settings.authorizationStatus,
            alerts: settings.alertSetting,
            style: settings.alertStyle
        )
    }

    func sendTestNotification(localization: LocalizationService) async -> Bool {
        guard await canDeliverNotifications() else { return false }

        let content = notificationContent(localization: localization)
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
        localization: LocalizationService,
        reminderStore: QuotaReminderStore
    ) async -> [QuotaReminderEvent] {
        guard !events.isEmpty else { return [] }

        var deliveredEvents: [QuotaReminderEvent] = []
        for event in events {
            if case let .dismissQuotaRecovered(requestID) = event {
                if await removeRecoveryNotifications(requestID: requestID) {
                    deliveredEvents.append(event)
                }
            }
        }

        let expiryEnabled = await reminderStore.resetExpiryReminderEnabled()
        let notificationEvents = events.filter {
            if case .manualResetExpiring = $0 { return expiryEnabled }
            if case .dismissQuotaRecovered = $0 { return false }
            return true
        }
        guard !notificationEvents.isEmpty, await canDeliverNotifications() else {
            return deliveredEvents
        }

        for event in notificationEvents {
            if case .manualResetExpiring = event,
               !(await reminderStore.isResetExpiryEventActive(event)) { continue }
            if case let .quotaLow(alert) = event,
               !(await reminderStore.isLowQuotaAlertActive(alert)) { continue }
            if case .quotaLow = event,
               await deliveredNotificationIdentifiers().contains(identifier(for: event)) {
                deliveredEvents.append(event)
                continue
            }
            if case let .quotaRecovered(requestID) = event,
               !(await reminderStore.isRecoveryRequestActive(requestID)) {
                continue
            }
            if case .quotaRecovered = event,
               await deliveredNotificationIdentifiers().contains(identifier(for: event)) {
                deliveredEvents.append(event)
                continue
            }
            let content = notificationContent(localization: localization)
            content.sound = .default

            switch event {
            case let .quotaLow(alert):
                content.title = localization.text("notification.lowQuota.title")
                content.body = String(
                    format: localization.text("notification.lowQuota.body"),
                    alert.displayLabel ?? localization.text(alert.labelKey), alert.remainingPercent
                )
            case let .manualResetExpiring(index, expiresAt, leadHours):
                content.title = localization.text("notification.resetExpiry.title")
                content.body = String(
                    format: localization.text("notification.resetExpiry.body"),
                    index,
                    leadHours,
                    Self.dateFormatter(language: localization.language).string(from: expiresAt)
                )
            case .quotaRecovered:
                content.title = localization.text("notification.recovered.title")
                content.body = localization.text("notification.recovered.body")
            case .creditsStarted:
                content.title = localization.text("notification.creditsStarted.title")
                content.body = localization.text("notification.creditsStarted.body")
            case .dismissQuotaRecovered:
                continue
            }

            let request = UNNotificationRequest(
                identifier: identifier(for: event),
                content: content,
                trigger: nil
            )
            let verified: Bool
            if case .manualResetExpiring = event {
                verified = await submitExpiryOnce(request, event: event, reminderStore: reminderStore)
            } else {
                verified = await addAndVerify(request)
            }
            if verified {
                if case let .quotaRecovered(requestID) = event {
                    _ = await removeRecoveryNotifications(exceptRequestID: requestID)
                }
                deliveredEvents.append(event)
            }
        }

        return deliveredEvents
    }

    func deliverResetCreditSuccess(_ notice: ResetCreditSuccessNotice, localization: LocalizationService,
                                   reminderStore: QuotaReminderStore) async -> Bool {
        if await reminderStore.hasDeliveredResetCreditNotice(notice.id) { return true }
        let identifier = "readycheck.reset-used.\(notice.id)"
        var delivered = await deliveredNotificationIdentifiers().contains(identifier)
        if !delivered, await canDeliverNotifications() {
            let content = notificationContent(localization: localization)
            content.title = localization.text("notification.resetUsed.title")
            content.body = String(format: localization.text("notification.resetUsed.body"),
                Self.dateFormatter(language: localization.language).string(from: notice.expiresAt))
            content.sound = .default
            delivered = await addAndVerify(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
        }
        let saved = await reminderStore.recordResetCreditNotice(notice, delivered: delivered)
        return delivered && saved
    }

    func deliverResetCreditCheckWarning(_ check: ResetCreditCheckRecord, localization: LocalizationService) async -> Bool {
        guard !check.warningSubmitted else { return true }
        guard check.shouldSubmitWarning else { return false }
        let identifier = "readycheck.reset-check." + check.id
        if await deliveredNotificationIdentifiers().contains(identifier) { return true }
        guard await canDeliverNotifications() else { return false }
        let content = notificationContent(localization: localization)
        content.title = localization.text("resetCheck.warningTitle")
        content.body = localization.text(check.reason == .serviceUnavailable ? "resetCheck.serviceWarning" : "resetCheck." + check.reason.rawValue)
        content.sound = .default
        do {
            try await client.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
            return true // Accepted submission suppresses repeat banners, even if the user dismisses it.
        } catch { return false }
    }

    func clearRecoveredResetCreditCheckWarnings(_ checks: [ResetCreditCheckRecord]) {
        let identifiers = checks.filter { $0.warningSubmitted && $0.recovered(in: checks) }
            .map { "readycheck.reset-check." + $0.id }
        guard !identifiers.isEmpty else { return }
        client.removeDeliveredNotifications(withIdentifiers: identifiers)
        client.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func canDeliverNotifications() async -> Bool {
        let settings = await client.configuration()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            await requestAuthorizationIfNeeded()
            let updatedSettings = await client.configuration()
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
            try await client.add(request)
        } catch {
            Self.logger.error("Failed to add quota notification: \(String(describing: error), privacy: .public)")
            return false
        }

        return await verifyDelivery(request)
    }

    private func submitExpiryOnce(_ baseRequest: UNNotificationRequest, event: QuotaReminderEvent,
                                  reminderStore: QuotaReminderStore) async -> Bool {
        let accountKey = await reminderStore.resetExpiryNotificationAccountKey()
        let request = UNNotificationRequest(identifier: baseRequest.identifier + (accountKey.map { "." + $0 } ?? ""),
                                            content: baseRequest.content, trigger: nil)
        guard !(await reminderStore.hasSubmittedResetExpiryNotification(event)),
              !submittedExpiryIdentifiers.contains(request.identifier),
              expiryInFlight.insert(request.identifier).inserted else { return false }
        defer { expiryInFlight.remove(request.identifier) }
        if await deliveredNotificationIdentifiers().contains(request.identifier) { return true }
        guard await reminderStore.resetExpiryNotificationAccountKey() == accountKey,
              await reminderStore.isResetExpiryEventActive(event) else { return false }
        do { try await client.add(request) }
        catch { return false }
        submittedExpiryIdentifiers.insert(request.identifier)
        _ = await reminderStore.recordResetExpirySubmission(event, accountKey: accountKey)
        return await verifyDelivery(request)
    }

    private func verifyDelivery(_ request: UNNotificationRequest) async -> Bool {
        for delay in verificationDelays {
            try? await Task.sleep(for: delay)
            let identifiers = await deliveredNotificationIdentifiers()
            if identifiers.contains(request.identifier) {
                return true
            }
        }

        Self.logger.error("Notification was accepted but not found in Notification Center: \(request.identifier, privacy: .public)")
        return false
    }

    private func deliveredNotificationIdentifiers() async -> Set<String> {
        await client.deliveredIdentifiers()
    }

    private func removeRecoveryNotifications(requestID: String? = nil, exceptRequestID: String? = nil) async -> Bool {
        let exact = requestID.map { "readycheck.recovered.\($0)" }
        let except = exceptRequestID.map { "readycheck.recovered.\($0)" }
        let delivered = await deliveredNotificationIdentifiers()
        var identifiers = delivered.filter {
            $0.hasPrefix("readycheck.recovered.") && $0 != except
        }
        if let exact { identifiers.insert(exact) }
        client.removeDeliveredNotifications(withIdentifiers: Array(identifiers))
        client.removePendingNotificationRequests(withIdentifiers: Array(identifiers))

        for delay in verificationDelays {
            try? await Task.sleep(for: delay)
            let remaining = await deliveredNotificationIdentifiers().filter {
                $0.hasPrefix("readycheck.recovered.") && $0 != except
            }
            if remaining.isEmpty { return true }
        }

        Self.logger.error("Recovery notification remained in Notification Center after removal")
        return false
    }

    private func identifier(for event: QuotaReminderEvent) -> String {
        switch event {
        case let .quotaLow(alert):
            return "readycheck.low-quota.\(alert.id)"
        case let .manualResetExpiring(_, expiresAt, leadHours):
            return "readycheck.reset-expiry.\(Int64(expiresAt.timeIntervalSince1970.rounded())).\(leadHours)"
        case let .quotaRecovered(requestID):
            return "readycheck.recovered.\(requestID)"
        case .creditsStarted:
            return "readycheck.credits-started.\(UUID().uuidString)"
        case let .dismissQuotaRecovered(requestID):
            return "readycheck.recovered.\(requestID)"
        }
    }

    private func notificationContent(localization: LocalizationService) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.subtitle = String(format: localization.text("notification.sentAt"),
            Self.dateFormatter(language: localization.language).string(from: Date()))
        return content
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
        completionHandler([.banner, .list, .sound])
    }

    func handleNotificationResponse(actionIdentifier: String) {
        guard actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        onOpenNotification?()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier
        await MainActor.run { self.handleNotificationResponse(actionIdentifier: actionIdentifier) }
    }
}

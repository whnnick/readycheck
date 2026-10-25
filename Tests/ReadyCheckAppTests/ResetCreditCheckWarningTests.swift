import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class ResetCreditCheckWarningTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_900_000_000)

    func testTransientReadFailureWaitsForThreeChecksAndTwoMinutesButUrgentFailuresDoNot() async {
        let client = CheckWarningNotifications()
        let service = QuotaNotificationService(client: client, verificationDelays: [])
        let localization = LocalizationService(language: .zhCN)
        for (count, elapsed) in [(1, 0.0), (2, 60), (3, 119)] {
            let submitted = await service.deliverResetCreditCheckWarning(check(count: count, elapsed: elapsed), localization: localization)
            XCTAssertFalse(submitted, "A transient read failure must remain retryable without acknowledging a notification")
        }
        XCTAssertTrue(client.requests.isEmpty)
        let persistent = await service.deliverResetCreditCheckWarning(check(count: 3, elapsed: 120), localization: localization)
        XCTAssertTrue(persistent)
        XCTAssertEqual(client.requests.count, 1)
        for reason: ResetCreditCheckRecord.Reason in [.credentialsUnavailable, .ledgerUnavailable, .writeFailed, .resultUnconfirmed, .cardChanged, .windowMissed] {
            let submitted = await service.deliverResetCreditCheckWarning(check(reason: reason), localization: localization)
            XCTAssertTrue(submitted, "Do not delay \(reason)")
        }
        XCTAssertEqual(client.requests.count, 7)
    }

    func testSubmissionFailureRetriesAndAcknowledgementSurvivesServiceRestart() async {
        let client = CheckWarningNotifications()
        let service = QuotaNotificationService(client: client, verificationDelays: [])
        let localization = LocalizationService(language: .enUS)
        var persistent = check(count: 3, elapsed: 120)
        client.failAdd = true
        let failed = await service.deliverResetCreditCheckWarning(persistent, localization: localization)
        XCTAssertFalse(failed)
        client.failAdd = false
        let retry = await service.deliverResetCreditCheckWarning(persistent, localization: localization)
        XCTAssertTrue(retry)
        persistent.warningSubmitted = true
        let restarted = QuotaNotificationService(client: client, verificationDelays: [])
        _ = await restarted.deliverResetCreditCheckWarning(persistent, localization: localization)
        XCTAssertEqual(client.requests.count, 1)
    }

    func testRecoveryOnlyWithdrawsEarlierSameAccountReadWarningsAndKeepsHistory() {
        let client = CheckWarningNotifications()
        let service = QuotaNotificationService(client: client, verificationDelays: [])
        var old = check(count: 3, elapsed: 120); old.warningSubmitted = true
        var urgent = check(reason: .resultUnconfirmed); urgent.warningSubmitted = true
        let other = ResetCreditCheckRecord(id: "other", accountKey: "B", reason: .serviceUnavailable,
            firstAt: now, lastAt: now, count: 3, warningSubmitted: true)
        let recovered = ResetCreditCheckRecord(id: "recovered", accountKey: "A", reason: .checked,
            firstAt: now.addingTimeInterval(180), lastAt: now.addingTimeInterval(240), count: 2, warningSubmitted: false)
        let rows = [recovered, old, urgent, other]
        service.clearRecoveredResetCreditCheckWarnings([old, urgent, other])
        XCTAssertTrue(client.removedDelivered.isEmpty)
        service.clearRecoveredResetCreditCheckWarnings(rows)
        XCTAssertEqual(client.removedDelivered, ["readycheck.reset-check.serviceUnavailable"])
        XCTAssertEqual(client.removedPending, client.removedDelivered)
        XCTAssertTrue(old.recovered(in: rows))
        XCTAssertFalse(other.recovered(in: rows))
        XCTAssertFalse(urgent.recovered(in: rows), "A read recovery cannot resolve an unknown redemption result")
        XCTAssertEqual(rows.count, 4, "Cleanup must not delete diagnostic history")
    }

    private func check(reason: ResetCreditCheckRecord.Reason = .serviceUnavailable, count: Int = 1, elapsed: TimeInterval = 0) -> ResetCreditCheckRecord {
        ResetCreditCheckRecord(id: reason.rawValue, accountKey: "A", reason: reason,
            firstAt: now, lastAt: now.addingTimeInterval(elapsed), count: count, warningSubmitted: false)
    }
}

@MainActor
private final class CheckWarningNotifications: NotificationCenterClient {
    var requests: [UNNotificationRequest] = []
    var removedDelivered: [String] = []
    var removedPending: [String] = []
    var failAdd = false
    func configuration() async -> NotificationCenterConfiguration {
        .init(authorizationStatus: .authorized, alertSetting: .enabled, alertStyle: .alert)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func add(_ request: UNNotificationRequest) async throws {
        if failAdd { throw URLError(.notConnectedToInternet) }
        requests.append(request)
    }
    func deliveredIdentifiers() async -> Set<String> { Set(requests.map(\.identifier)) }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) { removedDelivered += identifiers }
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) { removedPending += identifiers }
}

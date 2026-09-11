import XCTest
import UserNotifications
@testable import ReadyCheckCore

final class NotificationReadinessTests: XCTestCase {
    func testPersistentAndTemporaryAlertsAreDistinct() {
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .authorized, alerts: .enabled, style: .alert), .ready)
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .authorized, alerts: .enabled, style: .banner), .temporary)
    }

    func testSilentAndUnauthorizedDeliveryIsNotReportedAsReady() {
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .authorized, alerts: .enabled, style: .none), .alertsDisabled)
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .authorized, alerts: .disabled, style: .alert), .alertsDisabled)
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .provisional, alerts: .enabled, style: .banner), .alertsDisabled)
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .denied, alerts: .enabled, style: .alert), .denied)
        XCTAssertEqual(NotificationReadiness.evaluate(authorization: .notDetermined, alerts: .enabled, style: .alert), .checking)
    }
}

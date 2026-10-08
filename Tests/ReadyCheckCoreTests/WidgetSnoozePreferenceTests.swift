import XCTest
@testable import ReadyCheckCore

final class WidgetSnoozePreferenceTests: XCTestCase {
    func testDeadlineUsesWallClockAndExpiresAtBoundary() throws {
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let deadline = try XCTUnwrap(WidgetSnoozePreference.deadline(minutes: 30, now: now))
        XCTAssertEqual(deadline.timeIntervalSince(now), 1800)
        XCTAssertTrue(WidgetSnoozePreference.isActive(deadline, now: deadline.addingTimeInterval(-1)))
        XCTAssertFalse(WidgetSnoozePreference.isActive(deadline, now: deadline))
        XCTAssertFalse(WidgetSnoozePreference.isActive(deadline, now: deadline.addingTimeInterval(3600)))
        XCTAssertEqual(WidgetSnoozePreference.deadline(minutes: 60, now: now)?.timeIntervalSince(now), 3600)
        XCTAssertNil(WidgetSnoozePreference.deadline(minutes: -30, now: now))
    }

    func testRestartRetainsDeadlineAndResumeClearsIt() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertNil(WidgetSnoozePreference.value(defaults: defaults))
        let deadline = Date(timeIntervalSince1970: 1_900_001_800)
        WidgetSnoozePreference.set(deadline, defaults: defaults)
        let restarted = try XCTUnwrap(UserDefaults(suiteName: suite))
        XCTAssertEqual(WidgetSnoozePreference.value(defaults: restarted), deadline)
        WidgetSnoozePreference.set(nil, defaults: restarted)
        XCTAssertNil(WidgetSnoozePreference.value(defaults: defaults))
        defaults.set("invalid", forKey: WidgetSnoozePreference.defaultsKey)
        XCTAssertNil(WidgetSnoozePreference.value(defaults: defaults))
    }
}

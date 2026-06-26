import XCTest
@testable import ReadyCheckCore

final class RefreshSchedulerTests: XCTestCase {
    func testDefaultPolicyIntervalIsSixtySeconds() {
        XCTAssertEqual(RefreshPolicy.default.interval, 60)
    }

    func testInvalidPolicyIntervalsFallBackToDefault() {
        XCTAssertEqual(RefreshPolicy(interval: 0).interval, RefreshPolicy.default.interval)
        XCTAssertEqual(RefreshPolicy(interval: -1).interval, RefreshPolicy.default.interval)
        XCTAssertEqual(RefreshPolicy(interval: .infinity).interval, RefreshPolicy.default.interval)
    }

    func testManualRefreshIsAlwaysAllowedBeforeInterval() {
        let scheduler = RefreshScheduler(policy: RefreshPolicy(interval: 60))
        let lastRefresh = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 110)

        XCTAssertTrue(scheduler.shouldRefresh(lastRefresh: lastRefresh, now: now, reason: .manual))
    }

    func testOpenedPanelRefreshIsAlwaysAllowedBeforeInterval() {
        let scheduler = RefreshScheduler(policy: RefreshPolicy(interval: 60))
        let lastRefresh = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 110)

        XCTAssertTrue(scheduler.shouldRefresh(lastRefresh: lastRefresh, now: now, reason: .openedPanel))
    }

    func testAutomaticRefreshWaitsForInterval() {
        let scheduler = RefreshScheduler(policy: RefreshPolicy(interval: 60))
        let lastRefresh = Date(timeIntervalSince1970: 100)
        let beforeInterval = Date(timeIntervalSince1970: 159)
        let atInterval = Date(timeIntervalSince1970: 160)

        XCTAssertFalse(scheduler.shouldRefresh(lastRefresh: lastRefresh, now: beforeInterval, reason: .automatic))
        XCTAssertTrue(scheduler.shouldRefresh(lastRefresh: lastRefresh, now: atInterval, reason: .automatic))
    }

    func testAutomaticRefreshIsAllowedWithoutPreviousRefresh() {
        let scheduler = RefreshScheduler(policy: RefreshPolicy(interval: 60))
        let now = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(scheduler.shouldRefresh(lastRefresh: nil, now: now, reason: .automatic))
    }

    func testBackoffDelaysByFailureCount() {
        XCTAssertEqual(RefreshBackoff(failureCount: 0).delay, 60)
        XCTAssertEqual(RefreshBackoff(failureCount: 1).delay, 120)
        XCTAssertEqual(RefreshBackoff(failureCount: 2).delay, 300)
        XCTAssertEqual(RefreshBackoff(failureCount: 7).delay, 900)
    }
}

import Foundation
import XCTest
import ReadyCheckCore
@testable import ReadyCheckApp

final class CardEvidenceTimelineTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_900_000_000)
    private func record(status: ResetCreditAutomationStatus.Status = .reset, observed: Bool = false,
                        reminder: Bool = false, count: Int? = 2) -> ResetCreditExecutionRecord {
        .init(id: "card-request", expiresAt: time.addingTimeInterval(500), status: status,
              updatedAt: time, successNotificationPending: true,
              startedAt: observed ? nil : time.addingTimeInterval(-100), requestCount: count,
              observedOnly: observed, reminderOnly: reminder)
    }
    private func notice(id: String = "reset-used:card-request", kind: QuotaReminderHistoryKind = .resetCreditUsed) -> QuotaReminderHistoryRecord {
        .init(id: id, kind: kind, status: .delivered,
              lastAttemptAt: time.addingTimeInterval(20), deliveredAt: time.addingTimeInterval(25),
              expiresAt: time.addingTimeInterval(500))
    }

    func testPreparedResultAndNoticeEvidenceRemainDistinctAndChronological() {
        let events = CardEvidenceTimeline.events(record: record(), history: [notice()])
        XCTAssertEqual(events.map(\.kind), [.prepared, .result, .noticeAttempt, .noticeVerified])
        XCTAssertEqual(events.map(\.date), [time.addingTimeInterval(-100), time, time.addingTimeInterval(20), time.addingTimeInterval(25)])
    }

    func testLegacyReminderDoesNotTurnExpiryIntoAnEventOrClaimRequest() {
        XCTAssertTrue(CardEvidenceTimeline.events(record: record(status: .unrecorded, observed: true, reminder: true), history: [notice()]).isEmpty)
    }

    func testObservationIsNotLocalRequestOrRedemption() {
        let events = CardEvidenceTimeline.events(record: record(status: .disappeared, observed: true), history: [notice()])
        XCTAssertEqual(events.map(\.kind), [.observation])
        XCTAssertEqual(events.first?.date, time)
    }

    func testOtherRequestKindOrExpiryCannotAttachNotice() {
        var wrongExpiry = notice()
        wrongExpiry.expiresAt = time
        let history = [notice(id: "reset-used:another-request"), notice(kind: .manualResetExpiring), wrongExpiry]
        XCTAssertNil(CardEvidenceTimeline.notice(record: record(), history: history))
        XCTAssertEqual(CardEvidenceTimeline.events(record: record(), history: history).map(\.kind), [.prepared, .result])
    }

    func testPendingAttemptIsNotSuccessAndNoMissingNotificationTimeIsInvented() {
        XCTAssertNil(CardEvidenceTimeline.notice(record: record(status: .pending), history: [notice()]))
        let undated = QuotaReminderHistoryRecord(id: "reset-used:card-request", kind: .resetCreditUsed,
            status: .failed, expiresAt: time.addingTimeInterval(500))
        XCTAssertEqual(CardEvidenceTimeline.events(record: record(count: 0), history: [undated]).map(\.kind), [.prepared, .result])
        XCTAssertEqual(CardEvidenceTimeline.events(record: record(count: 0), history: []).first?.kind, .prepared)
    }
}

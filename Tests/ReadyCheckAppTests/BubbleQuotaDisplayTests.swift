import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

final class BubbleQuotaDisplayTests: XCTestCase {
    func testSwitchingQuotaWindowDoesNotLookLikeRecovery() {
        let fiveHour = BubbleQuotaDisplay(selection: .fiveHour, windowID: "codex-5h", ratio: 0.06)
        let sevenDay = BubbleQuotaDisplay(selection: .sevenDay, windowID: "codex-7d", ratio: 0.18)
        XCTAssertFalse(sevenDay.shouldHighlight(after: fiveHour))
    }

    func testOnlyIncreaseWithinSameWindowHighlights() {
        let before = BubbleQuotaDisplay(selection: .fiveHour, windowID: "codex-5h", ratio: 0.06)
        XCTAssertTrue(BubbleQuotaDisplay(selection: .fiveHour, windowID: "codex-5h", ratio: 0.18).shouldHighlight(after: before))
        XCTAssertFalse(BubbleQuotaDisplay(selection: .fiveHour, windowID: "codex-5h", ratio: 0.04).shouldHighlight(after: before))
        XCTAssertFalse(BubbleQuotaDisplay(selection: .fiveHour, windowID: "other-5h", ratio: 0.18).shouldHighlight(after: before))
        XCTAssertFalse(BubbleQuotaDisplay(selection: .fiveHour, windowID: "codex-5h", ratio: nil).shouldHighlight(after: before))
    }
}

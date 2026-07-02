import Foundation
import XCTest
@testable import ReadyCheckCore

final class UpdatePromptStateTests: XCTestCase {
    func testAvailableUpdateShowsBannerUntilSameVersionIsDismissed() {
        var state = UpdatePromptState()
        let update = AppUpdate(
            version: "v0.1.60",
            releaseURL: URL(string: "https://github.com/whnnick/readycheck/releases/tag/v0.1.60")!
        )

        XCTAssertTrue(state.shouldShowBanner(for: update))

        state.dismiss(update)

        XCTAssertFalse(state.shouldShowBanner(for: update))
    }

    func testNewerAvailableUpdateShowsBannerAfterPreviousVersionWasDismissed() {
        var state = UpdatePromptState()
        let dismissedUpdate = AppUpdate(
            version: "v0.1.60",
            releaseURL: URL(string: "https://github.com/whnnick/readycheck/releases/tag/v0.1.60")!
        )
        let newerUpdate = AppUpdate(
            version: "v0.1.61",
            releaseURL: URL(string: "https://github.com/whnnick/readycheck/releases/tag/v0.1.61")!
        )

        state.dismiss(dismissedUpdate)

        XCTAssertTrue(state.shouldShowBanner(for: newerUpdate))
    }
}

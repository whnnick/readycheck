import AppKit
import XCTest
@testable import ReadyCheckApp

@MainActor
final class WidgetInteractionControllerTests: XCTestCase {
    func testPinToggleKeepsOpenAndUnpinRestoresExitDismissal() async throws {
        let interaction = makeInteraction()
        var inside = true
        interaction.containsPointer = { inside }
        interaction.showPreview()
        interaction.hoverChanged(true)
        interaction.togglePin()
        XCTAssertEqual(interaction.state, .pinned)
        inside = false
        interaction.hoverChanged(false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .pinned)
        inside = true
        interaction.hoverChanged(true)
        interaction.togglePin()
        XCTAssertEqual(interaction.state, .preview)
        inside = false
        interaction.hoverChanged(false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
    }

    func testUnpinOutsideSchedulesDismissalAndDraggingCannotToggle() async throws {
        let interaction = makeInteraction()
        interaction.containsPointer = { false }
        interaction.togglePin()
        XCTAssertEqual(interaction.state, .collapsed)
        interaction.click()
        interaction.beginDrag()
        interaction.togglePin()
        XCTAssertEqual(interaction.state, .pinned)
        interaction.endDrag()
        interaction.togglePin()
        XCTAssertEqual(interaction.state, .preview)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
    }

    func testBriefHoverNeverOpensAndExitClosesOnlyPreview() async throws {
        let interaction = makeInteraction()
        interaction.containsPointer = { false }
        interaction.hoverChanged(true)
        interaction.hoverChanged(false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
        interaction.containsPointer = { true }
        interaction.hoverChanged(true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .preview)
        interaction.containsPointer = { false }
        interaction.hoverChanged(false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
    }

    func testClickPinsPreviewAndPointerExitCannotCloseIt() async throws {
        let interaction = makeInteraction()
        interaction.showPreview()
        interaction.hoverChanged(false)
        interaction.pinPreview()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .pinned)
        interaction.hoverChanged(false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .pinned)
        interaction.click()
        XCTAssertEqual(interaction.state, .collapsed)
    }

    func testExplicitCollapseDoesNotImmediatelyReopenUnderPointer() async throws {
        let interaction = makeInteraction()
        interaction.hoverChanged(true)
        interaction.click()
        interaction.collapse()
        interaction.hoverChanged(true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
        interaction.hoverChanged(false)
        interaction.hoverChanged(true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .preview)
    }

    func testDraggingAndResetCancelPendingHover() async throws {
        let interaction = makeInteraction()
        interaction.hoverChanged(true)
        interaction.beginDrag()
        interaction.click()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
        interaction.endDrag()
        interaction.hoverChanged(false)
        interaction.hoverChanged(true)
        interaction.reset()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
        XCTAssertFalse(interaction.isDragging)
    }

    func testPreviewPanelDoesNotTakeKeyboardButPinnedPanelCanReceiveEscape() {
        _ = NSApplication.shared
        let panel = QuotaWidgetPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                     backing: .buffered, defer: false)
        XCTAssertFalse(panel.canBecomeKey)
        panel.allowsKeyboard = true
        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertFalse(panel.canBecomeMain)
        panel.close()
    }

    func testReenterBeforeExitDelayKeepsPreviewAndLaterExitClosesIt() async throws {
        let interaction = WidgetInteractionController(hoverDelay: .milliseconds(20), exitDelay: .milliseconds(100))
        var pointerInside = true
        interaction.containsPointer = { pointerInside }
        interaction.hoverChanged(true)
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertEqual(interaction.state, .preview)
        pointerInside = false
        interaction.hoverChanged(false)
        pointerInside = true
        interaction.hoverChanged(true)
        try await Task.sleep(for: .milliseconds(160))
        XCTAssertEqual(interaction.state, .preview)
        pointerInside = false
        interaction.hoverChanged(false)
        try await Task.sleep(for: .milliseconds(160))
        XCTAssertEqual(interaction.state, .collapsed)
    }

    func testSpaceSwitchClearsPinnedPreviewAndPendingHoverWithoutReopenLatch() async throws {
        let interaction = makeInteraction()
        var changes: [WidgetInteractionController.State] = []
        interaction.onChange = { changes.append($0) }
        interaction.hoverChanged(true)
        interaction.click()
        interaction.spaceChanged()
        XCTAssertEqual(changes.last, .collapsed)
        interaction.hoverChanged(true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .preview)
        interaction.spaceChanged()
        interaction.hoverChanged(true)
        interaction.spaceChanged()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(interaction.state, .collapsed)
    }

    private func makeInteraction() -> WidgetInteractionController {
        WidgetInteractionController(hoverDelay: .milliseconds(20), exitDelay: .milliseconds(20))
    }
}

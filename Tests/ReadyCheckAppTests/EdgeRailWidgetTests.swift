import AppKit
import SwiftUI
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class EdgeRailWidgetTests: XCTestCase {
    @MainActor
    func testBubbleCanDragDirectlyInwardAfterDetailsOpenAtEitherEdge() throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        defer {
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        let visible = try XCTUnwrap(NSScreen.main).visibleFrame
        for (edge, pinned) in [(BubbleWidgetPlacement.Edge.left, true), (.left, false), (.right, true), (.right, false)] {
            let tab = BubbleWidgetPlacement.tabFrame(from: CGRect(x: visible.midX, y: visible.midY,
                width: 92, height: 92), edge: edge, in: visible)
            defaults.set(NSStringFromRect(tab), forKey: key)
            let controller = BubbleWindowController()
            let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
                client: RailTestNotificationClient(), verificationDelays: []))
            let previous = Set(NSApp.windows.map(\.windowNumber))
            controller.show(model: model)
            defer { controller.close() }
            let panel = try XCTUnwrap(NSApp.windows.first { $0 is QuotaWidgetPanel && !previous.contains($0.windowNumber) })
            let host = try XCTUnwrap(panel.contentViewController?.children.first as? NSHostingController<BubbleWidgetView>)
            host.rootView.onTap()
            if !pinned { host.rootView.onTogglePin() }
            XCTAssertTrue(host.rootView.isExpanded)
            XCTAssertEqual(host.rootView.isPinned, pinned)
            host.rootView.onDragChanged(CGSize(width: edge == .left ? 200 : -200, height: 0))
            host.rootView.onDragEnded()
            XCTAssertFalse(host.rootView.isExpanded)
            XCTAssertNil(host.rootView.tabEdge)
            XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.bubbleSize)
            XCTAssertEqual(panel.frame.midY, tab.midY, accuracy: 1)
            XCTAssertTrue(visible.contains(panel.frame))
        }
    }

    func testOrbitalMaskStaysWithinWindowThroughoutExpansion() {
        for start in [BubbleWidgetPlacement.bubbleSize, BubbleWidgetPlacement.tabSize] {
            for step in 0...20 {
                let t = CGFloat(step) / 20
                let end = BubbleWidgetPlacement.expandedSize
                let bounds = CGRect(x: 0, y: 0, width: start.width + (end.width - start.width) * t,
                    height: start.height + (end.height - start.height) * t)
                for left in [false, true] {
                    let path = OrbitalWidgetShape(orbOnLeft: left, tabProgress: start == BubbleWidgetPlacement.tabSize ? 1 - t : 0)
                        .path(in: bounds)
                    // Non-cardinal circular arcs are approximated with cubic segments.
                    let subpixelTolerance: CGFloat = 0.1
                    XCTAssertGreaterThanOrEqual(path.boundingRect.minX, -subpixelTolerance)
                    XCTAssertLessThanOrEqual(path.boundingRect.maxX, bounds.width + subpixelTolerance)
                    XCTAssertGreaterThanOrEqual(path.boundingRect.minY, -subpixelTolerance)
                    XCTAssertLessThanOrEqual(path.boundingRect.maxY, bounds.height + subpixelTolerance)
                    XCTAssertTrue(path.contains(CGPoint(x: bounds.midX, y: bounds.midY)))
                }
            }
        }
    }

    func testBubbleWindowContentFollowsEdgeAndExpandedSizes() throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        let visible = try XCTUnwrap(NSScreen.main).visibleFrame
        defaults.set(NSStringFromRect(CGRect(x: visible.maxX - 66, y: visible.minY + 150,
            width: 66, height: 114)), forKey: key)
        let controller = BubbleWindowController()
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: RailTestNotificationClient(), verificationDelays: []))
        let previous = Set(NSApp.windows.map(\.windowNumber))
        defer {
            controller.close()
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        controller.show(model: model)
        let panel = try XCTUnwrap(NSApp.windows.first { $0 is QuotaWidgetPanel && !previous.contains($0.windowNumber) })
        XCTAssertTrue(panel.allowsToolTipsWhenApplicationIsInactive)
        let container = try XCTUnwrap(panel.contentViewController)
        let host = try XCTUnwrap(container.children.first as? NSHostingController<BubbleWidgetView>)
        host.rootView.onTap()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        if !NSApp.isActive && !panel.isKeyWindow {
            throw XCTSkip("Pinned-window sizing needs an unlocked foreground session; the panel could not retain keyboard focus.")
        }
        XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.expandedSize)
        XCTAssertEqual(container.view.bounds.size, panel.frame.size)
        XCTAssertEqual(host.view.bounds.size, panel.frame.size)
        XCTAssertEqual(try XCTUnwrap(container.view.layer?.mask).contentsScale, panel.backingScaleFactor)
        host.rootView.onTogglePin()
        XCTAssertFalse(panel.canBecomeKey)
        host.rootView.onTogglePin()
        XCTAssertTrue(panel.canBecomeKey)
        host.rootView.onCollapse()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.tabSize)
        XCTAssertEqual(host.view.bounds.size, panel.frame.size)
    }

    func testBubbleDetailsRetainEveryWindowAndRecoverSavedSelectionAfterRefresh() throws {
        _ = NSApplication.shared
        let previousIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let image = NSImage(contentsOfFile: path) {
            NSApp.applicationIconImage = image
        }
        defer { NSApp.applicationIconImage = previousIcon }
        let keys = ["ReadyCheck.quotaWindowSelection.v2", "ReadyCheck.notchQuotaSelection.v1"]
        let defaults = UserDefaults.standard
        let saved = keys.map { defaults.object(forKey: $0) }
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: RailTestNotificationClient(), verificationDelays: []))
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        let weekly = window(id: "weekly", minutes: 10_080, remaining: 70)
        let hourly = window(id: "hourly", minutes: 300, remaining: 13)
        let extra = window(id: "extra", minutes: 300, remaining: 85, name: "Additional allowance")
        model.notchQuotaSelection = .window(extra.id)
        let view = BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        for (name, windows, expectedIDs) in [
            ("bubble-extra", [hourly, weekly, extra], [extra.id, hourly.id, weekly.id]),
            ("bubble-weekly", [weekly], [weekly.id]),
            ("bubble-empty", [], []),
            ("bubble-restored", [weekly, extra], [extra.id, weekly.id])
        ] {
            model.snapshots = [snapshot(windows)]
            XCTAssertEqual(view.expandedWindows.map(\.id), expectedIDs)
            XCTAssertEqual(model.notchQuotaSelection, .window(extra.id))
            let host = NSHostingView(rootView: view)
            host.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
            try capture(host, name: name)
        }
        model.notchQuotaSelection = .fiveHour
        model.snapshots = [snapshot([hourly, weekly])]
        let capturedAt = Date()
        let drops = [0.003, 0.010, 0.025, 0.006, 0.002, 0.004, 0.015, 0.008, 0.021, 0.009, 0.007]
        model.quotaHistorySamples = (0..<12).map { index in
            QuotaHistorySample(providerID: "codex-oauth", recordedAt: capturedAt.addingTimeInterval(Double(index - 12) * 300),
                values: [QuotaHistoryValue(windowID: hourly.id, labelKey: hourly.labelKey,
                    remainingRatio: 0.24 - drops.prefix(index).reduce(0, +), resetAt: hourly.resetAt)])
        }
        let finalHost = NSHostingView(rootView: view)
        finalHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
        try capture(finalHost, name: "bubble-unified-demo")
        let preview = BubbleWidgetView(model: model, isExpanded: true, isPinned: false, tabEdge: nil,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        let previewHost = NSHostingView(rootView: preview)
        previewHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
        try capture(previewHost, name: "bubble-preview-demo")
        model.language = .enUS
        let englishHost = NSHostingView(rootView: view)
        englishHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
        try capture(englishHost, name: "bubble-english-demo")
        let englishPreviewHost = NSHostingView(rootView: preview)
        englishPreviewHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
        try capture(englishPreviewHost, name: "bubble-preview-en-demo")
        model.language = .zhCN
        let observedSamples = model.quotaHistorySamples
        for (name, indices) in [("bubble-zero-bars-demo", Array(0..<12)),
                                ("bubble-missing-bars-demo", [0, 1, 2, 7, 8, 9])] {
            model.quotaHistorySamples = indices.map { index in
                QuotaHistorySample(providerID: "codex-oauth",
                    recordedAt: capturedAt.addingTimeInterval(Double(index - 12) * 300),
                    values: [QuotaHistoryValue(windowID: hourly.id, labelKey: hourly.labelKey,
                        remainingRatio: 0.5, resetAt: hourly.resetAt)])
            }
            let chartHost = NSHostingView(rootView: view)
            chartHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
            try capture(chartHost, name: name)
        }
        model.quotaHistorySamples = observedSamples
        let mirrored = BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil, expansionSide: .left,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        let leftHost = NSHostingView(rootView: mirrored)
        leftHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.expandedSize)
        try capture(leftHost, name: "bubble-left-demo")
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            let rail = BubbleWidgetView(model: model, isExpanded: false, tabEdge: edge,
                onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
            let railHost = NSHostingView(rootView: rail)
            railHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.tabSize)
            try capture(railHost, name: "bubble-rail-" + edge.rawValue)
        }
        for remaining: Double in [0, 80, 100] {
            let compactWindow = window(id: hourly.id, minutes: 300, remaining: remaining)
            model.snapshots = [snapshot([compactWindow, weekly])]
            let compact = BubbleWidgetView(model: model, isExpanded: false, tabEdge: nil,
                onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
            let compactHost = NSHostingView(rootView: compact)
            compactHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.bubbleSize)
            try capture(compactHost, name: "bubble-compact-\(Int(remaining))-demo")
        }
        model.snapshots = []
        let unknown = BubbleWidgetView(model: model, isExpanded: false, tabEdge: nil,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        let unknownHost = NSHostingView(rootView: unknown)
        unknownHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.bubbleSize)
        try capture(unknownHost, name: "bubble-compact-unknown-demo")
    }

    func testModelRefreshResizesVisiblePanelWithoutMovingItsScreenEdge() throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let keys = [WidgetPresentationPreference.defaultsKey, "ReadyCheck.edgeRailFrame.v1", "ReadyCheck.notchStatusVisible.v1"]
        let saved = keys.map { defaults.object(forKey: $0) }
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: RailTestNotificationClient(), verificationDelays: []))
        defer {
            model.widgetVisible = false
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        model.widgetVisible = false
        model.widgetPresentation = .edgeRail
        model.moveEdgeRail(to: .right)
        let panel = try XCTUnwrap(NSApp.windows.first { $0 is NSPanel && $0.isVisible })
        let edgeX = panel.frame.maxX
        let weekly = window(id: "codex-secondary", minutes: 10_080, remaining: 70)
        let hourly = window(id: "codex-primary", minutes: 300, remaining: 13)
        let extra = window(id: "extra-primary", minutes: 60, remaining: 85, name: "Extra allowance")

        for (name, windows, expectedHeight) in [
            ("empty", [], CGFloat(100)),
            ("weekly", [weekly], CGFloat(105)),
            ("two", [hourly, weekly], CGFloat(176)),
            ("extra", [hourly, weekly, extra], CGFloat(264)),
            ("weekly-again", [weekly], CGFloat(105))
        ] {
            model.snapshots = [snapshot(windows)]
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            XCTAssertEqual(panel.frame.height, expectedHeight)
            XCTAssertEqual(panel.frame.maxX, edgeX)
            try capture(panel.contentView, name: name)
        }
        model.moveEdgeRail(to: .left)
        model.snapshots = [snapshot([hourly, weekly, extra])]
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(panel.frame.height, 264)
        try capture(panel.contentView, name: "left-extra")

        let detailHeight = EdgeRailPlacement.contentHeight(for: [hourly, weekly, extra], maximum: 700, mode: .detail)
        let detail = EdgeRailWidgetView(model: model, edge: .right, mode: .detail, height: detailHeight,
            onHover: { _ in }, onExpand: {}, onToggleDetail: {}, onCollapse: {}, onDragChanged: { _ in }, onDragEnded: {})
        let host = NSHostingView(rootView: detail)
        host.frame = CGRect(x: 0, y: 0, width: EdgeRailPlacement.detailWidth, height: detailHeight)
        try capture(host, name: "extra-detail")
    }

    private func window(id: String, minutes: Int, remaining: Double, name: String? = nil) -> QuotaWindow {
        let label = minutes == 300 ? "quota.window.codex.5h" : minutes == 10_080 ? "quota.window.codex.7d" : "quota.window.dynamic"
        return QuotaWindow(id: id, labelKey: label, displayLabel: name, kind: .rolling,
            used: 100 - remaining, limit: 100, remaining: remaining, unit: .percent,
            resetAt: Date().addingTimeInterval(minutes == 10_080 ? 6 * 86_400 + 5 * 3600 : 3600),
            confidence: .verified, durationMinutes: minutes)
    }

    private func snapshot(_ windows: [QuotaWindow]) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available,
            source: .appServer, refreshedAt: Date(), staleAfter: Date().addingTimeInterval(300),
            windows: windows, errors: [])
    }

    private func capture(_ view: NSView?, name: String) throws {
        guard let directory = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"], let view else { return }
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
    }
}

@MainActor
private final class RailTestNotificationClient: NotificationCenterClient {
    func configuration() async -> NotificationCenterConfiguration {
        NotificationCenterConfiguration(authorizationStatus: .denied, alertSetting: .disabled, alertStyle: .none)
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func deliveredIdentifiers() async -> Set<String> { [] }
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}

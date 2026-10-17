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

    func testAttachedBubbleRetainsItsEdgeDuringExpansionAndCollapse() throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        defer {
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        let visible = try XCTUnwrap(NSScreen.main).visibleFrame
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
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
            for _ in 0..<3 {
                host.rootView.onTap()
                XCTAssertTrue(host.rootView.isExpanded)
                XCTAssertEqual(host.rootView.tabEdge, edge, "Expanded attached content must not enter the free-floating dial path")
                RunLoop.main.run(until: Date().addingTimeInterval(0.04))
                host.rootView.onCollapse()
                XCTAssertEqual(host.rootView.tabEdge, edge)
                XCTAssertFalse(host.rootView.isExpanded)
            }
        }
    }

    func testAttachedWidgetTransitionFramesRenderAtBothEdges() throws {
        _ = NSApplication.shared
        let previousIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let image = NSImage(contentsOfFile: path) {
            NSApp.applicationIconImage = image
        }
        defer { NSApp.applicationIconImage = previousIcon }
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: RailTestNotificationClient(), verificationDelays: []))
        model.snapshots = [snapshot([window(id: "codex-primary", minutes: 300, remaining: 80),
            window(id: "codex-secondary", minutes: 10_080, remaining: 70)])]
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            for width: CGFloat in [28, 92, 180, 380] {
                let progress = (width - 28) / (380 - 28)
                let view = BubbleWidgetView(model: model, isExpanded: true, tabEdge: edge,
                    onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
                let host = NSHostingView(rootView: view)
                host.frame = CGRect(x: 0, y: 0, width: width, height: 144 + (304 - 144) * progress)
                try capture(host, name: "attached-\(edge.rawValue)-\(Int(width))")
            }
        }
    }

    func testWidgetMaskStaysWithinWindowThroughoutExpansion() {
        for start in [BubbleWidgetPlacement.bubbleSize, BubbleWidgetPlacement.tabSize] {
            for step in 0...20 {
                let t = CGFloat(step) / 20
                let end = BubbleWidgetPlacement.expandedSize
                let bounds = CGRect(x: 0, y: 0, width: start.width + (end.width - start.width) * t,
                    height: start.height + (end.height - start.height) * t)
                for inset in [CGFloat(0), 1] {
                    let path = WidgetPanelShape(tabProgress: start == BubbleWidgetPlacement.tabSize ? 1 - t : 0).inset(by: inset)
                        .path(in: bounds)
                    let subpixelTolerance: CGFloat = 0.1
                    XCTAssertGreaterThanOrEqual(path.boundingRect.minX, -subpixelTolerance)
                    XCTAssertLessThanOrEqual(path.boundingRect.maxX, bounds.width + subpixelTolerance)
                    XCTAssertGreaterThanOrEqual(path.boundingRect.minY, -subpixelTolerance)
                    XCTAssertLessThanOrEqual(path.boundingRect.maxY, bounds.height + subpixelTolerance)
                    XCTAssertTrue(path.contains(CGPoint(x: bounds.midX, y: bounds.midY)), "start=\(start), step=\(step), inset=\(inset), bounds=\(bounds), path=\(path.boundingRect)")
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
        let visibilitySuite = "ReadyCheck.edge-test." + UUID().uuidString
        let visibilityDefaults = try XCTUnwrap(UserDefaults(suiteName: visibilitySuite))
        defer { visibilityDefaults.removePersistentDomain(forName: visibilitySuite) }
        let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
            client: RailTestNotificationClient(), verificationDelays: []), widgetVisibilityDefaults: visibilityDefaults)
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
        waitForBubbleLayout(panel: panel, hostedView: host.view, size: BubbleWidgetPlacement.expandedSize)
        if !NSApp.isActive && !panel.isKeyWindow {
            throw XCTSkip("Pinned-window sizing needs an unlocked foreground session; the panel could not retain keyboard focus.")
        }
        XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.expandedSize)
        XCTAssertEqual(container.view.bounds.size, panel.frame.size)
        XCTAssertEqual(host.view.bounds.size, panel.frame.size)
        let mask = try XCTUnwrap(container.view.layer?.mask)
        XCTAssertGreaterThanOrEqual(mask.contentsScale, panel.backingScaleFactor)
        XCTAssertEqual(mask.rasterizationScale, mask.contentsScale)
        host.rootView.onTogglePin()
        XCTAssertFalse(panel.canBecomeKey)
        host.rootView.onTogglePin()
        XCTAssertTrue(panel.canBecomeKey)
        host.rootView.onCollapse()
        waitForBubbleLayout(panel: panel, hostedView: host.view, size: BubbleWidgetPlacement.tabSize)
        XCTAssertEqual(panel.frame.size, BubbleWidgetPlacement.tabSize)
        XCTAssertEqual(host.view.bounds.size, panel.frame.size)
    }

    private func waitForBubbleLayout(panel: NSWindow, hostedView: NSView, size: CGSize) {
        let deadline = Date().addingTimeInterval(1)
        repeat {
            panel.contentView?.layoutSubtreeIfNeeded()
            if panel.frame.size == size, hostedView.bounds.size == size { return }
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        } while Date() < deadline
    }

    func testBubbleDetailsRetainEveryWindowAndRecoverSavedSelectionAfterRefresh() throws {
        _ = NSApplication.shared
        let previousIcon = NSApp.applicationIconImage
        if let path = ProcessInfo.processInfo.environment["READYCHECK_UI_APP_ICON"], let image = NSImage(contentsOfFile: path) {
            NSApp.applicationIconImage = image
        }
        defer { NSApp.applicationIconImage = previousIcon }
        let keys = ["ReadyCheck.quotaWindowSelection.v2", "ReadyCheck.notchQuotaSelection.v1", "ReadyCheck.quotaWindowLabel.v1", "ReadyCheck.language.v1"]
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
        let hourly = window(id: "hourly", minutes: 300, remaining: 80)
        let extra = window(id: "extra", minutes: 300, remaining: 85, name: "Additional allowance")
        model.notchQuotaSelection = .window(extra.id)
        let view = BubbleWidgetView(model: model, isExpanded: true, tabEdge: nil,
            onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
        for (name, windows, expectedIDs) in [
            ("bubble-extra", [hourly, weekly, extra], [extra.id, hourly.id, weekly.id]),
            ("bubble-weekly", [weekly], [extra.id, weekly.id]),
            ("bubble-empty", [], [extra.id]),
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
                    remainingRatio: 0.91 - drops.prefix(index).reduce(0, +), resetAt: hourly.resetAt)])
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
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            let rail = BubbleWidgetView(model: model, isExpanded: false, tabEdge: edge,
                onTap: {}, onDragChanged: { _ in }, onDragEnded: {}, onCollapse: {})
            let railHost = NSHostingView(rootView: rail)
            railHost.frame = CGRect(origin: .zero, size: BubbleWidgetPlacement.tabSize)
            try capture(railHost, name: "bubble-rail-" + edge.rawValue)
        }
        for remaining: Double in [0, 5, 80, 100] {
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

    func testUnifiedWidgetRefreshKeepsAttachedDetailsAnchoredForEveryQuotaWindow() throws {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let key = "ReadyCheck.bubbleWidgetFrame.v1"
        let saved = defaults.object(forKey: key)
        defer {
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        let visible = try XCTUnwrap(NSScreen.main).visibleFrame
        let hourly = window(id: "codex-primary", minutes: 300, remaining: 80)
        let weekly = window(id: "codex-secondary", minutes: 10_080, remaining: 70)
        let extra = window(id: "extra-primary", minutes: 60, remaining: 85, name: "Extra allowance")
        for edge in [BubbleWidgetPlacement.Edge.left, .right] {
            let tab = BubbleWidgetPlacement.tabFrame(from: CGRect(x: visible.midX, y: visible.midY,
                width: 92, height: 92), edge: edge, in: visible)
            defaults.set(NSStringFromRect(tab), forKey: key)
            let model = ReadyCheckAppModel(quotaNotificationService: QuotaNotificationService(
                client: RailTestNotificationClient(), verificationDelays: []))
            let previous = Set(NSApp.windows.map(\.windowNumber))
            let controller = BubbleWindowController()
            controller.show(model: model)
            defer { controller.close() }
            let panel = try XCTUnwrap(NSApp.windows.first { $0 is QuotaWidgetPanel && !previous.contains($0.windowNumber) })
            let host = try XCTUnwrap(panel.contentViewController?.children.first as? NSHostingController<BubbleWidgetView>)
            host.rootView.onTap()
            RunLoop.main.run(until: Date().addingTimeInterval(0.3))
            let detailFrame = panel.frame
            for windows in [[], [weekly], [hourly, weekly], [hourly, weekly, extra], [weekly]] {
                model.snapshots = [snapshot(windows)]
                RunLoop.main.run(until: Date().addingTimeInterval(0.1))
                XCTAssertEqual(panel.frame, detailFrame)
                XCTAssertEqual(host.rootView.tabEdge, edge)
                XCTAssertTrue(host.rootView.isPinned)
                XCTAssertEqual(host.rootView.expandedWindows.filter { $0.unit != .unknown }.map(\.id).sorted(), windows.map(\.id).sorted())
            }
            host.rootView.onCollapse()
            RunLoop.main.run(until: Date().addingTimeInterval(0.25))
            XCTAssertEqual(panel.frame.size, tab.size)
            XCTAssertEqual(panel.frame.minX, tab.minX, accuracy: 1)
            XCTAssertEqual(panel.frame.midY, tab.midY, accuracy: 1)
        }
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
        let bitmap: NSBitmapImageRep
        if let host = view as? NSHostingView<BubbleWidgetView>, !host.rootView.isExpanded {
            let renderer = ImageRenderer(content: host.rootView.frame(width: view.bounds.width,
                height: view.bounds.height))
            renderer.scale = CGFloat(Double(ProcessInfo.processInfo.environment["READYCHECK_UI_RENDER_SCALE"] ?? "4") ?? 4)
            bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
        } else {
            var fixtureWindow: NSWindow?
            var captureView = view
            if let host = view as? NSHostingView<BubbleWidgetView> {
                let window = NSWindow(contentRect: view.bounds, styleMask: .borderless,
                    backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                let attachedHost = NSHostingView(rootView: host.rootView)
                window.contentView = attachedHost
                attachedHost.frame = view.bounds
                attachedHost.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.1))
                fixtureWindow = window
                captureView = attachedHost
            }
            defer { fixtureWindow?.close() }
            bitmap = try XCTUnwrap(captureView.bitmapImageRepForCachingDisplay(in: captureView.bounds))
            captureView.cacheDisplay(in: captureView.bounds, to: bitmap)
        }
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

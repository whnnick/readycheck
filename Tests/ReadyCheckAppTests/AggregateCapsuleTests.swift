import AppKit
import SwiftUI
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class AggregateCapsuleTests: XCTestCase {
    func testThreeServiceReadingsKeepQuotaBalanceAndStaleStatesDistinct() async throws {
        try await withFixture { model in
            let original = model.selectedService
            await model.refreshService(.deepSeek)
            await model.refreshService(.muse)
            XCTAssertEqual(model.selectedService, original, "Refreshing a side detail cannot switch the main window")
            let now = Date()
            let readings = AggregateServiceSummary.readings(model: model, now: now)
            XCTAssertEqual(readings.map(\.id), [.codex, .deepSeek, .muse])
            XCTAssertEqual(readings[0].value, "82%")
            XCTAssertEqual(readings[0].primaryPeriod, "5h")
            XCTAssertEqual(readings[0].caption, "7d 64%")
            XCTAssertEqual(readings[0].rings.count, 2)
            XCTAssertEqual(readings[1].caption, "CNY")
            XCTAssertFalse(readings[1].value.contains("%"))
            XCTAssertTrue(readings[1].rings.isEmpty, "Currency balance cannot masquerade as quota progress")
            XCTAssertEqual(readings[2].value, "73%")
            for reading in AggregateServiceSummary.readings(model: model, now: now.addingTimeInterval(301)) {
                XCTAssertEqual(reading.value, "—", "Expired reading must not look current: \(reading.title)")
            }
        }
    }

    func testWeeklyOnlyCodexDoesNotInventAFiveHourReading() async throws {
        try await withFixture { model in
            let old = try XCTUnwrap(model.snapshots.first)
            model.snapshots = [ProviderQuotaSnapshot(providerId: old.providerId, displayName: old.displayName, status: old.status,
                source: old.source, refreshedAt: old.refreshedAt, staleAfter: old.staleAfter,
                windows: old.windows.filter { $0.durationMinutes == 10_080 }, errors: [], ordinaryUsageAllowed: true)]
            let reading = try XCTUnwrap(AggregateServiceSummary.readings(model: model, now: Date()).first)
            XCTAssertEqual(reading.value, "64%")
            XCTAssertEqual(reading.primaryPeriod, "7d")
            XCTAssertFalse(reading.caption.contains("5h"))
            XCTAssertEqual(reading.rings.count, 1)
        }
    }

    func testSideDetailsKeepAggregateVisibleAndOnlyExplicitPinPersists() async throws {
        try await withFixture { model in
            let defaults = UserDefaults.standard, key = AggregateCapsuleWindowController.frameKey
            let previous = defaults.object(forKey: key)
            let legacy = defaults.object(forKey: "ReadyCheck.bubbleWidgetFrame.v1") as? String
            let visible = CGRect(x: 0, y: 0, width: 1440, height: 900)
            let controller = AggregateCapsuleWindowController(
                visibleFrameProvider: { _ in visible }, reduceMotionProvider: { true }
            )
            defer { controller.close(); if let previous { defaults.set(previous, forKey: key) } else { defaults.removeObject(forKey: key) } }
            controller.show(model: model)
            let rail = try XCTUnwrap(controller.rail)
            let frame = rail.frame
            XCTAssertEqual(frame.size, AggregateCapsulePlacement.size)
            XCTAssertTrue(rail.canStartDrag(CGPoint(x: frame.width / 2, y: 6)))
            XCTAssertFalse(rail.canStartDrag(CGPoint(x: frame.width / 2, y: 22)), "The menu is outside the drag grip")
            let selection = model.selectedService
            controller.select(.muse)
            XCTAssertTrue(controller.rail?.isVisible == true)
            XCTAssertTrue(controller.detail?.isVisible == true)
            XCTAssertFalse(controller.detail?.allowsKeyboard == true)
            XCTAssertEqual(model.selectedService, selection, "Preview must not change main-window selection")
            controller.togglePin()
            XCTAssertTrue(controller.isPinned)
            controller.dismissFromExternalInteraction()
            XCTAssertTrue(controller.detail?.isVisible == true)
            controller.hover(.deepSeek, inside: true)
            XCTAssertEqual(controller.service, .muse, "Hover cannot change a pinned detail")
            controller.select(.deepSeek)
            XCTAssertTrue(controller.isPinned)
            controller.togglePin(); controller.dismissFromExternalInteraction()
            XCTAssertFalse(controller.detail?.isVisible == true)
            XCTAssertTrue(controller.rail?.isVisible == true)
            XCTAssertEqual(controller.rail?.frame, frame)
            XCTAssertEqual(defaults.string(forKey: "ReadyCheck.bubbleWidgetFrame.v1"), legacy)
            controller.updateFullscreenBehavior(hideInFullscreen: true)
            XCTAssertEqual(controller.rail?.collectionBehavior, WidgetSpaceBehavior.collectionBehavior(hideInFullscreen: true))
            let moved = frame.offsetBy(dx: frame.midX < visible.midX ? 110 : -110, dy: 0)
            controller.rail?.setFrame(moved, display: true)
            controller.finishDrag()
            let movedFrame = try XCTUnwrap(controller.rail).frame
            XCTAssertNotEqual(movedFrame, frame)
            controller.close()
            controller.show(model: model)
            XCTAssertEqual(controller.rail?.frame, movedFrame)
        }
    }

    func testWindowLevelChangesPreservePinningAndPlacement() async throws {
        try await withFixture { model in
            let defaults = UserDefaults.standard
            let key = AggregateCapsuleWindowController.frameKey
            let previous = defaults.object(forKey: key)
            let controller = AggregateCapsuleWindowController(reduceMotionProvider: { true })
            defer {
                controller.close()
                if let previous { defaults.set(previous, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
            controller.show(model: model)
            controller.select(.codex)
            let rail = try XCTUnwrap(controller.rail)
            let detail = try XCTUnwrap(controller.detail)
            let railFrame = rail.frame
            let detailFrame = detail.frame
            controller.updateLevel(alwaysOnTop: false)
            XCTAssertEqual(rail.level, .normal)
            XCTAssertEqual(detail.level, .normal)
            XCTAssertFalse(controller.isPinned)
            controller.togglePin()
            controller.updateLevel(alwaysOnTop: true)
            XCTAssertEqual(rail.level, .floating)
            XCTAssertEqual(detail.level, .floating)
            XCTAssertTrue(controller.isPinned)
            controller.updateLevel(alwaysOnTop: false)
            XCTAssertTrue(controller.isPinned)
            XCTAssertEqual(rail.frame, railFrame)
            XCTAssertEqual(detail.frame, detailFrame)
            controller.togglePin()
            controller.dismissFromExternalInteraction()
            XCTAssertFalse(detail.isVisible)
            XCTAssertTrue(rail.isVisible)
            XCTAssertEqual(rail.frame, railFrame)
        }
    }

    func testLeavingRailChromeDismissesPreviewAfterLeavingAServiceRow() async throws {
        try await withFixture { model in
            let key = AggregateCapsuleWindowController.frameKey
            let previous = UserDefaults.standard.object(forKey: key)
            let pointer = TestPointer()
            let controller = AggregateCapsuleWindowController(
                visibleFrameProvider: { _ in CGRect(x: 0, y: 0, width: 1440, height: 900) },
                pointerLocation: { pointer.location }, reduceMotionProvider: { true }
            )
            defer {
                controller.close()
                UserDefaults.standard.set(previous, forKey: key)
            }
            controller.show(model: model)
            let frame = try XCTUnwrap(controller.rail).frame
            controller.select(.muse)

            pointer.location = CGPoint(x: frame.midX, y: frame.maxY - 19)
            controller.hover(.muse, inside: false)
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertTrue(controller.detail?.isVisible == true, "The pointer is still over the rail header")

            pointer.location = CGPoint(x: frame.midX, y: frame.maxY + 30)
            controller.railPointerExited()
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertFalse(controller.detail?.isVisible == true, "Leaving from the header must start dismissal again")
            XCTAssertTrue(controller.rail?.isVisible == true)
        }
    }

    func testReopeningWhileFadingOutKeepsTheNewPreviewVisible() async throws {
        try await withFixture { model in
            let key = AggregateCapsuleWindowController.frameKey
            let previous = UserDefaults.standard.object(forKey: key)
            let visible = CGRect(x: 0, y: 0, width: 1440, height: 900)
            let controller = AggregateCapsuleWindowController(
                visibleFrameProvider: { _ in visible }, reduceMotionProvider: { false }
            )
            defer {
                controller.close()
                UserDefaults.standard.set(previous, forKey: key)
            }
            controller.show(model: model)
            let railFrame = try XCTUnwrap(controller.rail).frame
            let restingFrame = AggregateCapsulePlacement.detailFrame(beside: railFrame, in: visible)
            controller.select(.codex)
            let detail = try XCTUnwrap(controller.detail)
            XCTAssertTrue(detail.isVisible)
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertEqual(detail.frame, restingFrame)
            XCTAssertEqual(detail.alphaValue, 1, accuracy: 0.01)

            controller.dismissFromExternalInteraction()
            XCTAssertTrue(detail.ignoresMouseEvents, "A fading panel cannot intercept clicks")
            controller.select(.muse)
            XCTAssertEqual(controller.service, .muse)
            XCTAssertFalse(detail.ignoresMouseEvents)
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertTrue(detail.isVisible, "The old dismissal must not hide the reopened panel")
            XCTAssertEqual(detail.alphaValue, 1, accuracy: 0.01)
            XCTAssertEqual(detail.frame, restingFrame)

            controller.dismissFromExternalInteraction()
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertFalse(detail.isVisible)
            XCTAssertTrue(controller.rail?.isVisible == true)
        }
    }

    func testUnavailableScreenDoesNotPersistAZeroSizedCapsule() async throws {
        try await withFixture { model in
            let before = UserDefaults.standard.object(forKey: AggregateCapsuleWindowController.frameKey) as? String
            let controller = AggregateCapsuleWindowController(visibleFrameProvider: { _ in .zero })
            defer { controller.close() }
            controller.show(model: model)
            XCTAssertNil(controller.rail)
            XCTAssertEqual(UserDefaults.standard.string(forKey: AggregateCapsuleWindowController.frameKey), before)
        }
    }

    func testAggregateNativeSurfacesFitBothLanguagesAndAllServiceDetails() async throws {
        try await withFixture { model in
            for language in [AppLanguage.zhCN, .enUS] {
                model.language = language
                try capture(AnyView(AggregateCapsuleView(model: model, selected: .codex, onSelect: { _ in }, onHover: { _, _ in })),
                    size: AggregateCapsulePlacement.size, name: "rail-\(language.rawValue)")
                let pair = HStack(spacing: 10) {
                    AggregateCapsuleDetailView(model: model, service: .codex, isPinned: false, onTogglePin: {}, onHover: { _ in })
                        .frame(width: 360, height: 400)
                    AggregateCapsuleView(model: model, selected: .codex, onSelect: { _ in }, onHover: { _, _ in })
                        .frame(width: 84, height: 392)
                }.padding(8)
                try capture(AnyView(pair), size: CGSize(width: 470, height: 416), name: "overview-\(language.rawValue)")
                for service in ServiceSettingsTarget.allCases {
                    try capture(AnyView(AggregateCapsuleDetailView(model: model, service: service, isPinned: true, onTogglePin: {}, onHover: { _ in })),
                        size: AggregateCapsulePlacement.detailSize, name: "detail-\(service.rawValue)-\(language.rawValue)")
                }
                try capture(AnyView(WidgetPresentationPicker(selection: .constant(.aggregate), localization: model.localization)
                    .background(Color(red: 0.06, green: 0.07, blue: 0.09))),
                    size: CGSize(width: 530, height: 130), name: "picker-\(language.rawValue)")
            }
        }
    }

    @MainActor private final class TestPointer {
        var location = CGPoint.zero
    }

    private func capture(_ view: AnyView, size: CGSize, name: String) throws {
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.appearance = NSAppearance(named: .darkAqua)
        defer { window.close() }
        let host = NSHostingView(rootView: view.environment(\.colorScheme, .dark))
        window.contentView = host; host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        XCTAssertLessThanOrEqual(host.fittingSize.width, size.width + 1, name)
        XCTAssertLessThanOrEqual(host.fittingSize.height, size.height + 1, name)
        guard let output = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else { return }
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: output).appendingPathComponent("aggregate-\(name).png"))
    }

    private func withFixture(_ body: @MainActor (ReadyCheckAppModel) async throws -> Void) async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "aggregate-fixture-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        defaults.set(true, forKey: "ReadyCheck.muse.enabled.v1")
        let store = InMemoryCredentialStore()
        let balance = DeepSeekConnection(store: store, client: DeepSeekBalanceClient(loader: AggregateBalanceLoader()),
            historyStore: DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json")))
        await balance.connect(key: "synthetic")
        let muse = MuseConnection(reader: AggregateMuseReader(), defaults: defaults)
        await muse.refresh()
        let model = ReadyCheckAppModel(credentialStore: store, deepSeekConnection: balance, museConnection: muse,
            deepSeekAlertStore: DeepSeekBalanceAlertStore(fileURL: directory.appendingPathComponent("alerts.json")),
            quotaNotificationService: QuotaNotificationService(client: ClaritySilentNotifications(), verificationDelays: []), widgetVisibilityDefaults: defaults)
        let language = model.language, selected = model.selectedService
        defer { model.language = language; model.selectedService = selected }
        let now = Date()
        let windows = [("primary", 300, 82.0), ("secondary", 10_080, 64.0)].map { id, minutes, remaining in
            QuotaWindow(id: id, labelKey: minutes == 300 ? "quota.window.codex.5h" : "quota.window.codex.7d", kind: .rolling,
                used: 100 - remaining, limit: 100, remaining: remaining, unit: .percent,
                resetAt: now.addingTimeInterval(Double(minutes) * 60), confidence: .verified, durationMinutes: minutes)
        }
        model.snapshots = [ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: .available, source: .appServer,
            refreshedAt: now, staleAfter: now.addingTimeInterval(300), windows: windows, errors: [], ordinaryUsageAllowed: true)]
        try await body(model)
    }
}

private struct AggregateBalanceLoader: HTTPDataLoading {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        (Data(#"{"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"28.60","granted_balance":"3.10","topped_up_balance":"25.50"}]}"#.utf8),
         HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
@MainActor private final class AggregateMuseReader: MuseUsageReading {
    func read() async throws -> MuseUsageSnapshot { try MuseConnectionTests.snapshot() }
    func clearSession() async { }
}

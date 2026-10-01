import AppKit
import SwiftUI
import XCTest
import UserNotifications
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class EdgeRailWidgetTests: XCTestCase {
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
            onHover: { _ in }, onExpand: {}, onToggleDetail: {}, onDragChanged: { _ in }, onDragEnded: {})
        let host = NSHostingView(rootView: detail)
        host.frame = CGRect(x: 0, y: 0, width: EdgeRailPlacement.detailWidth, height: detailHeight)
        try capture(host, name: "extra-detail")
    }

    private func window(id: String, minutes: Int, remaining: Double, name: String? = nil) -> QuotaWindow {
        let label = minutes == 300 ? "quota.window.codex.5h" : minutes == 10_080 ? "quota.window.codex.7d" : "quota.window.dynamic"
        return QuotaWindow(id: id, labelKey: label, displayLabel: name, kind: .rolling,
            used: 100 - remaining, limit: 100, remaining: remaining, unit: .percent,
            resetAt: Date().addingTimeInterval(3600), confidence: .verified, durationMinutes: minutes)
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

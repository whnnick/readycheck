import AppKit
import SwiftUI
import Foundation
import XCTest
import ReadyCheckCore
@testable import ReadyCheckApp

final class NotificationHistoryPresentationTests: XCTestCase {
    private func record(_ id: String, kind: QuotaReminderHistoryKind = .quotaLow,
                        at date: Date? = nil) -> QuotaReminderHistoryRecord {
        QuotaReminderHistoryRecord(id: id, kind: kind, status: .delivered, lastAttemptAt: date)
    }

    func testAllKindsRemainAccessibleAndFiltersDoNotMutateRecords() {
        let kinds: [QuotaReminderHistoryKind] = [.quotaLow, .quotaRecovered, .creditsStarted, .manualResetExpiring, .resetCreditUsed]
        let records = kinds.enumerated().map { record(String($0.offset), kind: $0.element) }
        let original = records
        XCTAssertEqual(NotificationHistoryFilter.all.select(records), records)
        for filter in NotificationHistoryFilter.allCases.dropFirst() {
            XCTAssertEqual(filter.select(records).count, 1)
        }
        XCTAssertEqual(records, original)
        XCTAssertTrue(NotificationHistoryFilter.cardsUsed.select([record("quota")]).isEmpty)
    }

    func testLocalDaysNewestFirstWithUnknownLastAndStableTieOrder() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 28800)!
        let midnight = Date(timeIntervalSince1970: 1793030400) // 2026-10-27 00:00 +08
        let records = [record("unknown"), record("old", at: midnight.addingTimeInterval(-1)),
                       record("b", at: midnight), record("a", at: midnight)]
        let groups = NotificationHistoryPresentation.groups(records, calendar: calendar)
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].records.map(\.id), ["a", "b"])
        XCTAssertEqual(groups[1].records.map(\.id), ["old"])
        XCTAssertNil(groups[2].day)
        XCTAssertEqual(groups[2].records.map(\.id), ["unknown"])
        XCTAssertEqual(groups[0].day, calendar.startOfDay(for: midnight))
    }

    func testReceiptFallbackDoesNotUseExpiryOrInventMissingTime() {
        var receipt = record("receipt")
        receipt.deliveredAt = Date(timeIntervalSince1970: 100)
        receipt.expiresAt = Date(timeIntervalSince1970: 999)
        XCTAssertEqual(NotificationHistoryPresentation.timestamp(receipt), receipt.deliveredAt)
        var expiryOnly = record("legacy")
        expiryOnly.expiresAt = receipt.expiresAt
        XCTAssertNil(NotificationHistoryPresentation.timestamp(expiryOnly))
        receipt.lastAttemptAt = Date(timeIntervalSince1970: 200)
        XCTAssertEqual(NotificationHistoryPresentation.timestamp(receipt), receipt.lastAttemptAt)
    }

    func testDeliveryStatesHaveTheSameMeaningInHistoryAndCardEvidence() {
        var entry = record("notice")
        for (status, key) in [(QuotaReminderDeliveryStatus.delivered, "delivered"), (.failed, "failed"),
                              (.automaticallyWithdrawn, "withdrawn"), (.withdrawalPending, "withdrawalPending"),
                              (.legacyUnknown, "legacyUnknown")] {
            entry.status = status
            XCTAssertEqual(NotificationHistoryPresentation.statusKey(entry), "notification.history." + key)
        }
        entry.status = .legacyUnknown
        entry.submissionAccepted = true
        XCTAssertEqual(NotificationHistoryPresentation.statusKey(entry), "notification.history.submitted")
        entry.status = .delivered
        XCTAssertEqual(NotificationHistoryPresentation.statusKey(entry), "notification.history.delivered")
    }

    func testGroupingUsesSuppliedTimeZoneAndKeepsAllRecords() {
        let instant = Date(timeIntervalSince1970: 1793030400)
        let records = [record("first", at: instant.addingTimeInterval(-1)), record("second", at: instant)]
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        var local = utc
        local.timeZone = TimeZone(secondsFromGMT: 28800)!
        XCTAssertEqual(NotificationHistoryPresentation.groups(records, calendar: utc).count, 1)
        XCTAssertEqual(NotificationHistoryPresentation.groups(records, calendar: local).count, 2)
        XCTAssertEqual(NotificationHistoryPresentation.groups(records, calendar: local).flatMap(\.records).count, records.count)
    }
    @MainActor
    func testBilingualNativeHistoryLayout() async throws {
        guard let path = ProcessInfo.processInfo.environment["READYCHECK_UI_EVIDENCE_DIR"] else {
            throw XCTSkip("Opt-in synthetic native visual evidence")
        }
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        var expiry = record("expiry", kind: .manualResetExpiring, at: Date().addingTimeInterval(-90000))
        expiry.leadHours = 48
        var legacy = record("legacy")
        legacy.status = .legacyUnknown
        let records = [record("recent", at: Date().addingTimeInterval(-180)), expiry, legacy]
        for language in [AppLanguage.zhCN, .enUS] {
            for dark in [false, true] {
                let localization = LocalizationService(language: language)
                let host = NSHostingView(rootView: ScrollView {
                    ReminderHistoryPageView(records: records, localization: localization).padding(20)
                }.frame(width: 520, height: 680)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, dark ? .dark : .light))
                let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 520, height: 680),
                                      styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                window.contentView = host
                host.frame = CGRect(x: 0, y: 0, width: 520, height: 680)
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(300))
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                    .write(to: URL(fileURLWithPath: path).appendingPathComponent("history-\(language.rawValue)-\(dark).png"))
                window.close()
            }
        }
    }

}

import Foundation
import XCTest
@testable import ReadyCheckCore

final class DeepSeekBalanceHistoryTests: XCTestCase {
    func testChangedBalanceWithinFiveMinutesIsRecorded() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DeepSeekBalanceHistoryStore(fileURL: directory.appendingPathComponent("history.json"))
        let id = UUID(), now = Date()
        try await store.record(connectionID: id, observedAt: now.addingTimeInterval(-60),
            balances: [.init(currency: "CNY", total: 10, granted: 0, toppedUp: 10)])
        try await store.record(connectionID: id, observedAt: now,
            balances: [.init(currency: "CNY", total: 9, granted: 0, toppedUp: 9)])
        let items = try await store.load(connectionID: id, now: now)
        XCTAssertEqual(items.map(\.total), [10, 9])
    }

    func testHistoryIsScopedToConnectionAndCurrencyAndSurvivesReload() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("history.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DeepSeekBalanceHistoryStore(fileURL: url)
        let first = UUID(), second = UUID(), now = Date()
        let a = DeepSeekBalance(currency: "CNY", total: 12, granted: 2, toppedUp: 10)
        let b = DeepSeekBalance(currency: "USD", total: 3, granted: 0, toppedUp: 3)
        try await store.record(connectionID: first, observedAt: now, balances: [a, b])
        try await store.record(connectionID: second, observedAt: now, balances: [a])
        let reloaded = DeepSeekBalanceHistoryStore(fileURL: url)
        let firstItems = try await reloaded.load(connectionID: first, now: now)
        let secondItems = try await reloaded.load(connectionID: second, now: now)
        XCTAssertEqual(firstItems.map(\.currency).sorted(), ["CNY", "USD"])
        XCTAssertEqual(secondItems.count, 1)
        XCTAssertEqual(firstItems.first(where: { $0.currency == "CNY" })?.total, 12)
    }

    func testRetentionAndFiveMinuteDeduplication() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DeepSeekBalanceHistoryStore(fileURL: dir.appendingPathComponent("history.json"))
        let id = UUID(), now = Date(), balance = DeepSeekBalance(currency: "CNY", total: 1, granted: 0, toppedUp: 1)
        try await store.record(connectionID: id, observedAt: now.addingTimeInterval(-31 * 86400), balances: [balance])
        try await store.record(connectionID: id, observedAt: now.addingTimeInterval(-60), balances: [balance])
        try await store.record(connectionID: id, observedAt: now, balances: [balance])
        let items = try await store.load(connectionID: id, now: now)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.observedAt, now.addingTimeInterval(-60))
    }

    func testCorruptHistoryIsNotOverwritten() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = dir.appendingPathComponent("history.json")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let data = Data("corrupt".utf8)
        try data.write(to: url)
        let store = DeepSeekBalanceHistoryStore(fileURL: url)
        do { try await store.record(connectionID: UUID(), observedAt: Date(), balances: [.init(currency: "CNY", total: 1, granted: 0, toppedUp: 1)]); XCTFail("must not overwrite unreadable history") } catch { }
        XCTAssertEqual(try Data(contentsOf: url), data)
    }
}

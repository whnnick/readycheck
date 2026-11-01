import Foundation
import XCTest
@testable import ReadyCheckCore

final class DeepSeekBalanceAlertTests: XCTestCase {
    func testThresholdsAreIsolatedAndDeliveryIsDeduplicatedUntilRecovery() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json"))
        let a = UUID(), b = UUID()
        try await store.configure(connectionID: a, currency: "CNY", threshold: 10, enabled: true)
        let otherConnection = try await store.evaluate(connectionID: b, currency: "CNY", total: 2)
        let otherCurrency = try await store.evaluate(connectionID: a, currency: "USD", total: 2)
        XCTAssertNil(otherConnection)
        XCTAssertNil(otherCurrency)
        let candidate = try await store.evaluate(connectionID: a, currency: "CNY", total: 5)
        let event = try XCTUnwrap(candidate)
        XCTAssertEqual(event.threshold, 10)
        try await store.markDelivered(event)
        let duplicate = try await store.evaluate(connectionID: a, currency: "CNY", total: 4)
        let recovered = try await store.evaluate(connectionID: a, currency: "CNY", total: 11)
        let nextCandidate = try await store.evaluate(connectionID: a, currency: "CNY", total: 9)
        XCTAssertNil(duplicate)
        XCTAssertNil(recovered)
        let next = try XCTUnwrap(nextCandidate)
        XCTAssertNotEqual(event.id, next.id)
    }

    func testUnverifiedNewCycleDoesNotReuseEarlierDeliveryTime() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DeepSeekBalanceAlertStore(fileURL: dir.appendingPathComponent("alerts.json")), id = UUID()
        try await store.configure(connectionID: id, currency: "CNY", threshold: 10, enabled: true)
        let firstCandidate = try await store.evaluate(connectionID: id, currency: "CNY", total: 5)
        let first = try XCTUnwrap(firstCandidate)
        try await store.markSubmitted(first)
        try await store.markDelivered(first)
        _ = try await store.evaluate(connectionID: id, currency: "CNY", total: 11)
        let nextCandidate = try await store.evaluate(connectionID: id, currency: "CNY", total: 9)
        let next = try XCTUnwrap(nextCandidate)
        try await store.markSubmitted(next)
        let rules = try await store.rules(connectionID: id)
        XCTAssertNotNil(rules.first?.lastSubmittedAt)
        XCTAssertNil(rules.first?.lastDeliveredAt, "The previous cycle cannot prove delivery of the new alert")
    }

    func testAcceptedButUnverifiedSubmissionDoesNotRepeatAcrossRestart() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("alerts.json"), id = UUID()
        let store = DeepSeekBalanceAlertStore(fileURL: url)
        try await store.configure(connectionID: id, currency: "CNY", threshold: 10, enabled: true)
        let candidate = try await store.evaluate(connectionID: id, currency: "CNY", total: 5)
        let alert = try XCTUnwrap(candidate)
        try await store.markSubmitted(alert)
        let reloaded = DeepSeekBalanceAlertStore(fileURL: url)
        let repeated = try await reloaded.evaluate(connectionID: id, currency: "CNY", total: 4)
        XCTAssertNil(repeated)
        let rules = try await reloaded.rules(connectionID: id)
        XCTAssertNotNil(rules.first?.lastSubmittedAt)
        XCTAssertNil(rules.first?.lastDeliveredAt)
    }

    func testDisabledOrChangedRuleCannotMarkOldDeliveryAndCorruptFileIsPreserved() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("alerts.json"), id = UUID()
        let store = DeepSeekBalanceAlertStore(fileURL: url)
        try await store.configure(connectionID: id, currency: "USD", threshold: 3, enabled: true)
        let oldCandidate = try await store.evaluate(connectionID: id, currency: "USD", total: 2)
        let old = try XCTUnwrap(oldCandidate)
        try await store.configure(connectionID: id, currency: "USD", threshold: 5, enabled: true)
        try await store.markDelivered(old)
        let changed = try await store.evaluate(connectionID: id, currency: "USD", total: 2)
        XCTAssertNotNil(changed)
        try Data("bad".utf8).write(to: url)
        do { try await store.configure(connectionID: id, currency: "USD", threshold: 2, enabled: true); XCTFail("must preserve corrupt file") } catch { }
        XCTAssertEqual(try Data(contentsOf: url), Data("bad".utf8))
    }
}

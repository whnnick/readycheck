import Foundation
import XCTest
@testable import ReadyCheckCore

final class DeepSeekConsumptionTests: XCTestCase {
    func testDecreaseIsDecimalCurrencyAndRechargeIsNotNegativeConsumption() {
        let id = UUID(), start = Date(timeIntervalSince1970: 1_800_000_000)
        let readings = [
            reading(id, start, total: 10),
            reading(id, start.addingTimeInterval(60), total: Decimal(string: "9.9999")!),
            reading(id, start.addingTimeInterval(120), total: 20),
            reading(id, start.addingTimeInterval(180), total: Decimal(string: "19.9")!)
        ]
        let bins = DeepSeekBalanceConsumption.buckets(observations: readings, connectionID: id, currency: "CNY",
            range: start...start.addingTimeInterval(600), interval: 300)
        XCTAssertEqual(bins.count, 2)
        XCTAssertEqual(bins[0].decrease, Decimal(string: "0.1001"))
        XCTAssertNil(bins[1].decrease)
    }

    func testGapsCurrenciesAndOtherConnectionsAreNotMixed() {
        let id = UUID(), start = Date(timeIntervalSince1970: 1_800_000_000)
        let readings = [
            reading(id, start, total: 10),
            reading(UUID(), start.addingTimeInterval(60), total: 0),
            reading(id, start.addingTimeInterval(90), total: 2, currency: "USD"),
            reading(id, start.addingTimeInterval(900), total: 9)
        ]
        let bins = DeepSeekBalanceConsumption.buckets(observations: readings, connectionID: id, currency: "CNY",
            range: start...start.addingTimeInterval(1800), interval: 300)
        XCTAssertTrue(bins.allSatisfy { $0.decrease == nil })
    }

    func testObservedNoChangeIsZeroButMissingHistoryIsUnknown() {
        let id = UUID(), start = Date(timeIntervalSince1970: 1_800_000_000)
        let bins = DeepSeekBalanceConsumption.buckets(observations: [
            reading(id, start, total: 10), reading(id, start.addingTimeInterval(300), total: 10)
        ], connectionID: id, currency: "CNY", range: start...start.addingTimeInterval(900), interval: 300)
        XCTAssertNil(bins[0].decrease)
        XCTAssertEqual(bins[1].decrease, 0)
        XCTAssertNil(bins[2].decrease)
    }

    private func reading(_ id: UUID, _ date: Date, total: Decimal, currency: String = "CNY") -> DeepSeekBalanceObservation {
        .init(connectionID: id, observedAt: date, currency: currency, total: total, granted: 0, toppedUp: total)
    }
}

import Foundation
import ReadyCheckCore

enum ServiceConnectionMethod: String, CaseIterable {
    case oauth, apiKey
    var title: String { self == .oauth ? "OAuth" : "API Key" }
}

enum ServiceReadoutKind { case quota, balance }

struct ServicePresentation: Equatable {
    let connectionMethod: ServiceConnectionMethod
    let readoutKind: ServiceReadoutKind
}

extension ServiceSettingsTarget {
    var presentation: ServicePresentation {
        switch self {
        case .codex: .init(connectionMethod: .oauth, readoutKind: .quota)
        case .deepSeek: .init(connectionMethod: .apiKey, readoutKind: .balance)
        }
    }
}

extension ReadyCheckAppModel {
    var selectedService: ServiceSettingsTarget { selectedDeepSeek ? .deepSeek : .codex }
}

struct BalanceSurfaceReading: Identifiable, Equatable {
    let currency: String
    let total: Decimal
    let granted: Decimal?
    let toppedUp: Decimal?
    let values: [Decimal?]
    let observedAt: Date?
    let isStale: Bool
    var id: String { currency }
    var observedDecrease: Decimal? {
        let known = values.compactMap { $0 }
        return known.isEmpty ? nil : known.reduce(0, +)
    }
    var chartValues: [Double?] { values.map { $0.map { NSDecimalNumber(decimal: $0).doubleValue } } }
    static func amount(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(2...8)))
    }
}

extension DeepSeekDisplay {
    static func buckets(connection: DeepSeekConnection, currency: String, now: Date) -> [DeepSeekConsumptionBucket] {
        guard let id = connection.connectionID, !connection.historyError else { return [] }
        let end = max(now, connection.observedAt ?? now)
        return DeepSeekBalanceConsumption.buckets(observations: connection.history, connectionID: id,
            currency: currency, range: end.addingTimeInterval(-3600)...end, interval: 300)
    }

    static func readings(connection: DeepSeekConnection, now: Date) -> [BalanceSurfaceReading] {
        let end = max(now, connection.observedAt ?? now)
        let stale = DeepSeekReadingStatus.isStale(observedAt: connection.observedAt,
            hasError: connection.error != nil || connection.credentialError, now: now)
        return (connection.snapshot?.balances ?? []).map { balance in
            let buckets = buckets(connection: connection, currency: balance.currency, now: end)
            return BalanceSurfaceReading(currency: balance.currency, total: balance.total,
                granted: balance.granted, toppedUp: balance.toppedUp,
                values: connection.historyError ? Array(repeating: nil, count: 12) : buckets.map(\.decrease),
                observedAt: connection.observedAt, isStale: stale)
        }
    }
}

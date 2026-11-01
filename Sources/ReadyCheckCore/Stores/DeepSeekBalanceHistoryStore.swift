import Foundation

public struct DeepSeekBalanceObservation: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(connectionID.uuidString)-\(currency)-\(observedAt.timeIntervalSince1970)" }
    public let connectionID: UUID
    public let observedAt: Date
    public let currency: String
    public let total: Decimal
    public let granted: Decimal
    public let toppedUp: Decimal
}

public actor DeepSeekBalanceHistoryStore {
    private let fileURL: URL
    private let retention: TimeInterval = 30 * 24 * 60 * 60
    private let minimumInterval: TimeInterval = 5 * 60

    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load(connectionID: UUID, now: Date = Date()) throws -> [DeepSeekBalanceObservation] {
        try read().filter { $0.connectionID == connectionID && $0.observedAt >= now.addingTimeInterval(-retention) && $0.observedAt <= now }
            .sorted { $0.observedAt < $1.observedAt }
    }

    public func record(connectionID: UUID, observedAt: Date, balances: [DeepSeekBalance]) throws {
        var observations = try read().filter { $0.observedAt >= observedAt.addingTimeInterval(-retention) }
        for balance in balances {
            let last = observations.filter { $0.connectionID == connectionID && $0.currency == balance.currency }.max { $0.observedAt < $1.observedAt }
            if let last {
                guard observedAt > last.observedAt else { continue }
                if observedAt.timeIntervalSince(last.observedAt) < minimumInterval,
                   last.total == balance.total, last.granted == balance.granted,
                   last.toppedUp == balance.toppedUp { continue }
            }
            observations.append(.init(connectionID: connectionID, observedAt: observedAt, currency: balance.currency,
                                      total: balance.total, granted: balance.granted, toppedUp: balance.toppedUp))
        }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let data = try JSONEncoder().encode(observations)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    private func read() throws -> [DeepSeekBalanceObservation] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([DeepSeekBalanceObservation].self, from: Data(contentsOf: fileURL))
    }
}

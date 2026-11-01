import Foundation

public struct DeepSeekBalanceAlertRule: Codable, Equatable, Sendable {
    public let connectionID: UUID
    public let currency: String
    public let threshold: Decimal
    public let enabled: Bool
    public fileprivate(set) var lastSubmittedAt: Date?
    public fileprivate(set) var lastDeliveredAt: Date?
    fileprivate var submitted: Bool?
    fileprivate var cycle: UUID
    fileprivate var delivered: Bool
}

public struct DeepSeekBalanceAlert: Equatable, Sendable {
    public let connectionID: UUID
    public let currency: String
    public let threshold: Decimal
    public let total: Decimal
    public let id: UUID
}

public enum DeepSeekBalanceAlertStoreError: Error { case invalidRule }

public actor DeepSeekBalanceAlertStore {
    private let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func rules(connectionID: UUID) throws -> [DeepSeekBalanceAlertRule] {
        try read().filter { $0.connectionID == connectionID }
    }

    public func configure(connectionID: UUID, currency: String, threshold: Decimal, enabled: Bool) throws {
        guard ["CNY", "USD"].contains(currency), !threshold.isNaN, threshold >= 0 else { throw DeepSeekBalanceAlertStoreError.invalidRule }
        var rules = try read()
        let index = rules.firstIndex { $0.connectionID == connectionID && $0.currency == currency }
        if let index, rules[index].threshold == threshold && rules[index].enabled == enabled { return }
        let rule = DeepSeekBalanceAlertRule(connectionID: connectionID, currency: currency, threshold: threshold,
                                            enabled: enabled, lastSubmittedAt: nil, lastDeliveredAt: nil, submitted: false, cycle: UUID(), delivered: false)
        if let index { rules[index] = rule } else { rules.append(rule) }
        try write(rules)
    }

    public func evaluate(connectionID: UUID, currency: String, total: Decimal) throws -> DeepSeekBalanceAlert? {
        guard !total.isNaN, total >= 0 else { return nil }
        var rules = try read()
        guard let index = rules.firstIndex(where: { $0.connectionID == connectionID && $0.currency == currency && $0.enabled }) else { return nil }
        if total > rules[index].threshold {
            if rules[index].delivered || rules[index].submitted == true {
                rules[index].delivered = false
                rules[index].submitted = false
                rules[index].cycle = UUID()
                try write(rules)
            }
            return nil
        }
        guard !rules[index].delivered && rules[index].submitted != true else { return nil }
        return DeepSeekBalanceAlert(connectionID: connectionID, currency: currency, threshold: rules[index].threshold, total: total, id: rules[index].cycle)
    }

    public func isActive(_ alert: DeepSeekBalanceAlert) throws -> Bool {
        try read().contains { $0.connectionID == alert.connectionID && $0.currency == alert.currency && $0.enabled && !$0.delivered && $0.submitted != true && $0.cycle == alert.id && $0.threshold == alert.threshold }
    }

    public func markSubmitted(_ alert: DeepSeekBalanceAlert) throws {
        var rules = try read()
        guard let index = rules.firstIndex(where: { $0.connectionID == alert.connectionID && $0.currency == alert.currency && $0.enabled && !$0.delivered && $0.cycle == alert.id && $0.threshold == alert.threshold }) else { return }
        rules[index].submitted = true
        rules[index].lastSubmittedAt = Date()
        rules[index].lastDeliveredAt = nil
        try write(rules)
    }

    public func markDelivered(_ alert: DeepSeekBalanceAlert) throws {
        var rules = try read()
        guard let index = rules.firstIndex(where: { $0.connectionID == alert.connectionID && $0.currency == alert.currency && $0.enabled && !$0.delivered && $0.cycle == alert.id && $0.threshold == alert.threshold }) else { return }
        rules[index].delivered = true
        rules[index].lastDeliveredAt = Date()
        try write(rules)
    }

    private func read() throws -> [DeepSeekBalanceAlertRule] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([DeepSeekBalanceAlertRule].self, from: Data(contentsOf: fileURL))
    }

    private func write(_ rules: [DeepSeekBalanceAlertRule]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(rules).write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}

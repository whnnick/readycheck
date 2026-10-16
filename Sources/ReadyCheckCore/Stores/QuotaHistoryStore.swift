import Foundation
import CryptoKit

public struct QuotaHistoryValue: Codable, Equatable, Sendable {
    public let windowID: String
    public let labelKey: String
    public let displayLabel: String?
    public let remainingRatio: Double
    public let resetAt: Date?

    public init(
        windowID: String,
        labelKey: String,
        displayLabel: String? = nil,
        remainingRatio: Double,
        resetAt: Date?
    ) {
        self.windowID = windowID
        self.labelKey = labelKey
        self.displayLabel = displayLabel
        self.remainingRatio = remainingRatio
        self.resetAt = resetAt
    }
}

public struct QuotaHistorySample: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\(providerID)-\(accountKey ?? "unowned")-\(recordedAt.timeIntervalSince1970)" }
    public let providerID: String
    public let accountKey: String?
    public let recordedAt: Date
    public let values: [QuotaHistoryValue]

    public init(providerID: String, recordedAt: Date, values: [QuotaHistoryValue], accountKey: String? = nil) {
        self.providerID = providerID
        self.accountKey = accountKey
        self.recordedAt = recordedAt
        self.values = values
    }

    public init?(snapshot: ProviderQuotaSnapshot) {
        guard snapshot.status == .available, snapshot.isCached != true,
              let accountKey = Self.key(for: snapshot.accountID) else { return nil }
        let values = snapshot.windows.compactMap { window -> QuotaHistoryValue? in
            guard window.confidence == .verified, let ratio = window.remainingRatio else { return nil }
            return QuotaHistoryValue(
                windowID: window.id,
                labelKey: window.labelKey,
                displayLabel: window.displayLabel,
                remainingRatio: ratio,
                resetAt: window.resetAt
            )
        }
        guard !values.isEmpty else { return nil }
        self.init(providerID: snapshot.providerId, recordedAt: snapshot.refreshedAt, values: values, accountKey: accountKey)
    }
    static func key(for accountID: String?) -> String? {
        guard let value = accountID?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

public actor QuotaHistoryStore {
    private let fileURL: URL
    private let legacyFileURL: URL?
    private let retention: TimeInterval
    private let minimumSampleInterval: TimeInterval
    private let now: @Sendable () -> Date

    public init(
        fileURL: URL,
        legacyFileURL: URL? = nil,
        retention: TimeInterval = 30 * 24 * 60 * 60,
        minimumSampleInterval: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.legacyFileURL = legacyFileURL
        self.retention = retention
        self.minimumSampleInterval = minimumSampleInterval
        self.now = now
    }

    public func hasUnassignedLegacyHistory() -> Bool {
        guard let legacyFileURL else { return false }
        return FileManager.default.fileExists(atPath: legacyFileURL.path)
    }

    public func load(accountID: String? = nil) -> [QuotaHistorySample] {
        guard let key = QuotaHistorySample.key(for: accountID), let samples = try? loadAll() else { return [] }
        return retained(samples).filter { $0.accountKey == key }
    }

    @discardableResult
    public func record(_ snapshot: ProviderQuotaSnapshot) -> [QuotaHistorySample] {
        guard !snapshot.isStale(now: now()), let sample = QuotaHistorySample(snapshot: snapshot) else {
            return load(accountID: snapshot.accountID)
        }
        do {
            // Keep the original file usable by the previous version. Never infer its account owner.
            try preserveLegacyFile()
            var samples = retained(try loadAll())
            let sameOwner: (QuotaHistorySample) -> Bool = {
                $0.providerID == sample.providerID && $0.accountKey == sample.accountKey
            }
            // A late/out-of-order refresh must not erase newer account history.
            if let latest = samples.last(where: sameOwner), latest.recordedAt > sample.recordedAt {
                return samples.filter { $0.accountKey == sample.accountKey }
            }
            if let lastIndex = samples.lastIndex(where: sameOwner),
               sampleBucket(sample.recordedAt) == sampleBucket(samples[lastIndex].recordedAt) {
                samples[lastIndex] = sample
            } else {
                samples.append(sample)
            }
            samples.sort { $0.recordedAt < $1.recordedAt }
            try save(samples)
            return samples.filter { $0.accountKey == sample.accountKey }
        } catch {
            // Preserve unreadable files rather than replacing them with an empty history.
            return load(accountID: snapshot.accountID)
        }
    }

    private func loadAll() throws -> [QuotaHistorySample] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([QuotaHistorySample].self, from: Data(contentsOf: fileURL))
    }

    private func preserveLegacyFile() throws {
        guard let legacyFileURL, FileManager.default.fileExists(atPath: legacyFileURL.path) else { return }
        let backup = legacyFileURL.appendingPathExtension("legacy-backup")
        if !FileManager.default.fileExists(atPath: backup.path) {
            try FileManager.default.copyItem(at: legacyFileURL, to: backup)
        }
    }

    private func sampleBucket(_ date: Date) -> Int64 {
        let interval = max(minimumSampleInterval, 1)
        return Int64(floor(date.timeIntervalSince1970 / interval))
    }

    private func retained(_ samples: [QuotaHistorySample]) -> [QuotaHistorySample] {
        let cutoff = now().addingTimeInterval(-retention)
        return samples.filter { $0.recordedAt >= cutoff }
    }

    private func save(_ samples: [QuotaHistorySample]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(samples).write(to: fileURL, options: .atomic)
    }
}

import Foundation

public struct QuotaHistoryValue: Codable, Equatable, Sendable {
    public let windowID: String
    public let labelKey: String
    public let remainingRatio: Double
    public let resetAt: Date?

    public init(windowID: String, labelKey: String, remainingRatio: Double, resetAt: Date?) {
        self.windowID = windowID
        self.labelKey = labelKey
        self.remainingRatio = remainingRatio
        self.resetAt = resetAt
    }
}

public struct QuotaHistorySample: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\(providerID)-\(recordedAt.timeIntervalSince1970)" }
    public let providerID: String
    public let recordedAt: Date
    public let values: [QuotaHistoryValue]

    public init(providerID: String, recordedAt: Date, values: [QuotaHistoryValue]) {
        self.providerID = providerID
        self.recordedAt = recordedAt
        self.values = values
    }

    public init?(snapshot: ProviderQuotaSnapshot) {
        guard snapshot.status == .available else { return nil }
        let values = snapshot.windows.compactMap { window -> QuotaHistoryValue? in
            guard let ratio = window.remainingRatio else { return nil }
            return QuotaHistoryValue(
                windowID: window.id,
                labelKey: window.labelKey,
                remainingRatio: ratio,
                resetAt: window.resetAt
            )
        }
        guard !values.isEmpty else { return nil }
        self.init(providerID: snapshot.providerId, recordedAt: snapshot.refreshedAt, values: values)
    }
}

public actor QuotaHistoryStore {
    private let fileURL: URL
    private let retention: TimeInterval
    private let minimumSampleInterval: TimeInterval
    private let now: @Sendable () -> Date

    public init(
        fileURL: URL,
        retention: TimeInterval = 30 * 24 * 60 * 60,
        minimumSampleInterval: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.retention = retention
        self.minimumSampleInterval = minimumSampleInterval
        self.now = now
    }

    public func load() -> [QuotaHistorySample] {
        guard let data = try? Data(contentsOf: fileURL),
              let samples = try? JSONDecoder().decode([QuotaHistorySample].self, from: data)
        else {
            return []
        }
        return retained(samples)
    }

    @discardableResult
    public func record(_ snapshot: ProviderQuotaSnapshot) -> [QuotaHistorySample] {
        guard let sample = QuotaHistorySample(snapshot: snapshot) else {
            return load()
        }

        var samples = load().filter { $0.providerID != sample.providerID || $0.recordedAt <= sample.recordedAt }
        if let lastIndex = samples.lastIndex(where: { $0.providerID == sample.providerID }),
           sampleBucket(sample.recordedAt) == sampleBucket(samples[lastIndex].recordedAt) {
            samples[lastIndex] = sample
        } else {
            samples.append(sample)
        }
        samples = retained(samples).sorted { $0.recordedAt < $1.recordedAt }
        save(samples)
        return samples
    }

    private func sampleBucket(_ date: Date) -> Int64 {
        let interval = max(minimumSampleInterval, 1)
        return Int64(floor(date.timeIntervalSince1970 / interval))
    }

    private func retained(_ samples: [QuotaHistorySample]) -> [QuotaHistorySample] {
        let cutoff = now().addingTimeInterval(-retention)
        return samples.filter { $0.recordedAt >= cutoff }
    }

    private func save(_ samples: [QuotaHistorySample]) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(samples)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // History is optional product data; quota refresh remains usable if persistence fails.
        }
    }
}

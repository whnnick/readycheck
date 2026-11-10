import Foundation

/// Muse's personal-agent subscription (muse.ai), distinct from Muse Code and Meta API billing.
public struct MuseUsageSnapshot: Equatable, Sendable {
    public let usedPercent: Double
    public let resetsAt: Date?
    public let plan: String?
    public let usageLabel: String?
    public let additionalLabel: String?
    public let renewsAt: Date?

    public var remainingRatio: Double { 1 - usedPercent / 100 }

    public func isCurrent(observedAt: Date, now: Date) -> Bool {
        (0...300).contains(now.timeIntervalSince(observedAt)) && (resetsAt.map { $0 > now } ?? true)
    }
}

public enum MuseUsageError: Error, Equatable, Sendable {
    case loginRequired, network, timedOut, responseChanged
}

public enum MuseUsageParser {
    /// Decode only the subscription row from the website's React Flight response.
    public static func parse(_ data: Data) throws -> MuseUsageSnapshot {
        guard data.count <= 524_288, let text = String(data: data, encoding: .utf8) else {
            throw MuseUsageError.responseChanged
        }
        var result: MuseUsageSnapshot?
        for line in text.split(separator: "\n") {
            guard let colon = line.firstIndex(of: ":"),
                  line[..<colon].range(of: "^[0-9a-f]+$", options: .regularExpression) != nil,
                  let row = try? JSONDecoder().decode(Row.self, from: Data(line[line.index(after: colon)...].utf8)),
                  row.success, let sub = row.subscription else { continue }
            guard result == nil, sub.usage.percentUsed.isFinite, (0...100).contains(sub.usage.percentUsed) else {
                throw MuseUsageError.responseChanged
            }
            result = MuseUsageSnapshot(usedPercent: sub.usage.percentUsed, resetsAt: date(sub.usage.resetsAt),
                plan: label(sub.tier?.name), usageLabel: label(sub.usageRowValueLabel),
                additionalLabel: label(sub.topupRowValueLabel), renewsAt: date(sub.agreement?.currentPeriodEndTime))
        }
        guard let result else { throw MuseUsageError.responseChanged }
        return result
    }

    private static func label(_ value: String?) -> String? {
        guard let value else { return nil }
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 256, !clean.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else { return nil }
        return clean
    }

    private static func date(_ seconds: Double?) -> Date? {
        guard let seconds, seconds.isFinite, (1...253_402_300_799).contains(seconds) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    private struct Row: Decodable { let success: Bool; let subscription: Subscription? }
    private struct Subscription: Decodable {
        let tier: Tier?
        let usage: Usage
        let usageRowValueLabel: String?
        let topupRowValueLabel: String?
        let agreement: Agreement?
    }
    private struct Tier: Decodable { let name: String? }
    private struct Usage: Decodable { let percentUsed: Double; let resetsAt: Double? }
    private struct Agreement: Decodable { let currentPeriodEndTime: Double? }
}

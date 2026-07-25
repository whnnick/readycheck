import Foundation

public struct CodexUsageParser: Sendable {
    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    public func parse(_ data: Data, refreshedAt: Date) throws -> [QuotaWindow] {
        let payload = try JSONDecoder().decode(CodexUsagePayload.self, from: data)
        let windows = [
            makeWindow(payload.rateLimit?.primaryWindow, id: "codex-primary", fallbackLabelKey: "quota.window.codex.primary", refreshedAt: refreshedAt),
            makeWindow(payload.rateLimit?.secondaryWindow, id: "codex-secondary", fallbackLabelKey: "quota.window.codex.secondary", refreshedAt: refreshedAt)
        ].compactMap { $0 }

        guard !windows.isEmpty else {
            throw CodexUsageParserError.noDisplayableWindows
        }

        return windows
    }

    public func parseManualResetDetails(_ data: Data) -> ProviderQuotaDetails {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any]
        else {
            return ProviderQuotaDetails()
        }

        return ProviderQuotaDetails(
            manualResetCount: firstInt(
                in: root,
                paths: [
                    ["available_count"],
                    ["manual_reset_count"],
                    ["manual_resets_count"],
                    ["manual_resets"],
                    ["manual_reset_expirations"],
                    ["rate_limit_reset_credits", "available_count"],
                    ["rate_limit", "manual_reset_count"],
                    ["rate_limit", "manual_resets_count"],
                    ["rate_limit", "manual_resets"],
                    ["rate_limit", "manual_reset_expirations"]
                ]
            ),
            manualResetExpirations: firstDateArray(
                in: root,
                paths: [
                    ["manual_reset_expires_at"],
                    ["manual_reset_expire_at"],
                    ["manual_reset_expirations"],
                    ["credits"],
                    ["manual_resets", "expires_at"],
                    ["rate_limit", "manual_reset_expires_at"],
                    ["rate_limit", "manual_reset_expire_at"],
                    ["rate_limit", "manual_reset_expirations"],
                    ["rate_limit", "manual_resets", "expires_at"]
                ]
            ),
            creditBalance: creditBalance(in: root),
            creditsUnlimited: creditsUnlimited(in: root)
        )
    }

    private func makeWindow(
        _ payload: CodexUsageWindowPayload?,
        id: String,
        fallbackLabelKey: String,
        refreshedAt: Date
    ) -> QuotaWindow? {
        guard let payload,
              let usedPercent = payload.usedPercent,
              usedPercent.isFinite
        else {
            return nil
        }

        let used = min(max(usedPercent, 0), 100)
        let remaining = max(0, 100 - used)
        let resetAt = resetDate(from: payload, refreshedAt: refreshedAt)

        return QuotaWindow(
            id: id,
            labelKey: labelKey(for: payload.limitWindowSeconds, fallback: fallbackLabelKey),
            kind: .rolling,
            used: used,
            limit: 100,
            remaining: remaining,
            unit: .percent,
            resetAt: resetAt,
            confidence: .verified
        )
    }

    private func resetDate(from payload: CodexUsageWindowPayload, refreshedAt: Date) -> Date? {
        if let resetAt = payload.resetAt, resetAt.isFinite {
            let seconds = resetAt > 1_000_000_000_000 ? resetAt / 1_000 : resetAt
            return Date(timeIntervalSince1970: seconds)
        }

        if let resetAfterSeconds = payload.resetAfterSeconds, resetAfterSeconds.isFinite {
            return refreshedAt.addingTimeInterval(resetAfterSeconds)
        }

        return nil
    }

    private func firstInt(in root: [String: Any], paths: [[String]]) -> Int? {
        for path in paths {
            guard let value = value(in: root, path: path) else { continue }
            if let int = int(from: value) {
                return int
            }
        }
        return nil
    }

    private func firstDateArray(in root: [String: Any], paths: [[String]]) -> [Date] {
        for path in paths {
            guard let value = value(in: root, path: path) else { continue }
            let dates = dates(from: value)
            if !dates.isEmpty {
                return dates
            }
        }
        return []
    }

    private func creditBalance(in root: [String: Any]) -> String? {
        guard let credits = root["credits"] as? [String: Any],
              let value = credits["balance"]
        else {
            return nil
        }

        let raw: String
        if let string = value as? String {
            raw = string.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let number = value as? NSNumber {
            guard CFGetTypeID(number) != CFBooleanGetTypeID() else {
                return nil
            }
            raw = number.stringValue
        } else {
            return nil
        }

        guard !raw.isEmpty,
              let decimal = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")),
              decimal >= 0
        else {
            return nil
        }

        return NSDecimalNumber(decimal: decimal).stringValue
    }

    private func creditsUnlimited(in root: [String: Any]) -> Bool? {
        guard let credits = root["credits"] as? [String: Any],
              let value = credits["unlimited"]
        else {
            return nil
        }

        if let bool = value as? Bool {
            return bool
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1":
                return true
            case "false", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    private func value(in root: [String: Any], path: [String]) -> Any? {
        var current: Any = root
        for key in path {
            if let dictionary = current as? [String: Any] {
                guard let next = dictionary[key] else { return nil }
                current = next
            } else if let array = current as? [[String: Any]] {
                current = array.compactMap { $0[key] }
            } else {
                return nil
            }
        }
        return current
    }

    private func int(from value: Any) -> Int? {
        if let int = value as? Int {
            return int >= 0 ? int : nil
        }
        if let number = value as? NSNumber {
            let int = number.intValue
            return int >= 0 ? int : nil
        }
        if let string = value as? String, let int = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return int >= 0 ? int : nil
        }
        if let array = value as? [Any] {
            return array.count
        }
        return nil
    }

    private func dates(from value: Any) -> [Date] {
        if let array = value as? [[String: Any]] {
            return array.compactMap { dictionary in
                if let resetType = string(from: dictionary["reset_type"] ?? dictionary["resetType"]),
                   resetType != "codex_rate_limits" {
                    return nil
                }
                if let status = string(from: dictionary["status"]),
                   status != "available" {
                    return nil
                }
                return dictionary["expires_at"].flatMap(date(from:))
                    ?? dictionary["expire_at"].flatMap(date(from:))
                    ?? dictionary["expiresAt"].flatMap(date(from:))
                    ?? dictionary["expireAt"].flatMap(date(from:))
                    ?? dictionary["reset_at"].flatMap(date(from:))
            }
        }
        if let array = value as? [Any] {
            return array.compactMap(date(from:))
        }
        if let date = date(from: value) {
            return [date]
        }
        return []
    }

    private func date(from value: Any) -> Date? {
        if let number = value as? NSNumber {
            let raw = number.doubleValue
            guard raw.isFinite, raw > 0 else { return nil }
            let seconds = raw > 1_000_000_000_000 ? raw / 1_000 : raw
            return Date(timeIntervalSince1970: seconds)
        }
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            if let raw = Double(trimmed), raw.isFinite, raw > 0 {
                let seconds = raw > 1_000_000_000_000 ? raw / 1_000 : raw
                return Date(timeIntervalSince1970: seconds)
            }
            if let date = ISO8601DateFormatter().date(from: trimmed) {
                return date
            }
            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractionalFormatter.date(from: trimmed) {
                return date
            }
            return fixedWidthFractionalISO8601Date(from: trimmed)
        }
        return nil
    }

    private func fixedWidthFractionalISO8601Date(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private func string(from value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private func labelKey(for seconds: Double?, fallback: String) -> String {
        guard let seconds, seconds.isFinite else {
            return fallback
        }

        if abs(seconds - 18_000) <= 60 {
            return "quota.window.codex.5h"
        }
        if abs(seconds - 604_800) <= 3_600 {
            return "quota.window.codex.7d"
        }

        return fallback
    }
}

public enum CodexUsageParserError: Error, Equatable, Sendable {
    case noDisplayableWindows
}

private struct CodexUsagePayload: Decodable {
    let rateLimit: CodexUsageRateLimitPayload?

    enum CodingKeys: String, CodingKey {
        case rateLimit = "rate_limit"
    }
}

private struct CodexUsageRateLimitPayload: Decodable {
    let primaryWindow: CodexUsageWindowPayload?
    let secondaryWindow: CodexUsageWindowPayload?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

private struct CodexUsageWindowPayload: Decodable {
    let usedPercent: Double?
    let limitWindowSeconds: Double?
    let resetAfterSeconds: Double?
    let resetAt: Double?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }
}

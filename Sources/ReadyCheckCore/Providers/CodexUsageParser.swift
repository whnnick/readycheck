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

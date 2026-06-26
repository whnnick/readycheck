import Foundation

public enum ProviderStatus: String, Codable, Equatable, Sendable {
    case available
    case estimated
    case unavailable
    case error
}

public enum ProviderSource: String, Codable, Equatable, Sendable {
    case mock
    case local
    case usageAPI = "usage_api"
    case costAPI = "cost_api"
    case oauthAPI = "oauth_api"
    case manual
}

public enum QuotaWindowKind: String, Codable, Equatable, Sendable {
    case rolling
    case calendar
    case billing
    case rateLimit = "rate_limit"
    case manual
}

public enum QuotaUnit: String, Codable, Equatable, Sendable {
    case tokens
    case requests
    case messages
    case usd
    case percent
    case unknown
}

public enum QuotaConfidence: String, Codable, Equatable, Sendable {
    case verified
    case estimated
    case manual
    case unknown
}

public struct QuotaWindow: Identifiable, Codable, Equatable, Sendable {
    private static let consistencyTolerance = 0.0001

    public let id: String
    public let labelKey: String
    public let kind: QuotaWindowKind
    public let used: Double
    public let limit: Double
    public let remaining: Double
    public let unit: QuotaUnit
    public let resetAt: Date?
    public let confidence: QuotaConfidence

    public init(
        id: String,
        labelKey: String,
        kind: QuotaWindowKind,
        used: Double,
        limit: Double,
        remaining: Double,
        unit: QuotaUnit,
        resetAt: Date?,
        confidence: QuotaConfidence
    ) {
        self.id = id
        self.labelKey = labelKey
        self.kind = kind
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.unit = unit
        self.resetAt = resetAt
        self.confidence = confidence
    }

    public var remainingRatio: Double? {
        guard limit.isFinite,
              remaining.isFinite,
              used.isFinite,
              limit > 0,
              remaining >= 0,
              remaining <= limit,
              used >= 0,
              used <= limit,
              abs((used + remaining) - limit) <= Self.consistencyTolerance
        else {
            return nil
        }

        return remaining / limit
    }

    var hasDisplayableRatioIgnoringSnapshotState: Bool {
        remainingRatio != nil && confidence != .unknown
    }
}

public struct ProviderQuotaSnapshot: Identifiable, Codable, Equatable, Sendable {
    public var id: String { providerId }
    public let providerId: String
    public let displayName: String
    public let status: ProviderStatus
    public let source: ProviderSource
    public let refreshedAt: Date
    public let staleAfter: Date
    public let windows: [QuotaWindow]
    public let errors: [String]

    public init(
        providerId: String,
        displayName: String,
        status: ProviderStatus,
        source: ProviderSource,
        refreshedAt: Date,
        staleAfter: Date,
        windows: [QuotaWindow],
        errors: [String]
    ) {
        self.providerId = providerId
        self.displayName = displayName
        self.status = status
        self.source = source
        self.refreshedAt = refreshedAt
        self.staleAfter = staleAfter
        self.windows = windows
        self.errors = errors
    }

    var hasDisplayablePercentageWindowIgnoringStaleness: Bool {
        status == .available || status == .estimated
            ? windows.contains(where: \.hasDisplayableRatioIgnoringSnapshotState)
            : false
    }

    public func canShowPercentages(now: Date) -> Bool {
        guard !isStale(now: now) else { return false }
        return hasDisplayablePercentageWindowIgnoringStaleness
    }

    public func isStale(now: Date) -> Bool {
        now >= staleAfter
    }
}

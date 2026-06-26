import Foundation

public struct RefreshPolicy: Equatable, Sendable {
    public static let `default` = RefreshPolicy(interval: 60)

    public let interval: TimeInterval

    public init(interval: TimeInterval) {
        self.interval = interval.isFinite && interval > 0 ? interval : Self.default.interval
    }
}

public struct RefreshBackoff: Equatable, Sendable {
    public let failureCount: Int

    public init(failureCount: Int) {
        self.failureCount = max(0, failureCount)
    }

    public var delay: TimeInterval {
        switch failureCount {
        case 0:
            return 60
        case 1:
            return 120
        case 2:
            return 300
        default:
            return 900
        }
    }
}

public struct RefreshScheduler: Equatable, Sendable {
    public let policy: RefreshPolicy

    public init(policy: RefreshPolicy = .default) {
        self.policy = policy
    }

    public func shouldRefresh(lastRefresh: Date?, now: Date, reason: RefreshReason) -> Bool {
        if reason == .manual || reason == .openedPanel {
            return true
        }
        guard let lastRefresh else {
            return true
        }
        return now.timeIntervalSince(lastRefresh) >= policy.interval
    }
}

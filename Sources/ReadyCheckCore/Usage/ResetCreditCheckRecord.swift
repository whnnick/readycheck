import Foundation

/// Diagnostic metadata only; this file can never authorize or initiate a redemption.
public struct ResetCreditCheckRecord: Codable, Equatable, Identifiable, Sendable {
    public enum Reason: String, Codable, Sendable {
        case checked, ledgerUnavailable, credentialsUnavailable, serviceUnavailable, writeFailed, resultUnconfirmed, cardChanged, windowMissed
    }
    public let id: String
    public let accountKey: String
    public let reason: Reason
    public let firstAt: Date
    public var lastAt: Date
    public var count: Int
    public var warningSubmitted: Bool

    public var shouldSubmitWarning: Bool {
        guard reason != .checked, !warningSubmitted else { return false }
        guard reason == .serviceUnavailable else { return true }
        let elapsed = lastAt.timeIntervalSince(firstAt)
        return count >= 3 && elapsed.isFinite && elapsed >= 120
    }

    public func recovered(in checks: [Self]) -> Bool {
        reason == .serviceUnavailable && checks.contains {
            $0.accountKey == accountKey && $0.reason == .checked && $0.firstAt >= lastAt
        }
    }
}

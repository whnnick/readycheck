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
}

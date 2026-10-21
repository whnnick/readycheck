import Foundation

/// Read-only projection of existing redemption records; never a second ledger.
public struct ResetCreditExecutionRecord: Equatable, Identifiable, Sendable {
    public enum NotificationState: String, Sendable { case pending, delivered, unrecorded, notApplicable }
    public let id: String
    public let expiresAt: Date
    public let status: ResetCreditAutomationStatus.Status
    public let updatedAt: Date
    public let successNotificationPending: Bool?
    public init(id: String, expiresAt: Date, status: ResetCreditAutomationStatus.Status, updatedAt: Date, successNotificationPending: Bool?) {
        self.id = id; self.expiresAt = expiresAt; self.status = status; self.updatedAt = updatedAt
        self.successNotificationPending = successNotificationPending
    }
    public var confirmedUsed: Bool { status == .reset || status == .alreadyRedeemed }
    public func notificationState(history: [QuotaReminderHistoryRecord]) -> NotificationState {
        guard confirmedUsed else { return .notApplicable }
        if history.contains(where: { $0.id == "reset-used:\(id)" && $0.kind == .resetCreditUsed && $0.status == .delivered }) { return .delivered }
        return successNotificationPending == true ? .pending : .unrecorded
    }
}

public struct ReadyCheckNextEvent: Equatable, Identifiable, Sendable {
    public enum Kind: String, Sendable { case naturalReset, awaitingResetReading, cardWindow, automationOff, conditionsUnknown, cardResultUnconfirmed, notificationPending }
    public enum Action: Equatable, Sendable { case reset, connection, rules, card(Date), record(String) }
    public let kind: Kind
    public let date: Date?
    public let expiration: Date?
    public let action: Action
    public var id: String { kind.rawValue }
    public var titleKey: String { "next." + kind.rawValue }
    public var detailKey: String { titleKey + ".detail" }
    public var actionKey: String {
        switch action { case .reset: "next.resetAction"; case .connection: "next.connectionAction"; case .rules: "next.rulesAction"; case .card, .record: "next.detailAction" }
    }
    public var needsAttention: Bool { kind == .conditionsUnknown || kind == .cardResultUnconfirmed || kind == .notificationPending }

    public static func evaluate(snapshot: ProviderQuotaSnapshot?, automation: ResetCreditAutomationStatus,
                                records: [ResetCreditExecutionRecord], historyUnavailable: Bool, now: Date) -> [Self] {
        var items: [Self] = []
        if let unconfirmed = records.sorted(by: { $0.updatedAt > $1.updatedAt }).first(where: {
            $0.status == .pending || $0.status == .verificationRequired || $0.status == .storageFailed
        }) {
            items.append(Self(kind: .cardResultUnconfirmed, date: nil, expiration: unconfirmed.expiresAt, action: .record(unconfirmed.id)))
        } else if let pending = records.sorted(by: { $0.updatedAt > $1.updatedAt }).first(where: { $0.confirmedUsed && $0.successNotificationPending == true }) {
            items.append(Self(kind: .notificationPending, date: pending.updatedAt, expiration: pending.expiresAt, action: .record(pending.id)))
        }
        let fresh = snapshot.map { !$0.isStale(now: now) && $0.status == .available && $0.errors.isEmpty && ($0.source == .appServer || $0.source == .oauthAPI) } == true
        let details = snapshot?.details
        let cardCount = details?.manualResetCount ?? (details?.manualResetExpirations.isEmpty == false ? details?.manualResetExpirations.count : nil)
        let cardsKnown = fresh && details?.hasCurrentManualResetDetails(now: now) == true
        if !fresh || !cardsKnown || historyUnavailable || automation.status == .unavailable || automation.status == .storageFailed {
            items.append(Self(kind: .conditionsUnknown, date: nil, expiration: nil, action: .connection))
        } else if cardCount != 0, let expiry = details?.manualResetExpirations.filter({ $0 > now && $0.timeIntervalSince1970.isFinite }).min(), expiry.timeIntervalSince(now) <= 86400 {
            if automation.enabled {
                items.append(Self(kind: .cardWindow, date: expiry.addingTimeInterval(-3600), expiration: expiry, action: .card(expiry)))
            } else {
                items.append(Self(kind: .automationOff, date: expiry, expiration: expiry, action: .rules))
            }
        }
        if let window = snapshot?.windows.first(where: { $0.durationMinutes == 300 }), let reset = window.resetAt, reset.timeIntervalSince1970.isFinite {
            // A timestamp, including an elapsed timestamp, never proves actual recovery.
            items.append(Self(kind: fresh && window.confidence == .verified && reset > now ? .naturalReset : .awaitingResetReading, date: reset, expiration: nil, action: .reset))
        }
        func priority(_ kind: Kind) -> Int {
            switch kind {
            case .cardResultUnconfirmed: 0
            case .notificationPending: 1
            case .conditionsUnknown: 2
            case .automationOff: 3
            case .awaitingResetReading: 4
            case .cardWindow, .naturalReset: 5
            }
        }
        return Array(items.sorted {
            if priority($0.kind) != priority($1.kind) { return priority($0.kind) < priority($1.kind) }
            return ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture)
        }.prefix(2))
    }
}

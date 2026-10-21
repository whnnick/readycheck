import Foundation

public enum QuotaReminderEvent: Equatable, Hashable, Sendable {
    case manualResetExpiring(index: Int, expiresAt: Date, leadHours: Int)
    case creditsStarted
    case quotaLow(LowQuotaAlert)
    case quotaRecovered(requestID: String)
    case dismissQuotaRecovered(requestID: String)
}

public enum QuotaReminderHistoryKind: String, Codable, Equatable, Sendable {
    case resetCreditUsed
    case manualResetExpiring
    case creditsStarted
    case quotaLow
    case quotaRecovered
}

public enum QuotaReminderDeliveryStatus: String, Codable, Equatable, Sendable {
    case delivered
    case failed
    case automaticallyWithdrawn
    case withdrawalPending
    case legacyUnknown
}

public struct QuotaReminderHistoryRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: QuotaReminderHistoryKind
    public var status: QuotaReminderDeliveryStatus
    public var lastAttemptAt: Date?
    public var deliveredAt: Date?
    public var expiresAt: Date?
    public var leadHours: Int?
    public var resetIndex: Int?
    public var attemptCount: Int
    public var submissionAccepted: Bool? = nil
    public var accountKey: String? = nil
    public var quotaLabelKey: String? = nil
    public var quotaDisplayLabel: String? = nil
    public var remainingPercent: Int? = nil

    public init(
        id: String,
        kind: QuotaReminderHistoryKind,
        status: QuotaReminderDeliveryStatus,
        lastAttemptAt: Date? = nil,
        deliveredAt: Date? = nil,
        expiresAt: Date? = nil,
        leadHours: Int? = nil,
        resetIndex: Int? = nil,
        attemptCount: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.lastAttemptAt = lastAttemptAt
        self.deliveredAt = deliveredAt
        self.expiresAt = expiresAt
        self.leadHours = leadHours
        self.resetIndex = resetIndex
        self.attemptCount = attemptCount
    }
}

public struct QuotaReminderState: Codable, Equatable, Sendable {
    public var detailsAccount: String? = nil
    public var lowQuotaThreshold: Int? = nil
    public var lowQuotaState: LowQuotaReminderState? = nil
    public var lowQuotaRevision: Int? = nil
    public var recoveryRequest: QuotaRecoveryRequest?
    public var recoveryNotificationBaseline: QuotaRecoveryRequest? = nil
    public var recoveryNotificationBaselineMigrationCompleted: Bool? = nil
    public var recoveryNotificationRemovalVerificationVersion: Int? = nil
    public var pendingRecoveryNotificationDismissalID: String? = nil
    public var resetExpiryReminderEnabled: Bool? = nil
    public var resetExpiryReminderRevision: Int? = nil
    public var expiryNotificationAccountKey: String? = nil
    public var isResetExpiryReminderEnabled: Bool { resetExpiryReminderEnabled ?? true }
    public var automaticRecoveryEnabled: Bool?
    public var recoveryRevision: Int?
    public var isAutomaticRecoveryEnabled: Bool { automaticRecoveryEnabled ?? true }
    public var notifiedManualResetExpirations: [Int64]
    public var notifiedManualResetThresholds: [String]?
    public var knownManualResetExpirations: [Int64]?
    public var previousCreditBalance: String?
    public var creditsReminderSentForCurrentExhaustion: Bool
    public var creditExhaustionCycleKey: String?
    public var notificationHistory: [QuotaReminderHistoryRecord]?
    public var notificationHistoryMigrationCompleted: Bool?
    public var notificationDeliveryVerificationVersion: Int?

    public init(
        notifiedManualResetExpirations: [Int64] = [],
        notifiedManualResetThresholds: [String]? = nil,
        knownManualResetExpirations: [Int64]? = nil,
        previousCreditBalance: String? = nil,
        creditsReminderSentForCurrentExhaustion: Bool = false,
        creditExhaustionCycleKey: String? = nil,
        notificationHistory: [QuotaReminderHistoryRecord]? = nil,
        notificationHistoryMigrationCompleted: Bool? = nil,
        notificationDeliveryVerificationVersion: Int? = nil
    ) {
        self.notifiedManualResetExpirations = notifiedManualResetExpirations
        self.notifiedManualResetThresholds = notifiedManualResetThresholds
        self.knownManualResetExpirations = knownManualResetExpirations
        self.previousCreditBalance = previousCreditBalance
        self.creditsReminderSentForCurrentExhaustion = creditsReminderSentForCurrentExhaustion
        self.creditExhaustionCycleKey = creditExhaustionCycleKey
        self.notificationHistory = notificationHistory
        self.notificationHistoryMigrationCompleted = notificationHistoryMigrationCompleted
        self.notificationDeliveryVerificationVersion = notificationDeliveryVerificationVersion
    }
}

public struct QuotaReminderDeliveryBatch: Sendable {
    public let previousState: QuotaReminderState
    public let proposedState: QuotaReminderState
    public let events: [QuotaReminderEvent]

    public init(
        previousState: QuotaReminderState,
        proposedState: QuotaReminderState,
        events: [QuotaReminderEvent]
    ) {
        self.previousState = previousState
        self.proposedState = proposedState
        self.events = events
    }
}

public struct QuotaReminderEvaluation: Equatable, Sendable {
    public let state: QuotaReminderState
    public let events: [QuotaReminderEvent]

    public init(state: QuotaReminderState, events: [QuotaReminderEvent]) {
        self.state = state
        self.events = events
    }
}

public enum QuotaReminderEvaluator {
    public static let manualResetLeadHours = [12, 24, 48, 72]

    public static func evaluate(
        snapshot: ProviderQuotaSnapshot,
        now: Date,
        state originalState: QuotaReminderState,
        account: String? = nil
    ) -> QuotaReminderEvaluation {
        guard snapshot.status == .available else {
            return QuotaReminderEvaluation(state: originalState, events: [])
        }

        var state = originalState
        var events: [QuotaReminderEvent] = []
        let lowQuota = LowQuotaReminderEvaluator.evaluate(
            snapshot: snapshot, now: now, account: account,
            threshold: state.lowQuotaThreshold ?? 0, state: state.lowQuotaState
        )
        state.lowQuotaState = lowQuota.state
        events.append(contentsOf: lowQuota.alerts.map(QuotaReminderEvent.quotaLow))
        if let requestID = state.pendingRecoveryNotificationDismissalID {
            events.append(.dismissQuotaRecovered(requestID: requestID))
            state.pendingRecoveryNotificationDismissalID = nil
        }
        if let baseline = state.recoveryNotificationBaseline,
           baseline.hasConsumption(snapshot, account: account, now: now) {
            events.append(.dismissQuotaRecovered(requestID: baseline.id))
            state.recoveryNotificationBaseline = nil
        }
        if !state.isAutomaticRecoveryEnabled {
            state.recoveryRequest = nil
        } else if let account, !account.isEmpty {
            if let request = state.recoveryRequest, request.account != account {
                state.recoveryRequest = nil
            }
            if state.recoveryRequest == nil, QuotaRecoveryRequest.canArm(snapshot, now: now) {
                state.recoveryRequest = QuotaRecoveryRequest(account: account, snapshot: snapshot)
            }
        }
        if let request = state.recoveryRequest,
           request.isRecovered(snapshot, account: account, now: now) {
            events.append(.quotaRecovered(requestID: request.id))
            state.recoveryNotificationBaseline = QuotaRecoveryRequest(
                id: request.id, account: request.account, snapshot: snapshot
            )
            state.recoveryRequest = QuotaRecoveryRequest.canArm(snapshot, now: now)
                ? QuotaRecoveryRequest(account: request.account, snapshot: snapshot) : nil
        } else if let request = state.recoveryRequest,
                  account == request.account,
                  snapshot.refreshedAt > request.observedAt,
                  QuotaRecoveryRequest.canArm(snapshot, now: now) {
            state.recoveryRequest = QuotaRecoveryRequest(account: request.account, snapshot: snapshot)
        }
        let nowTimestamp = Int64(now.timeIntervalSince1970.rounded())
        var notifiedThresholds = Set(
            (state.notifiedManualResetThresholds ?? []).filter {
                expirationTimestamp(from: $0).map { $0 >= nowTimestamp } ?? false
            }
        )
        for timestamp in state.notifiedManualResetExpirations where timestamp >= nowTimestamp {
            notifiedThresholds.insert(thresholdKey(expirationTimestamp: timestamp, leadHours: 72))
        }
        state.notifiedManualResetExpirations = []

        let reportedExpirations = snapshot.details?.manualResetExpirations ?? []
        let reportedCount = snapshot.details?.manualResetCount
        let knownExpirations: [Int64]
        if !reportedExpirations.isEmpty {
            knownExpirations = deduplicatedExpirationTimestamps(
                reportedExpirations.map { Int64($0.timeIntervalSince1970.rounded()) },
                nowTimestamp: nowTimestamp
            )
        } else if reportedCount == 0 {
            knownExpirations = []
        } else {
            let migratedExpirations = notifiedThresholds.compactMap(expirationTimestamp(from:))
            knownExpirations = deduplicatedExpirationTimestamps(
                (state.knownManualResetExpirations ?? []) + migratedExpirations,
                nowTimestamp: nowTimestamp
            )
        }
        state.knownManualResetExpirations = knownExpirations

        for (offset, timestamp) in knownExpirations.enumerated() where state.isResetExpiryReminderEnabled {
            let expiration = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let interval = expiration.timeIntervalSince(now)
            guard interval > 0 else { continue }

            let eligibleHours = manualResetLeadHours.filter {
                interval <= TimeInterval($0 * 60 * 60)
            }
            let pendingHours = eligibleHours.filter {
                !thresholdWasNotified(
                    notifiedThresholds,
                    expirationTimestamp: timestamp,
                    leadHours: $0
                )
            }
            guard let leadHours = pendingHours.first else { continue }

            events.append(.manualResetExpiring(
                index: offset + 1,
                expiresAt: expiration,
                leadHours: leadHours
            ))
            for handledHours in eligibleHours {
                notifiedThresholds.insert(
                    thresholdKey(expirationTimestamp: timestamp, leadHours: handledHours)
                )
            }
        }
        state.notifiedManualResetThresholds = Array(notifiedThresholds).sorted()

        let validWindows = snapshot.windows.filter { window in
            guard window.confidence != .unknown else { return false }
            return window.remainingRatio != nil
        }
        guard !validWindows.isEmpty,
              let currentBalanceText = snapshot.details?.creditBalance,
              let currentBalance = decimal(from: currentBalanceText)
        else {
            return QuotaReminderEvaluation(state: state, events: events)
        }

        let exhaustedWindows = validWindows.filter {
            QuotaUrgency(remainingRatio: $0.remainingRatio) == .exhausted
        }
        if exhaustedWindows.isEmpty {
            state.creditsReminderSentForCurrentExhaustion = false
            state.creditExhaustionCycleKey = nil
        } else {
            let cycleKey = exhaustedWindows
                .map { window in
                    let resetTimestamp = window.resetAt.map {
                        String(Int64($0.timeIntervalSince1970.rounded()))
                    } ?? "unknown"
                    return "\(window.id):\(resetTimestamp)"
                }
                .sorted()
                .joined(separator: "|")
            if state.creditExhaustionCycleKey != cycleKey {
                state.creditExhaustionCycleKey = cycleKey
                state.creditsReminderSentForCurrentExhaustion = false
            }

            if !state.creditsReminderSentForCurrentExhaustion,
                  let previousBalanceText = state.previousCreditBalance,
                  let previousBalance = decimal(from: previousBalanceText),
                  currentBalance < previousBalance {
                events.append(.creditsStarted)
                state.creditsReminderSentForCurrentExhaustion = true
            }
        }

        state.previousCreditBalance = currentBalanceText
        return QuotaReminderEvaluation(state: state, events: events)
    }

    private static func decimal(from value: String) -> Decimal? {
        let normalized = value
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func thresholdKey(expirationTimestamp: Int64, leadHours: Int) -> String {
        "\(expirationTimestamp):\(leadHours)"
    }

    private static func expirationTimestamp(from key: String) -> Int64? {
        Int64(key.split(separator: ":", maxSplits: 1).first ?? "")
    }

    static func thresholdKeyForPersistence(
        expirationTimestamp: Int64,
        leadHours: Int
    ) -> String {
        thresholdKey(expirationTimestamp: expirationTimestamp, leadHours: leadHours)
    }

    static func expirationTimestampForPersistence(from key: String) -> Int64? {
        expirationTimestamp(from: key)
    }

    static func thresholdMatchesExpiration(_ key: String, timestamp: Int64) -> Bool {
        expirationTimestamp(from: key).map { abs($0 - timestamp) <= 5 } ?? false
    }

    private static func thresholdWasNotified(
        _ thresholds: Set<String>,
        expirationTimestamp: Int64,
        leadHours: Int
    ) -> Bool {
        thresholds.contains { key in
            let parts = key.split(separator: ":", maxSplits: 1)
            guard parts.count == 2,
                  let timestamp = Int64(parts[0]),
                  let storedLeadHours = Int(parts[1])
            else {
                return false
            }
            return abs(timestamp - expirationTimestamp) <= 5
                && storedLeadHours == leadHours
        }
    }

    private static func deduplicatedExpirationTimestamps(
        _ timestamps: [Int64],
        nowTimestamp: Int64
    ) -> [Int64] {
        var result: [Int64] = []
        for timestamp in timestamps.filter({ $0 >= nowTimestamp }).sorted() {
            if let last = result.last, abs(timestamp - last) <= 5 {
                continue
            }
            result.append(timestamp)
        }
        return result
    }
}

public actor QuotaReminderStore {
    public static let historyLimit = 50

    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func evaluate(
        _ snapshot: ProviderQuotaSnapshot,
        now: Date = Date()
    ) -> [QuotaReminderEvent] {
        let batch = prepare(snapshot, now: now)
        commit(batch, deliveredEvents: batch.events)
        return batch.events
    }

    public func prepare(
        _ snapshot: ProviderQuotaSnapshot,
        now: Date = Date(),
        account: String? = nil
    ) -> QuotaReminderDeliveryBatch {
        let previousState = migrateHistoryIfNeeded(load())
        let evaluation = QuotaReminderEvaluator.evaluate(
            snapshot: snapshot,
            now: now,
            state: previousState,
            account: account
        )
        return QuotaReminderDeliveryBatch(
            previousState: previousState,
            proposedState: evaluation.state,
            events: evaluation.events
        )
    }

    public func commit(
        _ batch: QuotaReminderDeliveryBatch,
        deliveredEvents: [QuotaReminderEvent],
        now: Date = Date()
    ) {
        let delivered = Set(deliveredEvents)
        let undelivered = batch.events.filter { !delivered.contains($0) }
        let previousState = migrateHistoryIfNeeded(batch.previousState)
        var state = migrateHistoryIfNeeded(batch.proposedState)

        for event in undelivered {
            switch event {
            case let .quotaLow(alert):
                state.lowQuotaState?.windows[alert.windowID]?.notified = false
                state.lowQuotaState?.windows[alert.windowID]?.pending = true
            case let .manualResetExpiring(_, expiresAt, _):
                let timestamp = Int64(expiresAt.timeIntervalSince1970.rounded())
                let previousThresholds = migratedThresholds(from: previousState)
                state.notifiedManualResetThresholds = (state.notifiedManualResetThresholds ?? [])
                    .filter { !QuotaReminderEvaluator.thresholdMatchesExpiration($0, timestamp: timestamp) }
                    + previousThresholds.filter {
                        QuotaReminderEvaluator.thresholdMatchesExpiration($0, timestamp: timestamp)
                    }
            case .quotaRecovered:
                state.recoveryRequest = previousState.recoveryRequest
                state.recoveryNotificationBaseline = delivered.contains(where: {
                    if case .dismissQuotaRecovered = $0 { return true }
                    return false
                }) ? nil : previousState.recoveryNotificationBaseline
            case .dismissQuotaRecovered:
                let deliveredRecoveryID = delivered.compactMap { event -> String? in
                    guard case let .quotaRecovered(requestID) = event else { return nil }
                    return requestID
                }.first
                if state.recoveryNotificationBaseline?.id != deliveredRecoveryID {
                    state.recoveryNotificationBaseline = previousState.recoveryNotificationBaseline
                }
                state.pendingRecoveryNotificationDismissalID = previousState.pendingRecoveryNotificationDismissalID
            case .creditsStarted:
                state.previousCreditBalance = previousState.previousCreditBalance
                state.creditsReminderSentForCurrentExhaustion = previousState.creditsReminderSentForCurrentExhaustion
                state.creditExhaustionCycleKey = previousState.creditExhaustionCycleKey
            }
        }

        let expiryStillEnabled = load().isResetExpiryReminderEnabled
        for event in batch.events where !event.isDismissal {
            if case .manualResetExpiring = event, !expiryStillEnabled, !delivered.contains(event) { continue }
            recordHistory(
                event,
                delivered: delivered.contains(event),
                cycleKey: batch.proposedState.creditExhaustionCycleKey,
                now: now,
                state: &state
            )
        }
        for event in batch.events where event.isDismissal {
            recordDismissal(
                event,
                withdrawn: delivered.contains(event),
                now: now,
                state: &state
            )
        }

        // A user may cancel or replace a request while system delivery is awaiting confirmation.
        let currentState = load()
        guard currentState.detailsAccount == batch.previousState.detailsAccount else { return }
        state.expiryNotificationAccountKey = currentState.expiryNotificationAccountKey
        // OS acceptance is enough to suppress another expiry banner, even after dismissal.
        var receiptThresholds: [String] = []
        for receipt in currentState.notificationHistory ?? [] where receipt.kind == .manualResetExpiring
            && receipt.accountKey == QuotaHistorySample.key(for: currentState.detailsAccount)
            && (receipt.submissionAccepted == true || receipt.status == .delivered || receipt.deliveredAt != nil) {
            var retained = receipt
            if let event = batch.events.first(where: { matchesExpiry(receipt, event: $0) }), delivered.contains(event) {
                retained.status = .delivered
                retained.deliveredAt = receipt.deliveredAt ?? now
            }
            var history = state.notificationHistory ?? []
            history.removeAll { $0.id == receipt.id }
            history.append(retained)
            state.notificationHistory = prunedHistory(history)
            if let expiry = receipt.expiresAt, expiry > now, let hours = receipt.leadHours {
                receiptThresholds += QuotaReminderEvaluator.manualResetLeadHours.filter { $0 >= hours }.map {
                    QuotaReminderEvaluator.thresholdKeyForPersistence(expirationTimestamp: Int64(expiry.timeIntervalSince1970.rounded()), leadHours: $0)
                }
            }
        }
        let nowTimestamp = Int64(now.timeIntervalSince1970.rounded())
        let currentThresholds = (currentState.notifiedManualResetThresholds ?? []).filter {
            Int64($0.split(separator: ":").first ?? "").map { $0 >= nowTimestamp } == true
        }
        state.notifiedManualResetThresholds = Array(Set((state.notifiedManualResetThresholds ?? []) + currentThresholds + receiptThresholds)).sorted()
        // Automatic-use receipts can arrive while a quota delivery batch is awaiting the system.
        let resetReceipts = (currentState.notificationHistory ?? []).filter { $0.kind == .resetCreditUsed }
        state.notificationHistory = prunedHistory((state.notificationHistory ?? []).filter { $0.kind != .resetCreditUsed } + resetReceipts)
        if currentState.resetExpiryReminderRevision != batch.previousState.resetExpiryReminderRevision {
            state.resetExpiryReminderEnabled = currentState.resetExpiryReminderEnabled
            state.resetExpiryReminderRevision = currentState.resetExpiryReminderRevision
        }
        if currentState.lowQuotaRevision != batch.previousState.lowQuotaRevision {
            state.lowQuotaThreshold = currentState.lowQuotaThreshold
            state.lowQuotaState = currentState.lowQuotaState
            state.lowQuotaRevision = currentState.lowQuotaRevision
        }
        if currentState.recoveryRevision != batch.previousState.recoveryRevision
            || currentState.recoveryRequest?.id != batch.previousState.recoveryRequest?.id {
            state.recoveryRequest = currentState.recoveryRequest
            state.automaticRecoveryEnabled = currentState.automaticRecoveryEnabled
            state.recoveryRevision = currentState.recoveryRevision
        }
        state.notifiedManualResetThresholds = Array(Set(state.notifiedManualResetThresholds ?? [])).sorted()
        save(state)
    }

    public func recoveryRequest() -> QuotaRecoveryRequest? {
        load().recoveryRequest
    }

    public func hasDeliveredResetCreditNotice(_ id: String) -> Bool {
        (load().notificationHistory ?? []).contains { $0.id == "reset-used:\(id)" && $0.status == .delivered }
    }

    @discardableResult
    public func recordResetCreditNotice(_ notice: ResetCreditSuccessNotice, delivered: Bool, now: Date = Date()) -> Bool {
        var state = migrateHistoryIfNeeded(load())
        var history = state.notificationHistory ?? []
        let id = "reset-used:\(notice.id)"
        let previous = history.first { $0.id == id }
        if previous?.status == .delivered { return true }
        let record = QuotaReminderHistoryRecord(id: id, kind: .resetCreditUsed,
            status: delivered ? .delivered : .failed, lastAttemptAt: now,
            deliveredAt: delivered ? now : nil, expiresAt: notice.expiresAt,
            attemptCount: (previous?.attemptCount ?? 0) + 1)
        history.removeAll { $0.id == id }
        history.append(record)
        state.notificationHistory = prunedHistory(history)
        save(state)
        return (load().notificationHistory ?? []).contains(record)
    }

    public func automaticRecoveryEnabled() -> Bool {
        load().isAutomaticRecoveryEnabled
    }

    public func resetExpiryReminderEnabled() -> Bool { load().isResetExpiryReminderEnabled }

    public func hasSubmittedResetExpiryNotification(_ event: QuotaReminderEvent) -> Bool {
        expiryReceipt(event, state: migrateHistoryIfNeeded(load())) != nil
    }

    public func resetExpiryNotificationAccountKey() -> String? {
        QuotaHistorySample.key(for: load().detailsAccount)
    }

    @discardableResult
    public func recordResetExpirySubmission(_ event: QuotaReminderEvent, accountKey: String?, now: Date = Date()) -> Bool {
        guard case let .manualResetExpiring(_, expiry, hours) = event else { return false }
        var state = migrateHistoryIfNeeded(load())
        guard QuotaHistorySample.key(for: state.detailsAccount) == accountKey else { return false }
        if expiryReceipt(event, state: state) != nil { return true }
        recordHistory(event, delivered: false, cycleKey: nil, now: now, state: &state, submitted: true)
        let timestamp = Int64(expiry.timeIntervalSince1970.rounded())
        let handled = QuotaReminderEvaluator.manualResetLeadHours.filter { $0 >= hours }.map {
            QuotaReminderEvaluator.thresholdKeyForPersistence(expirationTimestamp: timestamp, leadHours: $0)
        }
        state.notifiedManualResetThresholds = Array(Set((state.notifiedManualResetThresholds ?? []) + handled)).sorted()
        save(state)
        return expiryReceipt(event, state: load()) != nil
    }

    private func matchesExpiry(_ record: QuotaReminderHistoryRecord, event: QuotaReminderEvent) -> Bool {
        guard case let .manualResetExpiring(_, expiry, hours) = event else { return false }
        return record.kind == .manualResetExpiring && record.leadHours == hours
            && record.expiresAt.map { abs($0.timeIntervalSince(expiry)) <= 5 } == true
    }

    private func expiryReceipt(_ event: QuotaReminderEvent, state: QuotaReminderState) -> QuotaReminderHistoryRecord? {
        (state.notificationHistory ?? []).first {
            matchesExpiry($0, event: event) && $0.accountKey == QuotaHistorySample.key(for: state.detailsAccount)
                && ($0.submissionAccepted == true || $0.status == .delivered || $0.deliveredAt != nil)
        }
    }

    @discardableResult
    public func setResetExpiryReminderEnabled(_ enabled: Bool) -> Bool {
        var state = migrateHistoryIfNeeded(load())
        state.resetExpiryReminderEnabled = enabled
        state.resetExpiryReminderRevision = (state.resetExpiryReminderRevision ?? 0) + 1
        save(state)
        return load() == state
    }

    public func lowQuotaThreshold() -> Int { load().lowQuotaThreshold ?? 0 }

    @discardableResult
    public func setLowQuotaThreshold(_ threshold: Int) -> Bool {
        guard [0, 5, 10, 20].contains(threshold) else { return false }
        var state = migrateHistoryIfNeeded(load())
        state.lowQuotaThreshold = threshold
        state.lowQuotaState = nil
        state.lowQuotaRevision = (state.lowQuotaRevision ?? 0) + 1
        save(state)
        return load() == state
    }

    public func clearLowQuotaBaseline() {
        var state = load()
        state.lowQuotaState = nil
        state.lowQuotaRevision = (state.lowQuotaRevision ?? 0) + 1
        save(state)
    }

    public func clearLowQuotaBaselineIfAccountChanged(_ account: String) {
        guard let previous = load().lowQuotaState?.account, previous != account else { return }
        clearLowQuotaBaseline()
    }

    public func isLowQuotaAlertActive(_ alert: LowQuotaAlert) -> Bool {
        let state = load()
        return state.lowQuotaThreshold == alert.threshold
            && state.lowQuotaState?.windows[alert.windowID]?.id == alert.id
    }

    public func isRecoveryRequestActive(_ id: String) -> Bool {
        let state = load()
        return state.isAutomaticRecoveryEnabled && state.recoveryRequest?.id == id
    }

    @discardableResult
    public func setAutomaticRecoveryEnabled(_ enabled: Bool) -> Bool {
        var state = migrateHistoryIfNeeded(load())
        state.automaticRecoveryEnabled = enabled
        state.recoveryRevision = (state.recoveryRevision ?? 0) + 1
        if !enabled { state.recoveryRequest = nil }
        save(state)
        return load() == state
    }

    @discardableResult
    public func setRecoveryRequest(_ request: QuotaRecoveryRequest?) -> Bool {
        var state = migrateHistoryIfNeeded(load())
        state.recoveryRequest = request
        state.recoveryRevision = (state.recoveryRevision ?? 0) + 1
        save(state)
        return load().recoveryRequest == request
    }

    public func history() -> [QuotaReminderHistoryRecord] {
        let storedState = load()
        var normalizedState = migrateHistoryIfNeeded(storedState)
        normalizedState.notificationHistory = prunedHistory(normalizedState.notificationHistory ?? [])
        if normalizedState != storedState {
            save(normalizedState)
        }
        return normalizedState.notificationHistory ?? []
    }

    public func knownManualResetExpirations(now: Date = Date()) -> [Date] {
        let state = migrateHistoryIfNeeded(load())
        if state.detailsAccount == nil && state.expiryNotificationAccountKey != nil { return [] }
        let nowTimestamp = Int64(now.timeIntervalSince1970.rounded())
        return deduplicatedKnownExpirations(
            state,
            nowTimestamp: nowTimestamp
        ).map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    public func updateDetailsAccount(_ account: String?) {
        var state = load()
        guard state.detailsAccount != account else { return }
        let previousKey = state.expiryNotificationAccountKey ?? QuotaHistorySample.key(for: state.detailsAccount)
        let nextKey = QuotaHistorySample.key(for: account)
        if let nextKey, nextKey != previousKey {
            state.notifiedManualResetExpirations = []
            state.notifiedManualResetThresholds = []
        }
        state.expiryNotificationAccountKey = nextKey ?? previousKey
        state.detailsAccount = account
        state.knownManualResetExpirations = []
        state.previousCreditBalance = nil
        state.creditsReminderSentForCurrentExhaustion = false
        state.creditExhaustionCycleKey = nil
        save(state)
    }

    public func clearKnownManualResetExpirations() {
        var state = migrateHistoryIfNeeded(load())
        state.knownManualResetExpirations = []
        state.notifiedManualResetExpirations = []
        state.notifiedManualResetThresholds = []
        save(state)
    }

    private func migratedThresholds(from state: QuotaReminderState) -> [String] {
        var thresholds = Set(state.notifiedManualResetThresholds ?? [])
        for timestamp in state.notifiedManualResetExpirations {
            thresholds.insert(QuotaReminderEvaluator.thresholdKeyForPersistence(
                expirationTimestamp: timestamp,
                leadHours: 72
            ))
        }
        return Array(thresholds)
    }

    private func deduplicatedKnownExpirations(
        _ state: QuotaReminderState,
        nowTimestamp: Int64
    ) -> [Int64] {
        let migratedExpirations = migratedThresholds(from: state).compactMap {
            QuotaReminderEvaluator.expirationTimestampForPersistence(from: $0)
        }
        return Array(Set((state.knownManualResetExpirations ?? []) + migratedExpirations))
            .filter { $0 >= nowTimestamp }
            .sorted()
    }

    private func load() -> QuotaReminderState {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(QuotaReminderState.self, from: data)
        else {
            return QuotaReminderState()
        }
        return state
    }

    private func migrateHistoryIfNeeded(_ input: QuotaReminderState) -> QuotaReminderState {
        var state = input
        let baselineMigrationWasAlreadyCompleted = state.recoveryNotificationBaselineMigrationCompleted == true
        if state.notificationHistoryMigrationCompleted != true {
            var history = state.notificationHistory ?? []
            let existingIDs = Set(history.map(\.id))

            for key in migratedThresholds(from: state) {
                let parts = key.split(separator: ":", maxSplits: 1)
                guard parts.count == 2,
                      let timestamp = Int64(parts[0]),
                      let leadHours = Int(parts[1])
                else {
                    continue
                }
                let id = "legacy-reset:\(timestamp):\(leadHours)"
                guard !existingIDs.contains(id) else { continue }
                history.append(QuotaReminderHistoryRecord(
                    id: id,
                    kind: .manualResetExpiring,
                    status: .legacyUnknown,
                    expiresAt: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                    leadHours: leadHours
                ))
            }

            state.notificationHistory = prunedHistory(history)
            state.notificationHistoryMigrationCompleted = true
        }

        if (state.notificationDeliveryVerificationVersion ?? 0) < 1 {
            state.notificationHistory = (state.notificationHistory ?? []).map { record in
                guard record.status == .delivered else { return record }
                var migrated = record
                migrated.status = .legacyUnknown
                migrated.deliveredAt = nil
                return migrated
            }
            state.notificationDeliveryVerificationVersion = 1
        }

        if state.recoveryNotificationBaselineMigrationCompleted != true {
            if state.recoveryNotificationBaseline == nil,
               let request = state.recoveryRequest,
               let deliveredRecovery = (state.notificationHistory ?? []).first(where: {
                   $0.kind == .quotaRecovered
                       && $0.status == .delivered
                       && $0.deliveredAt.map { $0 <= request.observedAt } == true
               }),
               deliveredRecovery.id.hasPrefix("recovery:") {
                let requestID = String(deliveredRecovery.id.dropFirst("recovery:".count))
                state.recoveryNotificationBaseline = QuotaRecoveryRequest(id: requestID, copying: request)
            }
            state.recoveryNotificationBaselineMigrationCompleted = true
        }

        if (state.recoveryNotificationRemovalVerificationVersion ?? 0) < 1 {
            if state.recoveryNotificationBaseline == nil,
               let request = state.recoveryRequest,
               let deliveredRecovery = (state.notificationHistory ?? []).first(where: {
                   $0.kind == .quotaRecovered && $0.status == .delivered
               }),
               deliveredRecovery.id.hasPrefix("recovery:") {
                let requestID = String(deliveredRecovery.id.dropFirst("recovery:".count))
                if baselineMigrationWasAlreadyCompleted {
                    state.pendingRecoveryNotificationDismissalID = requestID
                } else {
                    state.recoveryNotificationBaseline = QuotaRecoveryRequest(id: requestID, copying: request)
                }
            }
            state.recoveryNotificationRemovalVerificationVersion = 1
        }

        return state
    }

    private func recordHistory(
        _ event: QuotaReminderEvent,
        delivered: Bool,
        cycleKey: String?,
        now: Date,
        state: inout QuotaReminderState,
        submitted: Bool = false
    ) {
        var history = state.notificationHistory ?? []
        let recordID: String
        let kind: QuotaReminderHistoryKind
        let expiresAt: Date?
        let leadHours: Int?
        let resetIndex: Int?

        switch event {
        case let .quotaLow(alert):
            recordID = "low-quota:\(alert.id)"
            kind = .quotaLow
            expiresAt = nil
            leadHours = nil
            resetIndex = nil
        case let .manualResetExpiring(index, expiration, hours):
            let timestamp = Int64(expiration.timeIntervalSince1970.rounded())
            let accountKey = QuotaHistorySample.key(for: state.detailsAccount)
            recordID = history.first(where: {
                $0.kind == .manualResetExpiring
                    && $0.accountKey == accountKey
                    && $0.leadHours == hours
                    && $0.expiresAt.map {
                        abs($0.timeIntervalSince1970 - expiration.timeIntervalSince1970) <= 5
                    } == true
            })?.id ?? "reset:\(accountKey.map { $0 + ":" } ?? "")\(timestamp):\(hours)"
            kind = .manualResetExpiring
            expiresAt = expiration
            leadHours = hours
            resetIndex = index
        case let .quotaRecovered(requestID):
            recordID = "recovery:\(requestID)"
            kind = .quotaRecovered
            expiresAt = nil
            leadHours = nil
            resetIndex = nil
        case .dismissQuotaRecovered:
            return
        case .creditsStarted:
            recordID = "credits:\(cycleKey ?? "unknown")"
            kind = .creditsStarted
            expiresAt = nil
            leadHours = nil
            resetIndex = nil
        }

        let existing = history.first(where: { $0.id == recordID })
        var record = QuotaReminderHistoryRecord(
            id: recordID,
            kind: kind,
            status: delivered ? .delivered : submitted ? .legacyUnknown : .failed,
            lastAttemptAt: now,
            deliveredAt: delivered ? now : existing?.deliveredAt,
            expiresAt: expiresAt,
            leadHours: leadHours,
            resetIndex: resetIndex,
            attemptCount: (existing?.attemptCount ?? 0) + 1
        )
        if case .manualResetExpiring = event {
            record.submissionAccepted = submitted ? true : existing?.submissionAccepted
            record.accountKey = QuotaHistorySample.key(for: state.detailsAccount)
        }
        if case let .quotaLow(alert) = event {
            record.quotaLabelKey = alert.labelKey
            record.quotaDisplayLabel = alert.displayLabel
            record.remainingPercent = alert.remainingPercent
        }
        history.removeAll { $0.id == recordID }
        history.append(record)
        state.notificationHistory = prunedHistory(history)
    }

    private func recordDismissal(
        _ event: QuotaReminderEvent,
        withdrawn: Bool,
        now: Date,
        state: inout QuotaReminderState
    ) {
        guard case let .dismissQuotaRecovered(requestID) = event else { return }
        var history = state.notificationHistory ?? []
        guard let index = history.firstIndex(where: { $0.id == "recovery:\(requestID)" }) else { return }
        history[index].status = withdrawn ? .automaticallyWithdrawn : .withdrawalPending
        history[index].lastAttemptAt = now
        state.notificationHistory = prunedHistory(history)
    }

    private func prunedHistory(_ history: [QuotaReminderHistoryRecord]) -> [QuotaReminderHistoryRecord] {
        Array(history.sorted { left, right in
            historySortDate(left) > historySortDate(right)
        }.prefix(Self.historyLimit))
    }

    private func historySortDate(_ record: QuotaReminderHistoryRecord) -> Date {
        if let lastAttemptAt = record.lastAttemptAt {
            return lastAttemptAt
        }
        if let expiresAt = record.expiresAt, let leadHours = record.leadHours {
            return expiresAt.addingTimeInterval(TimeInterval(-leadHours * 60 * 60))
        }
        return record.expiresAt ?? .distantPast
    }

    private func save(_ state: QuotaReminderState) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            // Reminder persistence must never prevent quota refresh.
        }
    }
}

private extension QuotaReminderEvent {
    var isDismissal: Bool {
        if case .dismissQuotaRecovered = self { return true }
        return false
    }
}

import Foundation

public enum QuotaReminderEvent: Equatable, Hashable, Sendable {
    case manualResetExpiring(index: Int, expiresAt: Date, leadHours: Int)
    case creditsStarted
}

public enum QuotaReminderHistoryKind: String, Codable, Equatable, Sendable {
    case manualResetExpiring
    case creditsStarted
}

public enum QuotaReminderDeliveryStatus: String, Codable, Equatable, Sendable {
    case delivered
    case failed
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
        state originalState: QuotaReminderState
    ) -> QuotaReminderEvaluation {
        guard snapshot.status == .available else {
            return QuotaReminderEvaluation(state: originalState, events: [])
        }

        var state = originalState
        var events: [QuotaReminderEvent] = []
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

        for (offset, timestamp) in knownExpirations.enumerated() {
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
        now: Date = Date()
    ) -> QuotaReminderDeliveryBatch {
        let previousState = migrateHistoryIfNeeded(load())
        let evaluation = QuotaReminderEvaluator.evaluate(
            snapshot: snapshot,
            now: now,
            state: previousState
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
            case let .manualResetExpiring(_, expiresAt, _):
                let timestamp = Int64(expiresAt.timeIntervalSince1970.rounded())
                let previousThresholds = migratedThresholds(from: previousState)
                state.notifiedManualResetThresholds = (state.notifiedManualResetThresholds ?? [])
                    .filter { !QuotaReminderEvaluator.thresholdMatchesExpiration($0, timestamp: timestamp) }
                    + previousThresholds.filter {
                        QuotaReminderEvaluator.thresholdMatchesExpiration($0, timestamp: timestamp)
                    }
            case .creditsStarted:
                state.previousCreditBalance = previousState.previousCreditBalance
                state.creditsReminderSentForCurrentExhaustion = previousState.creditsReminderSentForCurrentExhaustion
                state.creditExhaustionCycleKey = previousState.creditExhaustionCycleKey
            }
        }

        for event in batch.events {
            recordHistory(
                event,
                delivered: delivered.contains(event),
                cycleKey: batch.proposedState.creditExhaustionCycleKey,
                now: now,
                state: &state
            )
        }

        state.notifiedManualResetThresholds = Array(Set(state.notifiedManualResetThresholds ?? [])).sorted()
        save(state)
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
        let nowTimestamp = Int64(now.timeIntervalSince1970.rounded())
        return deduplicatedKnownExpirations(
            migrateHistoryIfNeeded(load()),
            nowTimestamp: nowTimestamp
        ).map { Date(timeIntervalSince1970: TimeInterval($0)) }
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

        return state
    }

    private func recordHistory(
        _ event: QuotaReminderEvent,
        delivered: Bool,
        cycleKey: String?,
        now: Date,
        state: inout QuotaReminderState
    ) {
        var history = state.notificationHistory ?? []
        let recordID: String
        let kind: QuotaReminderHistoryKind
        let expiresAt: Date?
        let leadHours: Int?
        let resetIndex: Int?

        switch event {
        case let .manualResetExpiring(index, expiration, hours):
            let timestamp = Int64(expiration.timeIntervalSince1970.rounded())
            recordID = history.first(where: {
                $0.kind == .manualResetExpiring
                    && $0.leadHours == hours
                    && $0.expiresAt.map {
                        abs($0.timeIntervalSince1970 - expiration.timeIntervalSince1970) <= 5
                    } == true
            })?.id ?? "reset:\(timestamp):\(hours)"
            kind = .manualResetExpiring
            expiresAt = expiration
            leadHours = hours
            resetIndex = index
        case .creditsStarted:
            recordID = "credits:\(cycleKey ?? "unknown")"
            kind = .creditsStarted
            expiresAt = nil
            leadHours = nil
            resetIndex = nil
        }

        let existing = history.first(where: { $0.id == recordID })
        let record = QuotaReminderHistoryRecord(
            id: recordID,
            kind: kind,
            status: delivered ? .delivered : .failed,
            lastAttemptAt: now,
            deliveredAt: delivered ? now : existing?.deliveredAt,
            expiresAt: expiresAt,
            leadHours: leadHours,
            resetIndex: resetIndex,
            attemptCount: (existing?.attemptCount ?? 0) + 1
        )
        history.removeAll { $0.id == recordID }
        history.append(record)
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

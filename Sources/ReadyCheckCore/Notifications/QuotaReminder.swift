import Foundation

public enum QuotaReminderEvent: Equatable, Sendable {
    case manualResetExpiring(index: Int, expiresAt: Date)
    case creditsStarted
}

public struct QuotaReminderState: Codable, Equatable, Sendable {
    public var notifiedManualResetExpirations: [Int64]
    public var previousCreditBalance: String?
    public var creditsReminderSentForCurrentExhaustion: Bool
    public var creditExhaustionCycleKey: String?

    public init(
        notifiedManualResetExpirations: [Int64] = [],
        previousCreditBalance: String? = nil,
        creditsReminderSentForCurrentExhaustion: Bool = false,
        creditExhaustionCycleKey: String? = nil
    ) {
        self.notifiedManualResetExpirations = notifiedManualResetExpirations
        self.previousCreditBalance = previousCreditBalance
        self.creditsReminderSentForCurrentExhaustion = creditsReminderSentForCurrentExhaustion
        self.creditExhaustionCycleKey = creditExhaustionCycleKey
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
    public static let manualResetLeadTime: TimeInterval = 3 * 24 * 60 * 60

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
        state.notifiedManualResetExpirations = state.notifiedManualResetExpirations
            .filter { $0 >= nowTimestamp }

        var notifiedExpirations = Set(state.notifiedManualResetExpirations)
        for (offset, expiration) in (snapshot.details?.manualResetExpirations ?? []).enumerated() {
            let interval = expiration.timeIntervalSince(now)
            let timestamp = Int64(expiration.timeIntervalSince1970.rounded())
            guard interval > 0,
                  interval <= manualResetLeadTime,
                  !notifiedExpirations.contains(timestamp)
            else {
                continue
            }

            events.append(.manualResetExpiring(index: offset + 1, expiresAt: expiration))
            notifiedExpirations.insert(timestamp)
        }
        state.notifiedManualResetExpirations = Array(notifiedExpirations).sorted()

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
}

public actor QuotaReminderStore {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func evaluate(
        _ snapshot: ProviderQuotaSnapshot,
        now: Date = Date()
    ) -> [QuotaReminderEvent] {
        let evaluation = QuotaReminderEvaluator.evaluate(
            snapshot: snapshot,
            now: now,
            state: load()
        )
        save(evaluation.state)
        return evaluation.events
    }

    private func load() -> QuotaReminderState {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(QuotaReminderState.self, from: data)
        else {
            return QuotaReminderState()
        }
        return state
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

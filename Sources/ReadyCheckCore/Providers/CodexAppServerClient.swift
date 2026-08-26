import Foundation

public protocol CodexAppServerReading: Sendable {
    func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot
    func readAccountSnapshots() async throws -> [CodexAppServerAccountSnapshot]
}

public extension CodexAppServerReading {
    func readAccountSnapshots() async throws -> [CodexAppServerAccountSnapshot] {
        [try await readAccountSnapshot()]
    }
}

public struct CodexAppServerAccountSnapshot: Equatable, Sendable {
    public let email: String?
    public let planName: String?
    public let rateLimits: [CodexAppServerRateLimitSnapshot]
    public let manualResetCount: Int?
    public let resetCredits: [CodexAppServerResetCredit]
    public let tokenUsage: AccountTokenUsage?

    public init(
        email: String?,
        planName: String?,
        rateLimits: [CodexAppServerRateLimitSnapshot],
        manualResetCount: Int? = nil,
        resetCredits: [CodexAppServerResetCredit],
        tokenUsage: AccountTokenUsage?
    ) {
        self.email = email
        self.planName = planName
        self.rateLimits = rateLimits
        self.manualResetCount = manualResetCount
        self.resetCredits = resetCredits
        self.tokenUsage = tokenUsage
    }
}

public struct CodexAppServerRateLimitWindow: Equatable, Sendable {
    public let usedPercent: Double
    public let durationMinutes: Int?
    public let resetsAt: Date?

    public init(usedPercent: Double, durationMinutes: Int?, resetsAt: Date?) {
        self.usedPercent = usedPercent
        self.durationMinutes = durationMinutes
        self.resetsAt = resetsAt
    }
}

public struct CodexAppServerRateLimitSnapshot: Equatable, Sendable {
    public let limitID: String
    public let limitName: String?
    public let primary: CodexAppServerRateLimitWindow?
    public let secondary: CodexAppServerRateLimitWindow?
    public let creditBalance: String?
    public let hasCredits: Bool?
    public let creditsUnlimited: Bool?
    public let planName: String?
    public let reachedStateCode: String?

    public init(
        limitID: String,
        limitName: String?,
        primary: CodexAppServerRateLimitWindow?,
        secondary: CodexAppServerRateLimitWindow?,
        creditBalance: String?,
        hasCredits: Bool?,
        creditsUnlimited: Bool?,
        planName: String?,
        reachedStateCode: String? = nil
    ) {
        self.limitID = limitID
        self.limitName = limitName
        self.primary = primary
        self.secondary = secondary
        self.creditBalance = creditBalance
        self.hasCredits = hasCredits
        self.creditsUnlimited = creditsUnlimited
        self.planName = planName
        self.reachedStateCode = reachedStateCode
    }
}

public struct CodexAppServerResetCredit: Equatable, Sendable {
    public let status: String?
    public let expiresAt: Date?

    public init(status: String?, expiresAt: Date?) {
        self.status = status
        self.expiresAt = expiresAt
    }
}

public enum CodexAppServerError: Error, Equatable {
    case executableUnavailable
    case launchFailed
    case requestFailed(String)
    case invalidResponse
    case timedOut
}

public struct CodexAppServerClient: CodexAppServerReading {
    private let executableURL: URL?
    private let candidateExecutableURLs: [URL]?
    private let timeout: TimeInterval

    public init(
        executableURL: URL? = nil,
        candidateExecutableURLs: [URL]? = nil,
        timeout: TimeInterval = 12
    ) {
        self.executableURL = executableURL
        self.candidateExecutableURLs = candidateExecutableURLs
        self.timeout = timeout
    }

    public func readAccountSnapshot() async throws -> CodexAppServerAccountSnapshot {
        guard let snapshot = try await readAccountSnapshots().first else {
            throw CodexAppServerError.invalidResponse
        }
        return snapshot
    }

    public func readAccountSnapshots() async throws -> [CodexAppServerAccountSnapshot] {
        let executableURLs = executableURL.map { [$0] }
            ?? candidateExecutableURLs
            ?? Self.discoverExecutables()
        guard !executableURLs.isEmpty else {
            throw CodexAppServerError.executableUnavailable
        }

        var snapshots: [CodexAppServerAccountSnapshot] = []
        var lastError: Error?
        for executableURL in executableURLs {
            do {
                let payloads = try await CodexAppServerProcess(
                    executableURL: executableURL,
                    timeout: timeout
                ).readPayloads()
                snapshots.append(try CodexAppServerResponseParser.parse(
                    accountData: payloads.account,
                    rateLimitsData: payloads.rateLimits,
                    usageData: payloads.usage
                ))
            } catch {
                lastError = error
            }
        }

        if snapshots.isEmpty {
            throw lastError ?? CodexAppServerError.invalidResponse
        }
        return snapshots
    }

    public static func discoverExecutable(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL? {
        discoverExecutables(environment: environment, homeDirectory: homeDirectory).first
    }

    public static func discoverExecutables(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [URL] {
        let configured = environment["READYCHECK_CODEX_PATH"].map(URL.init(fileURLWithPath:))
        let candidates = [
            configured,
            URL(fileURLWithPath: "/Applications/Codex.app/Contents/Resources/codex"),
            URL(fileURLWithPath: "/Applications/ChatGPT.app/Contents/Resources/codex"),
            homeDirectory.appendingPathComponent(".local/bin/codex"),
            URL(fileURLWithPath: "/opt/homebrew/bin/codex"),
            URL(fileURLWithPath: "/usr/local/bin/codex")
        ].compactMap { $0 }

        var resolvedPaths = Set<String>()
        return candidates.filter { candidate in
            guard FileManager.default.isExecutableFile(atPath: candidate.path) else { return false }
            let resolvedPath = candidate.resolvingSymlinksInPath().standardizedFileURL.path
            return resolvedPaths.insert(resolvedPath).inserted
        }
    }
}

private struct CodexAppServerPayloads: Sendable {
    let account: Data
    let rateLimits: Data
    let usage: Data?
}

private final class CodexAppServerProcess: @unchecked Sendable {
    private let executableURL: URL
    private let timeout: TimeInterval

    init(executableURL: URL, timeout: TimeInterval) {
        self.executableURL = executableURL
        self.timeout = timeout
    }

    func readPayloads() async throws -> CodexAppServerPayloads {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    continuation.resume(returning: try self.readPayloadsSynchronously())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func readPayloadsSynchronously() throws -> CodexAppServerPayloads {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = executableURL
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw CodexAppServerError.launchFailed
        }
        let timeoutTimer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timeoutTimer.schedule(deadline: .now() + timeout)
        timeoutTimer.setEventHandler {
            if process.isRunning {
                process.terminate()
            }
        }
        timeoutTimer.resume()
        defer {
            timeoutTimer.cancel()
            if process.isRunning {
                process.terminate()
            }
        }

        let deadline = Date().addingTimeInterval(timeout)
        try write(
            [
                "method": "initialize",
                "id": 1,
                "params": [
                    "clientInfo": [
                        "name": "readycheck",
                        "title": "ReadyCheck",
                        "version": ReadyCheckCore.version
                    ]
                ]
            ],
            to: input.fileHandleForWriting
        )

        var buffer = Data()
        var didInitialize = false
        var accountData: Data?
        var rateLimitsData: Data?
        var usageData: Data?
        var usageFinished = false

        while Date() < deadline {
            guard let messageData = try readLine(
                from: output.fileHandleForReading,
                buffer: &buffer,
                deadline: deadline
            ) else {
                break
            }
            guard let message = try JSONSerialization.jsonObject(with: messageData) as? [String: Any]
            else {
                continue
            }

            if let error = message["error"] as? [String: Any],
               let id = message["id"] as? Int,
               [1, 2, 3].contains(id) {
                let code = error["code"].map(String.init(describing:)) ?? "unknown"
                throw CodexAppServerError.requestFailed(code)
            }

            guard let id = message["id"] as? Int else { continue }
            if id == 1, !didInitialize {
                didInitialize = true
                try write(["method": "initialized", "params": [:]], to: input.fileHandleForWriting)
                try write(["method": "account/read", "id": 2, "params": ["refreshToken": false]], to: input.fileHandleForWriting)
                try write(["method": "account/rateLimits/read", "id": 3], to: input.fileHandleForWriting)
                try write(["method": "account/usage/read", "id": 4], to: input.fileHandleForWriting)
            } else if id == 2 {
                accountData = try resultData(from: message)
            } else if id == 3 {
                rateLimitsData = try resultData(from: message)
            } else if id == 4 {
                usageFinished = true
                usageData = try? resultData(from: message)
            }

            if let accountData, let rateLimitsData, usageFinished {
                return CodexAppServerPayloads(
                    account: accountData,
                    rateLimits: rateLimitsData,
                    usage: usageData
                )
            }
        }

        throw Date() >= deadline ? CodexAppServerError.timedOut : CodexAppServerError.invalidResponse
    }

    private func write(_ object: [String: Any], to handle: FileHandle) throws {
        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(0x0A)
        try handle.write(contentsOf: data)
    }

    private func resultData(from message: [String: Any]) throws -> Data {
        guard let result = message["result"] else {
            throw CodexAppServerError.invalidResponse
        }
        return try JSONSerialization.data(withJSONObject: result)
    }

    private func readLine(
        from handle: FileHandle,
        buffer: inout Data,
        deadline: Date
    ) throws -> Data? {
        while Date() < deadline {
            if let newline = buffer.firstIndex(of: 0x0A) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                return line
            }
            let chunk = handle.availableData
            if chunk.isEmpty {
                return buffer.isEmpty ? nil : buffer
            }
            buffer.append(chunk)
        }
        return nil
    }
}

public enum CodexAppServerResponseParser {
    public static func parse(
        accountData: Data,
        rateLimitsData: Data,
        usageData: Data?
    ) throws -> CodexAppServerAccountSnapshot {
        let decoder = JSONDecoder()
        let account = try decoder.decode(AccountResponse.self, from: accountData)
        let limits = try decoder.decode(RateLimitsResponse.self, from: rateLimitsData)
        let usage = try usageData.map { try decoder.decode(UsageResponse.self, from: $0) }

        let mappedSnapshots = limits.rateLimitsByLimitID?.values.sorted {
            ($0.limitID ?? "") < ($1.limitID ?? "")
        }
        let snapshots: [RateLimitResponseSnapshot]
        if let mappedSnapshots, !mappedSnapshots.isEmpty {
            snapshots = mappedSnapshots
        } else {
            snapshots = [limits.rateLimits]
        }

        return CodexAppServerAccountSnapshot(
            email: account.account?.email,
            planName: account.account?.planType,
            rateLimits: snapshots.map(mapRateLimit),
            manualResetCount: limits.rateLimitResetCredits?.availableCount,
            resetCredits: limits.rateLimitResetCredits?.credits?.map {
                CodexAppServerResetCredit(
                    status: $0.status,
                    expiresAt: $0.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
                )
            } ?? [],
            tokenUsage: usage.map {
                AccountTokenUsage(
                    summary: AccountTokenUsageSummary(
                        lifetimeTokens: $0.summary.lifetimeTokens,
                        peakDailyTokens: $0.summary.peakDailyTokens,
                        longestRunningTurnSeconds: $0.summary.longestRunningTurnSeconds,
                        currentStreakDays: $0.summary.currentStreakDays,
                        longestStreakDays: $0.summary.longestStreakDays
                    ),
                    dailyBuckets: ($0.dailyUsageBuckets ?? []).map {
                        AccountTokenUsageDailyBucket(startDate: $0.startDate, tokens: $0.tokens)
                    }
                )
            }
        )
    }

    private static func mapRateLimit(_ snapshot: RateLimitResponseSnapshot) -> CodexAppServerRateLimitSnapshot {
        CodexAppServerRateLimitSnapshot(
            limitID: snapshot.limitID ?? "codex",
            limitName: snapshot.limitName,
            primary: snapshot.primary.map(mapWindow),
            secondary: snapshot.secondary.map(mapWindow),
            creditBalance: snapshot.credits?.balance,
            hasCredits: snapshot.credits?.hasCredits,
            creditsUnlimited: snapshot.credits?.unlimited,
            planName: snapshot.planType,
            reachedStateCode: snapshot.rateLimitReachedType
        )
    }

    private static func mapWindow(_ window: RateLimitResponseWindow) -> CodexAppServerRateLimitWindow {
        CodexAppServerRateLimitWindow(
            usedPercent: window.usedPercent,
            durationMinutes: window.windowDurationMinutes,
            resetsAt: window.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
    }
}

private struct AccountResponse: Decodable {
    let account: Account?

    struct Account: Decodable {
        let email: String?
        let planType: String?
    }
}

private struct RateLimitsResponse: Decodable {
    let rateLimits: RateLimitResponseSnapshot
    let rateLimitsByLimitID: [String: RateLimitResponseSnapshot]?
    let rateLimitResetCredits: ResetCredits?

    enum CodingKeys: String, CodingKey {
        case rateLimits
        case rateLimitsByLimitID = "rateLimitsByLimitId"
        case rateLimitResetCredits
    }

    struct ResetCredits: Decodable {
        let availableCount: Int?
        let credits: [Credit]?
    }

    struct Credit: Decodable {
        let status: String?
        let expiresAt: Int64?
    }
}

private struct RateLimitResponseSnapshot: Decodable {
    let limitID: String?
    let limitName: String?
    let primary: RateLimitResponseWindow?
    let secondary: RateLimitResponseWindow?
    let credits: Credits?
    let planType: String?
    let rateLimitReachedType: String?

    enum CodingKeys: String, CodingKey {
        case limitID = "limitId"
        case limitName
        case primary
        case secondary
        case credits
        case planType
        case rateLimitReachedType
    }

    struct Credits: Decodable {
        let hasCredits: Bool?
        let unlimited: Bool?
        let balance: String?
    }
}

private struct RateLimitResponseWindow: Decodable {
    let usedPercent: Double
    let windowDurationMinutes: Int?
    let resetsAt: Int64?

    enum CodingKeys: String, CodingKey {
        case usedPercent
        case windowDurationMinutes = "windowDurationMins"
        case resetsAt
    }
}

private struct UsageResponse: Decodable {
    let summary: Summary
    let dailyUsageBuckets: [DailyBucket]?

    struct Summary: Decodable {
        let lifetimeTokens: Int64?
        let peakDailyTokens: Int64?
        let longestRunningTurnSeconds: Int64?
        let currentStreakDays: Int64?
        let longestStreakDays: Int64?

        enum CodingKeys: String, CodingKey {
            case lifetimeTokens
            case peakDailyTokens
            case longestRunningTurnSeconds = "longestRunningTurnSec"
            case currentStreakDays
            case longestStreakDays
        }
    }

    struct DailyBucket: Decodable {
        let startDate: String
        let tokens: Int64
    }
}

import Foundation

/// Uses the documented app-server consume RPC, never an inferred HTTP mutation route.
public struct CodexResetCreditClient: ResetCreditServicing {
    private let executableURL: URL?
    private let timeout: TimeInterval
    public init(executableURL: URL? = nil, timeout: TimeInterval = 25) {
        self.executableURL = executableURL
        self.timeout = timeout
    }
    public func read(account: String, token: CodexOAuthToken?) async throws -> CodexAppServerAccountSnapshot {
        let response = try await run(account: account, token: token, credit: nil, key: nil, authorization: nil)
        return response.snapshot
    }
    public func consume(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit, idempotencyKey: String, authorization: ResetCreditAuthorization) async throws -> ResetCreditOutcome {
        let response = try await run(account: account, token: token, credit: credit, key: idempotencyKey, authorization: authorization)
        guard let outcome = response.outcome else { throw CodexAppServerError.invalidResponse }
        return outcome
    }
    private struct Response: Sendable { let snapshot: CodexAppServerAccountSnapshot; let outcome: ResetCreditOutcome? }
    private func run(account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit?, key: String?, authorization: ResetCreditAuthorization?) async throws -> Response {
        guard let executable = executableURL ?? CodexAppServerClient.discoverExecutable(), !account.isEmpty else {
            throw CodexAppServerError.executableUnavailable
        }
        if let token {
            guard token.accountID == account, token.expiresAt > Date(), !token.accessToken.isEmpty else { throw CodexAppServerError.invalidResponse }
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do { continuation.resume(returning: try transact(executable: executable, account: account, token: token, credit: credit, key: key, authorization: authorization)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
    private func transact(executable: URL, account: String, token: CodexOAuthToken?, credit: CodexAppServerResetCredit?, key: String?, authorization: ResetCreditAuthorization?) throws -> Response {
        let process = Process()
        let input = Pipe(), output = Pipe()
        process.executableURL = executable
        process.arguments = ["app-server", "--listen", "stdio://"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        var isolatedHome: URL?
        var launched = false
        if token != nil {
            // External tokens stay in this process's stdin/memory; no native Codex login is replaced.
            let home = FileManager.default.temporaryDirectory.appendingPathComponent("readycheck-reset-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: home, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            isolatedHome = home
            var environment = ProcessInfo.processInfo.environment
            environment["CODEX_HOME"] = home.path
            process.environment = environment
        }
        defer {
            try? input.fileHandleForWriting.close()
            if launched {
                if process.isRunning { process.terminate() }
                process.waitUntilExit()
            }
            if let isolatedHome { try? FileManager.default.removeItem(at: isolatedHome) }
        }
        try process.run()
        launched = true
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler { if process.isRunning { process.terminate() } }
        timer.resume()
        defer { timer.cancel() }
        var buffer = Data()
        var requestID = 0
        func send(_ object: [String: Any]) throws {
            var data = try JSONSerialization.data(withJSONObject: object); data.append(10)
            try input.fileHandleForWriting.write(contentsOf: data)
        }
        func rpc(_ method: String, _ params: [String: Any] = [:]) throws -> Data {
            requestID += 1
            let request: [String: Any] = ["method": method, "id": requestID, "params": params]
            if method == "account/rateLimitResetCredit/consume" {
                guard let authorization else { throw CancellationError() }
                try authorization.whileAllowed { try send(request) }
            } else { try send(request) }
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning && Date() < deadline {
                if let newline = buffer.firstIndex(of: 10) {
                    let line = Data(buffer[..<newline]); buffer.removeSubrange(...newline)
                    guard let message = try JSONSerialization.jsonObject(with: line) as? [String: Any] else { throw CodexAppServerError.invalidResponse }
                    guard message["id"] as? Int == requestID else { continue }
                    guard message["error"] == nil, let result = message["result"] else { throw CodexAppServerError.requestFailed("reset-rpc") }
                    return try JSONSerialization.data(withJSONObject: result)
                }
                let chunk = output.fileHandleForReading.availableData
                guard !chunk.isEmpty, buffer.count + chunk.count <= 4_194_304 else { throw CodexAppServerError.invalidResponse }
                buffer.append(chunk)
            }
            throw CodexAppServerError.timedOut
        }
        _ = try rpc("initialize", ["clientInfo": ["name": "readycheck", "version": ReadyCheckCore.version], "capabilities": ["experimentalApi": token != nil]])
        try send(["method": "initialized", "params": [:]])
        if let token {
            _ = try rpc("account/login/start", ["type": "chatgptAuthTokens", "accessToken": token.accessToken, "chatgptAccountId": account])
        }
        let accountData = try rpc("account/read", ["refreshToken": false])
        let limits = try rpc("account/rateLimits/read")
        let snapshot = try CodexAppServerResponseParser.parse(accountData: accountData, rateLimitsData: limits, usageData: nil)
        guard snapshot.accountID == account else { throw CodexAppServerError.invalidResponse }
        guard let credit, let key else { return Response(snapshot: snapshot, outcome: nil) }
        let now = Date()
        guard !key.isEmpty, let creditID = credit.id, !creditID.isEmpty,
              let expiration = credit.expiresAt, expiration > now, expiration.timeIntervalSince(now) <= 3600,
              snapshot.resetCredits.filter({ $0.id == creditID }).count == 1,
              snapshot.resetCredits.contains(where: { $0.id == creditID && $0.resetType == "codexRateLimits" && $0.status == "available" && $0.expiresAt == expiration }) else {
            throw CodexAppServerError.invalidResponse
        }
        let outcomeData = try rpc("account/rateLimitResetCredit/consume", ["creditId": creditID, "idempotencyKey": key])
        struct Result: Decodable { let outcome: ResetCreditOutcome }
        let outcome = try JSONDecoder().decode(Result.self, from: outcomeData).outcome
        // Never infer quota windows from a successful consume response.
        _ = try rpc("account/rateLimits/read")
        return Response(snapshot: snapshot, outcome: outcome)
    }
}

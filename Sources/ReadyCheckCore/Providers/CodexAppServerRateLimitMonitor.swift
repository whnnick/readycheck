import Foundation
import Darwin

public enum CodexAppServerMonitorFailure: String, Equatable, Sendable {
    case executableUnavailable
    case launchFailed
    case handshakeTimedOut
    case handshakeRejected
    case protocolError
    case connectionClosed
}

public enum CodexAppServerMonitorStatus: Equatable, Sendable {
    case stopped
    case connecting
    case connected
    case retrying(failure: CodexAppServerMonitorFailure, attempt: Int)
}

public final class CodexAppServerRateLimitMonitor: @unchecked Sendable {
    private let executableURL: URL?
    private let candidateExecutableURLs: [URL]?
    private let initialReconnectDelay: TimeInterval
    private let maximumReconnectDelay: TimeInterval
    private let handshakeTimeout: TimeInterval
    private let lock = NSLock()
    private var generation = 0
    private var isRunning = false
    private var workerTask: Task<Void, Never>?
    private var process: Process?

    public init(
        executableURL: URL? = nil,
        candidateExecutableURLs: [URL]? = nil,
        reconnectDelay: TimeInterval = 2,
        maximumReconnectDelay: TimeInterval = 30,
        handshakeTimeout: TimeInterval = 5
    ) {
        self.executableURL = executableURL
        self.candidateExecutableURLs = candidateExecutableURLs
        self.initialReconnectDelay = max(0.1, reconnectDelay)
        self.maximumReconnectDelay = max(self.initialReconnectDelay, maximumReconnectDelay)
        self.handshakeTimeout = max(0.1, handshakeTimeout)
    }

    public func start(onRateLimitsUpdated: @escaping @Sendable () -> Void) {
        start(onStatusChanged: { _ in }, onRateLimitsUpdated: onRateLimitsUpdated)
    }

    public func start(
        onStatusChanged: @escaping @Sendable (CodexAppServerMonitorStatus) -> Void,
        onRateLimitsUpdated: @escaping @Sendable () -> Void
    ) {
        lock.lock()
        guard !isRunning else {
            lock.unlock()
            return
        }
        isRunning = true
        generation += 1
        let activeGeneration = generation
        let task = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.run(
                generation: activeGeneration,
                onStatusChanged: onStatusChanged,
                onRateLimitsUpdated: onRateLimitsUpdated
            )
        }
        workerTask = task
        lock.unlock()
    }

    public func stop() {
        lock.lock()
        generation += 1
        isRunning = false
        let task = workerTask
        workerTask = nil
        let activeProcess = process
        process = nil
        lock.unlock()

        task?.cancel()
        if activeProcess?.isRunning == true { activeProcess?.terminate() }
    }

    private func run(
        generation activeGeneration: Int,
        onStatusChanged: @escaping @Sendable (CodexAppServerMonitorStatus) -> Void,
        onRateLimitsUpdated: @escaping @Sendable () -> Void
    ) async {
        var retryAttempt = 0
        while shouldContinue(generation: activeGeneration), !Task.isCancelled {
            let executables = executableURL.map { [$0] }
                ?? candidateExecutableURLs
                ?? CodexAppServerClient.discoverExecutables()
            guard !executables.isEmpty else {
                retryAttempt += 1
                onStatusChanged(.retrying(failure: .executableUnavailable, attempt: retryAttempt))
                await waitBeforeRetry(attempt: retryAttempt)
                continue
            }

            var lastFailure: CodexAppServerMonitorFailure = .connectionClosed
            var didConnect = false
            for executable in executables where shouldContinue(generation: activeGeneration) && !Task.isCancelled {
                onStatusChanged(.connecting)
                lastFailure = monitor(
                    executableURL: executable,
                    generation: activeGeneration,
                    onConnected: {
                        didConnect = true
                        retryAttempt = 0
                        onStatusChanged(.connected)
                    },
                    onRateLimitsUpdated: onRateLimitsUpdated
                )
                if didConnect { break }
            }

            guard shouldContinue(generation: activeGeneration), !Task.isCancelled else { break }
            retryAttempt += 1
            onStatusChanged(.retrying(failure: lastFailure, attempt: retryAttempt))
            await waitBeforeRetry(attempt: retryAttempt)
        }

        if finish(generation: activeGeneration) {
            onStatusChanged(.stopped)
        }
    }

    private func waitBeforeRetry(attempt: Int) async {
        let exponent = min(max(0, attempt - 1), 8)
        let delay = min(initialReconnectDelay * pow(2, Double(exponent)), maximumReconnectDelay)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    private func monitor(
        executableURL: URL,
        generation activeGeneration: Int,
        onConnected: () -> Void,
        onRateLimitsUpdated: @escaping @Sendable () -> Void
    ) -> CodexAppServerMonitorFailure {
        let child = Process()
        let input = Pipe()
        let output = Pipe()
        child.executableURL = executableURL
        child.arguments = ["app-server", "--stdio"]
        child.standardInput = input
        child.standardOutput = output
        child.standardError = FileHandle.nullDevice

        guard register(child, generation: activeGeneration) else { return .connectionClosed }
        defer { unregister(child, generation: activeGeneration) }

        guard shouldContinue(generation: activeGeneration) else { return .connectionClosed }
        do {
            try child.run()
        } catch {
            return .launchFailed
        }

        let deadline = Date().addingTimeInterval(handshakeTimeout)
        let timeoutTimer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timeoutTimer.schedule(deadline: .now() + handshakeTimeout)
        timeoutTimer.setEventHandler {
            if child.isRunning { child.terminate() }
        }
        timeoutTimer.resume()
        var timeoutTimerCancelled = false
        defer {
            if !timeoutTimerCancelled { timeoutTimer.cancel() }
            if child.isRunning { child.terminate() }
        }

        do {
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
            var initialized = false
            let descriptor = output.fileHandleForReading.fileDescriptor
            let descriptorFlags = fcntl(descriptor, F_GETFL)
            if descriptorFlags >= 0 { _ = fcntl(descriptor, F_SETFL, descriptorFlags | O_NONBLOCK) }
            while shouldContinue(generation: activeGeneration), child.isRunning {
                guard let data = readLine(
                    from: output.fileHandleForReading,
                    buffer: &buffer,
                    deadline: initialized ? nil : deadline,
                    shouldContinue: { self.shouldContinue(generation: activeGeneration) && child.isRunning }
                ) else { break }
                guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }

                if (message["id"] as? Int) == 1, !initialized {
                    guard message["error"] == nil, message["result"] != nil else {
                        return .handshakeRejected
                    }
                    initialized = true
                    timeoutTimer.cancel()
                    timeoutTimerCancelled = true
                    try write(["method": "initialized", "params": [:]], to: input.fileHandleForWriting)
                    onConnected()
                } else if initialized,
                          let method = message["method"] as? String,
                          method == "account/rateLimits/updated" || method == "account/updated" {
                    onRateLimitsUpdated()
                }
            }
            if !initialized {
                return Date() >= deadline ? .handshakeTimedOut : .protocolError
            }
            return .connectionClosed
        } catch {
            return .protocolError
        }
    }

    private func register(_ child: Process, generation activeGeneration: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard generation == activeGeneration, isRunning else { return false }
        process = child
        return true
    }

    private func unregister(_ child: Process, generation activeGeneration: Int) {
        lock.lock()
        if generation == activeGeneration, process === child { process = nil }
        lock.unlock()
    }

    private func shouldContinue(generation activeGeneration: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return generation == activeGeneration && isRunning
    }

    private func finish(generation activeGeneration: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if generation == activeGeneration {
            isRunning = false
            workerTask = nil
            return true
        }
        return false
    }

    private func write(_ object: [String: Any], to handle: FileHandle) throws {
        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(0x0A)
        try handle.write(contentsOf: data)
    }

    private func readLine(
        from handle: FileHandle,
        buffer: inout Data,
        deadline: Date?,
        shouldContinue: () -> Bool
    ) -> Data? {
        var chunk = [UInt8](repeating: 0, count: 4_096)
        while true {
            if let newline = buffer.firstIndex(of: 0x0A) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                return line
            }
            guard shouldContinue() else { return buffer.isEmpty ? nil : buffer }
            if let deadline, Date() >= deadline { return nil }
            let count = chunk.withUnsafeMutableBytes {
                Darwin.read(handle.fileDescriptor, $0.baseAddress, $0.count)
            }
            if count > 0 {
                buffer.append(contentsOf: chunk.prefix(count))
            } else if count == 0 {
                return buffer.isEmpty ? nil : buffer
            } else if errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR {
                Thread.sleep(forTimeInterval: 0.01)
            } else {
                return buffer.isEmpty ? nil : buffer
            }
        }
    }
}

import Foundation

public final class CodexAppServerRateLimitMonitor: @unchecked Sendable {
    private let executableURL: URL?
    private let reconnectDelay: TimeInterval
    private let lock = NSLock()
    private var generation = 0
    private var isRunning = false
    private var workerTask: Task<Void, Never>?
    private var process: Process?

    public init(
        executableURL: URL? = nil,
        reconnectDelay: TimeInterval = 30
    ) {
        self.executableURL = executableURL
        self.reconnectDelay = max(0.1, reconnectDelay)
    }

    public func start(onRateLimitsUpdated: @escaping @Sendable () -> Void) {
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
            await self.run(generation: activeGeneration, onRateLimitsUpdated: onRateLimitsUpdated)
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
        if activeProcess?.isRunning == true {
            activeProcess?.terminate()
        }
    }

    private func run(
        generation activeGeneration: Int,
        onRateLimitsUpdated: @escaping @Sendable () -> Void
    ) async {
        while shouldContinue(generation: activeGeneration), !Task.isCancelled {
            if let executable = executableURL ?? CodexAppServerClient.discoverExecutable() {
                monitor(
                    executableURL: executable,
                    generation: activeGeneration,
                    onRateLimitsUpdated: onRateLimitsUpdated
                )
            }

            guard shouldContinue(generation: activeGeneration), !Task.isCancelled else { break }
            try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))
        }

        finish(generation: activeGeneration)
    }

    private func monitor(
        executableURL: URL,
        generation activeGeneration: Int,
        onRateLimitsUpdated: @escaping @Sendable () -> Void
    ) {
        let child = Process()
        let input = Pipe()
        let output = Pipe()
        child.executableURL = executableURL
        child.arguments = ["app-server", "--stdio"]
        child.standardInput = input
        child.standardOutput = output
        child.standardError = FileHandle.nullDevice

        guard register(child, generation: activeGeneration) else { return }
        defer { unregister(child, generation: activeGeneration) }

        do {
            guard shouldContinue(generation: activeGeneration) else { return }
            try child.run()
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
            while shouldContinue(generation: activeGeneration), child.isRunning {
                guard let data = readLine(from: output.fileHandleForReading, buffer: &buffer) else { break }
                guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }

                if (message["id"] as? Int) == 1 {
                    try write(["method": "initialized", "params": [:]], to: input.fileHandleForWriting)
                } else if message["method"] as? String == "account/rateLimits/updated" {
                    onRateLimitsUpdated()
                }
            }
        } catch {
            // Polling remains the fallback when the app-server is unavailable or exits.
        }

        if child.isRunning {
            child.terminate()
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
        if generation == activeGeneration, process === child {
            process = nil
        }
        lock.unlock()
    }

    private func shouldContinue(generation activeGeneration: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return generation == activeGeneration && isRunning
    }

    private func finish(generation activeGeneration: Int) {
        lock.lock()
        if generation == activeGeneration {
            isRunning = false
            workerTask = nil
        }
        lock.unlock()
    }

    private func write(_ object: [String: Any], to handle: FileHandle) throws {
        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(0x0A)
        try handle.write(contentsOf: data)
    }

    private func readLine(from handle: FileHandle, buffer: inout Data) -> Data? {
        while true {
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
    }
}

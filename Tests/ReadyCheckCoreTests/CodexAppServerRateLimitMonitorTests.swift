import XCTest
@testable import ReadyCheckCore

final class CodexAppServerRateLimitMonitorTests: XCTestCase {
    func testMonitorEmitsAccountAndRateLimitUpdateNotifications() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let executable = directory.appendingPathComponent("fake-codex")
        let script = """
        #!/bin/sh
        IFS= read -r initialize
        printf '%s\\n' '{"id":1,"result":{}}'
        IFS= read -r initialized
        printf '%s\\n' '{"method":"account/updated","params":{}}'
        printf '%s\\n' '{"method":"account/rateLimits/updated","params":{"rateLimits":{"limitId":"codex"}}}'
        sleep 5
        """
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let eventReceived = expectation(description: "rate limit event received")
        eventReceived.expectedFulfillmentCount = 2
        let monitor = CodexAppServerRateLimitMonitor(
            executableURL: executable,
            reconnectDelay: 10
        )

        monitor.start {
            eventReceived.fulfill()
        }
        wait(for: [eventReceived], timeout: 2)
        monitor.stop()
    }

    func testMonitorRejectsInitializationErrorWithoutEmittingUpdate() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = try makeExecutable(
            in: directory,
            name: "rejected-codex",
            script: """
            #!/bin/sh
            IFS= read -r initialize
            printf '%s\\n' '{"id":1,"error":{"code":-32600,"message":"unsupported"}}'
            sleep 1
            """
        )
        let rejected = expectation(description: "handshake rejection reported")
        let event = expectation(description: "no update emitted")
        event.isInverted = true
        let monitor = CodexAppServerRateLimitMonitor(
            executableURL: executable,
            reconnectDelay: 10,
            handshakeTimeout: 0.5
        )

        monitor.start(onStatusChanged: { status in
            if status == .retrying(failure: .handshakeRejected, attempt: 1) {
                rejected.fulfill()
            }
        }, onRateLimitsUpdated: {
            event.fulfill()
        })

        wait(for: [rejected, event], timeout: 1)
        monitor.stop()
    }

    func testMonitorFallsBackWhenFirstCandidateDoesNotCompleteHandshake() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let silent = try makeExecutable(
            in: directory,
            name: "silent-codex",
            script: """
            #!/bin/sh
            IFS= read -r initialize
            sleep 5
            """
        )
        let working = try makeExecutable(
            in: directory,
            name: "working-codex",
            script: """
            #!/bin/sh
            IFS= read -r initialize
            printf '%s\\n' '{"id":1,"result":{}}'
            IFS= read -r initialized
            printf '%s\\n' '{"method":"account/rateLimits/updated","params":{}}'
            sleep 5
            """
        )
        let connected = expectation(description: "fallback connected")
        let event = expectation(description: "fallback emitted update")
        let monitor = CodexAppServerRateLimitMonitor(
            candidateExecutableURLs: [silent, working],
            reconnectDelay: 10,
            handshakeTimeout: 1
        )

        monitor.start(onStatusChanged: { status in
            if status == .connected {
                connected.fulfill()
            }
        }, onRateLimitsUpdated: {
            event.fulfill()
        })

        wait(for: [connected, event], timeout: 4)
        monitor.stop()
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeExecutable(
        in directory: URL,
        name: String,
        script: String
    ) throws -> URL {
        let executable = directory.appendingPathComponent(name)
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        return executable
    }
}

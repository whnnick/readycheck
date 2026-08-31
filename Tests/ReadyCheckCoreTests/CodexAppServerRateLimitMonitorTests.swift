import XCTest
@testable import ReadyCheckCore

final class CodexAppServerRateLimitMonitorTests: XCTestCase {
    func testMonitorEmitsOnlyRateLimitUpdateNotifications() throws {
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
        eventReceived.expectedFulfillmentCount = 1
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
}

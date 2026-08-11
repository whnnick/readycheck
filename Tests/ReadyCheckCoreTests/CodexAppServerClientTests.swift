import XCTest
@testable import ReadyCheckCore

final class CodexAppServerClientTests: XCTestCase {
    func testParserMapsDynamicWindowsCreditsResetsAndTokenUsage() throws {
        let snapshot = try CodexAppServerResponseParser.parse(
            accountData: Data(
                #"{"account":{"type":"chatgpt","email":"user@example.com","planType":"plus"}}"#.utf8
            ),
            rateLimitsData: Data(
                """
                {
                  "rateLimits": {
                    "limitId": "codex",
                    "primary": {
                      "usedPercent": 24,
                      "windowDurationMins": 300,
                      "resetsAt": 1785261600
                    },
                    "secondary": {
                      "usedPercent": 31,
                      "windowDurationMins": 10080,
                      "resetsAt": 1785686400
                    },
                    "credits": {
                      "hasCredits": true,
                      "unlimited": false,
                      "balance": "12.5"
                    },
                    "planType": "plus"
                  },
                  "rateLimitsByLimitId": {
                    "codex": {
                      "limitId": "codex",
                      "primary": {
                        "usedPercent": 24,
                        "windowDurationMins": 300,
                        "resetsAt": 1785261600
                      },
                      "secondary": {
                        "usedPercent": 31,
                        "windowDurationMins": 10080,
                        "resetsAt": 1785686400
                      },
                      "credits": {
                        "hasCredits": true,
                        "unlimited": false,
                        "balance": "12.5"
                      },
                      "planType": "plus"
                    }
                  },
                  "rateLimitResetCredits": {
                    "availableCount": 1,
                    "credits": [
                      {
                        "status": "available",
                        "expiresAt": 1785686400
                      }
                    ]
                  }
                }
                """.utf8
            ),
            usageData: Data(
                """
                {
                  "summary": {
                    "lifetimeTokens": 123456,
                    "peakDailyTokens": 45000,
                    "longestRunningTurnSec": 180,
                    "currentStreakDays": 3,
                    "longestStreakDays": 9
                  },
                  "dailyUsageBuckets": [
                    {"startDate":"2026-07-28","tokens":12000},
                    {"startDate":"2026-07-29","tokens":9000}
                  ]
                }
                """.utf8
            )
        )

        XCTAssertEqual(snapshot.email, "user@example.com")
        XCTAssertEqual(snapshot.planName, "plus")
        XCTAssertEqual(snapshot.rateLimits.count, 1)
        XCTAssertEqual(snapshot.rateLimits[0].primary?.durationMinutes, 300)
        XCTAssertEqual(snapshot.rateLimits[0].secondary?.durationMinutes, 10_080)
        XCTAssertEqual(snapshot.rateLimits[0].creditBalance, "12.5")
        XCTAssertEqual(snapshot.manualResetCount, 1)
        XCTAssertEqual(snapshot.resetCredits.count, 1)
        XCTAssertEqual(snapshot.tokenUsage?.summary.lifetimeTokens, 123_456)
        XCTAssertEqual(snapshot.tokenUsage?.dailyBuckets.map(\.tokens), [12_000, 9_000])
    }

    func testParserKeepsMultipleLimitGroups() throws {
        let snapshot = try CodexAppServerResponseParser.parse(
            accountData: Data(#"{"account":{"email":"user@example.com"}}"#.utf8),
            rateLimitsData: Data(
                """
                {
                  "rateLimits": {"limitId":"codex","primary":{"usedPercent":10}},
                  "rateLimitsByLimitId": {
                    "codex": {"limitId":"codex","primary":{"usedPercent":10}},
                    "codex_spark": {"limitId":"codex_spark","primary":{"usedPercent":20}}
                  },
                  "rateLimitResetCredits": null
                }
                """.utf8
            ),
            usageData: nil
        )

        XCTAssertEqual(snapshot.rateLimits.map(\.limitID), ["codex", "codex_spark"])
        XCTAssertNil(snapshot.manualResetCount)
    }

    func testParserDistinguishesZeroResetCreditsFromUnavailableDetails() throws {
        let zero = try CodexAppServerResponseParser.parse(
            accountData: Data(#"{"account":{"email":"user@example.com"}}"#.utf8),
            rateLimitsData: Data(
                #"{"rateLimits":{"limitId":"codex","primary":{"usedPercent":10}},"rateLimitResetCredits":{"availableCount":0,"credits":[]}}"#.utf8
            ),
            usageData: nil
        )
        let unavailable = try CodexAppServerResponseParser.parse(
            accountData: Data(#"{"account":{"email":"user@example.com"}}"#.utf8),
            rateLimitsData: Data(
                #"{"rateLimits":{"limitId":"codex","primary":{"usedPercent":10}},"rateLimitResetCredits":null}"#.utf8
            ),
            usageData: nil
        )

        XCTAssertEqual(zero.manualResetCount, 0)
        XCTAssertNil(unavailable.manualResetCount)
    }

    func testExecutableDiscoveryHonorsExplicitPath() throws {
        let executable = URL(fileURLWithPath: "/bin/sh")
        let discovered = CodexAppServerClient.discoverExecutable(
            environment: ["READYCHECK_CODEX_PATH": executable.path],
            homeDirectory: URL(fileURLWithPath: "/tmp/unused")
        )

        XCTAssertEqual(discovered, executable)
    }

    func testClientReadsSmallResponsesWithoutWaitingForProcessExit() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let executable = directory.appendingPathComponent("fake-codex")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let script = """
        #!/bin/sh
        IFS= read -r initialize
        printf '%s\\n' '{"id":1,"result":{"userAgent":"test"}}'
        IFS= read -r initialized
        IFS= read -r account
        IFS= read -r rate_limits
        IFS= read -r usage
        printf '%s\\n' '{"id":2,"result":{"account":{"email":"user@example.com","planType":"plus"}}}'
        printf '%s\\n' '{"id":3,"result":{"rateLimits":{"limitId":"codex","primary":{"usedPercent":10}}}}'
        printf '%s\\n' '{"id":4,"result":{"summary":{"lifetimeTokens":100},"dailyUsageBuckets":[]}}'
        sleep 2
        """
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let snapshot = try await CodexAppServerClient(
            executableURL: executable,
            timeout: 1
        ).readAccountSnapshot()

        XCTAssertEqual(snapshot.email, "user@example.com")
        XCTAssertEqual(snapshot.rateLimits.first?.primary?.usedPercent, 10)
        XCTAssertEqual(snapshot.tokenUsage?.summary.lifetimeTokens, 100)
    }
}

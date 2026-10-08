import XCTest
@testable import ReadyCheckCore

final class QuotaDataDiagnosticsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_900_000_000)

    func testMissingFieldsDoNotInvalidateQuotaOrInventSubscriptionDates() {
        let value = snapshot()
        XCTAssertTrue(value.canShowPercentages(now: now))
        XCTAssertEqual(QuotaDataDiagnostics.issueKeys(snapshot: value, now: now), ["dataStatus.permissionMissing", "dataStatus.subscriptionMissing"])
        XCTAssertNil(value.details?.subscriptionRenewalAt)
    }

    func testStaleAndUnavailableHaveDifferentReasons() {
        XCTAssertTrue(QuotaDataDiagnostics.issueKeys(snapshot: snapshot(), now: now.addingTimeInterval(61)).contains("dataStatus.stale"))
        XCTAssertEqual(QuotaDataDiagnostics.issueKeys(snapshot: snapshot(status: .error), now: now), ["dataStatus.unavailable"])
        XCTAssertEqual(QuotaDataDiagnostics.issueKeys(snapshot: nil, now: now), ["dataStatus.noSnapshot"])
    }

    func testVerifiedCompleteDataHasNoMissingFieldExplanation() {
        XCTAssertTrue(QuotaDataDiagnostics.issueKeys(snapshot: snapshot(permission: true, renewal: now.addingTimeInterval(86400)), now: now).isEmpty)
        XCTAssertTrue(QuotaDataDiagnostics.issueKeys(snapshot: snapshot(permission: false), now: now).contains("dataStatus.permissionBlocked"))
    }

    func testPastSubscriptionDateIsExplainedAsHistorical() {
        let issues = QuotaDataDiagnostics.issueKeys(snapshot: snapshot(permission: true, renewal: now.addingTimeInterval(-60)), now: now)
        XCTAssertEqual(issues, ["dataStatus.subscriptionHistorical"])
    }

    private func snapshot(status: ProviderStatus = .available, permission: Bool? = nil, renewal: Date? = nil) -> ProviderQuotaSnapshot {
        ProviderQuotaSnapshot(providerId: "codex-oauth", displayName: "Codex", status: status, source: .appServer, refreshedAt: now, staleAfter: now.addingTimeInterval(60), windows: [QuotaWindow(id: "weekly", labelKey: "quota.sevenDay", kind: .rateLimit, used: 20, limit: 100, remaining: 80, unit: .percent, resetAt: now.addingTimeInterval(3600), confidence: .verified)], errors: [], details: ProviderQuotaDetails(subscriptionRenewalAt: renewal), ordinaryUsageAllowed: permission)
    }
}

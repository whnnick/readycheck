import XCTest
@testable import ReadyCheckCore

final class LocalizationServiceTests: XCTestCase {
    func testEnglishAndChineseContainRequiredKeys() {
        let requiredKeys = [
            "app.name",
            "action.refresh",
            "action.pinWidget",
            "action.hideWidget",
            "action.unpinWidget",
            "action.settings",
            "action.connect",
            "action.connectCodex",
            "action.disconnect",
            "action.completeAuthorization",
            "action.closeWindow",
            "action.quit",
            "action.checkForUpdates",
            "action.downloadUpdate",
            "about.title",
            "about.menuItem",
            "about.version",
            "about.safeRefresh",
            "about.source",
            "about.precision",
            "about.copyright",
            "settings.general",
            "settings.account",
            "settings.preferences",
            "settings.language",
            "settings.refreshInterval",
            "settings.refreshHelp",
            "settings.updates",
            "dashboard.subtitle",
            "dashboard.refreshCadence",
            "productBrief.title",
            "productBrief.summary",
            "productBrief.safeRefresh",
            "productBrief.keychain",
            "productBrief.surfaces",
            "settings.codex",
            "settings.quota",
            "settings.providers",
            "settings.providersHelp",
            "provider.mock",
            "provider.mock.detail",
            "provider.localCodex",
            "provider.localCodex.detail",
            "provider.codexOAuth",
            "provider.codexOAuth.detail",
            "quota.error.oauthRequired",
            "quota.error.endpointCalibrationRequired",
            "quota.error.unsafeEndpoint",
            "quota.error.tokenRefreshFailed",
            "quota.error.accountIdUnavailable",
            "quota.error.parserUnavailable",
            "quota.error.requestFailed",
            "oauth.status.notConnected",
            "oauth.status.waitingForCallback",
            "oauth.status.exchanging",
            "oauth.status.connected",
            "oauth.status.failed",
            "oauth.account.connectedAs",
            "oauth.callback.placeholder",
            "oauth.callback.help",
            "oauth.callback.listening",
            "oauth.callback.manualFallback",
            "oauth.step.openBrowser",
            "oauth.step.waitForCallback",
            "oauth.step.refreshAfterConnect",
            "oauth.error.missingSession",
            "oauth.error.stateMismatch",
            "oauth.error.invalidCallback",
            "oauth.error.callbackFailed",
            "oauth.error.tokenExchangeFailed",
            "oauth.error.unsafeEndpoint",
            "oauth.error.authorizationFailed",
            "refreshInterval.1m",
            "refreshInterval.3m",
            "refreshInterval.5m",
            "status.available",
            "status.estimated",
            "status.unavailable",
            "status.error",
            "status.needsCalibration",
            "status.live",
            "status.autoUpdate",
            "status.lastUpdated",
            "status.notUpdatedYet",
            "status.refreshing",
            "status.safeRefresh",
            "update.checking",
            "update.available",
            "update.upToDate",
            "update.failed",
            "empty.quota.title",
            "empty.quota.message",
            "empty.quota.codexMessage",
            "empty.quota.connectedMessage",
            "source.mock",
            "source.local",
            "source.usageAPI",
            "source.costAPI",
            "source.oauthAPI",
            "source.manual",
            "confidence.verified",
            "confidence.estimated",
            "confidence.manual",
            "confidence.unknown",
            "quota.remaining",
            "quota.resetAt",
            "quota.account",
            "quota.plan",
            "quota.subscriptionRenewal",
            "quota.manualResetCount",
            "quota.manualResetExpires",
            "quota.manualResetIndex",
            "quota.manualResetTimes",
            "quota.notProvided",
            "quota.dataSource",
            "quota.refreshedAt",
            "quota.validUntil",
            "quota.window.codex.5h",
            "quota.window.codex.7d",
            "quota.window.codex.primary",
            "quota.window.codex.secondary",
            "quota.window.claude.monthly",
            "quota.window.openai.monthly"
        ]

        for language in AppLanguage.allCases {
            let service = LocalizationService(language: language)

            for key in requiredKeys {
                let text = service.text(key)
                XCTAssertFalse(text.isEmpty, "Missing text for \(key) in \(language.rawValue)")
                XCTAssertNotEqual(text, key, "Unexpected fallback for \(key) in \(language.rawValue)")
            }
        }
    }

    func testChineseRefreshText() {
        let service = LocalizationService(language: .zhCN)
        XCTAssertEqual(service.text("action.refresh"), "刷新")
    }

    func testEnglishRefreshText() {
        let service = LocalizationService(language: .enUS)
        XCTAssertEqual(service.text("action.refresh"), "Refresh")
    }

    func testChineseMetadataLabels() {
        let service = LocalizationService(language: .zhCN)

        XCTAssertEqual(service.text("source.mock"), "模拟")
        XCTAssertEqual(service.text("provider.mock"), "模拟数据")
        XCTAssertEqual(service.text("provider.localCodex"), "本地 Codex")
        XCTAssertEqual(service.text("provider.codexOAuth"), "Codex OAuth")
        XCTAssertEqual(service.text("quota.error.oauthRequired"), "请先在设置里连接 Codex，连接后显示额度。")
        XCTAssertEqual(service.text("oauth.status.connected"), "已连接")
        XCTAssertEqual(service.text("oauth.error.stateMismatch"), "回调和本次登录不匹配，请重新连接。")
        XCTAssertEqual(service.text("source.usageAPI"), "用量 API")
        XCTAssertEqual(service.text("source.costAPI"), "费用 API")
        XCTAssertEqual(service.text("status.autoUpdate"), "自动刷新")
        XCTAssertEqual(service.text("confidence.estimated"), "估算")
        XCTAssertEqual(service.text("quota.remaining"), "剩余")
        XCTAssertEqual(service.text("quota.plan"), "套餐")
        XCTAssertEqual(service.text("quota.manualResetCount"), "主动重置次数")
        XCTAssertEqual(service.text("quota.dataSource"), "来源")
        XCTAssertEqual(service.text("quota.validUntil"), "有效期")
        XCTAssertEqual(service.text("empty.quota.codexMessage"), "请先在设置里连接 Codex OAuth，并粘贴回调 URL 完成授权。")
    }
}

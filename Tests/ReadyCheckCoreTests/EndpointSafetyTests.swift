import XCTest
@testable import ReadyCheckCore

final class EndpointSafetyTests: XCTestCase {
    func testOpenAIInferenceEndpointsAreDeniedForRefresh() throws {
        let responsesURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/responses"))
        let chatCompletionsURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(responsesURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(chatCompletionsURL))
    }

    func testAnthropicInferenceEndpointIsDeniedForRefresh() throws {
        let messagesURL = try XCTUnwrap(URL(string: "https://api.anthropic.com/v1/messages"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(messagesURL))
    }

    func testAnthropicSubstringEndpointsAreDeniedForRefresh() throws {
        let usageURL = try XCTUnwrap(URL(string: "https://api.anthropic.com/v1/messages/usage"))
        let rateURL = try XCTUnwrap(URL(string: "https://api.anthropic.com/v1/rate_limit"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(usageURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(rateURL))
    }

    func testOpenAIAllowListRequiresPathSegmentBoundary() throws {
        let usagefulURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/usageful"))
        let costsExtraURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/costs-extra"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(usagefulURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(costsExtraURL))
    }

    func testOpenAIRefreshEndpointRequiresHTTPS() throws {
        let usageURL = try XCTUnwrap(URL(string: "http://api.openai.com/v1/organization/usage/completions"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(usageURL))
    }

    func testOpenAIRefreshPathsRejectTraversalEscapes() throws {
        let dotSegmentURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/usage/../../responses"))
        let encodedDotSegmentURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/usage/%2E%2E/%2E%2E/responses"))
        let encodedSlashTraversalURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/usage/%2F..%2F..%2Fresponses"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(dotSegmentURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(encodedDotSegmentURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(encodedSlashTraversalURL))
    }

    func testUsageCostAndLocalFileEndpointsAreAllowedForRefresh() throws {
        let usageURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/usage/completions"))
        let costsURL = try XCTUnwrap(URL(string: "https://api.openai.com/v1/organization/costs"))
        let codexUsageURL = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/usage"))
        let localFileURL = URL(fileURLWithPath: "/Users/example/.codex/sqlite/state_5.sqlite")

        XCTAssertTrue(EndpointSafety.isAllowedForRefresh(usageURL))
        XCTAssertTrue(EndpointSafety.isAllowedForRefresh(costsURL))
        XCTAssertTrue(EndpointSafety.isAllowedForRefresh(codexUsageURL))
        XCTAssertTrue(EndpointSafety.isLocalFileAllowed(localFileURL))
    }

    func testCodexUsageAllowListRequiresExactPath() throws {
        let responsesURL = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/codex/responses"))
        let usageExtraURL = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/usage-extra"))
        let wrongHostURL = try XCTUnwrap(URL(string: "https://example.com/backend-api/wham/usage"))

        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(responsesURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(usageExtraURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(wrongHostURL))
    }

    func testCodexOAuthEndpointsAreAllowedOnlyForOAuthFlow() throws {
        let authorizeURL = try XCTUnwrap(URL(string: "https://auth.openai.com/oauth/authorize"))
        let tokenURL = try XCTUnwrap(URL(string: "https://auth.openai.com/oauth/token"))
        let wrongHostURL = try XCTUnwrap(URL(string: "https://api.openai.com/oauth/token"))
        let wrongPathURL = try XCTUnwrap(URL(string: "https://auth.openai.com/v1/responses"))

        XCTAssertTrue(EndpointSafety.isAllowedForOAuth(authorizeURL))
        XCTAssertTrue(EndpointSafety.isAllowedForOAuth(tokenURL))
        XCTAssertFalse(EndpointSafety.isAllowedForOAuth(wrongHostURL))
        XCTAssertFalse(EndpointSafety.isAllowedForOAuth(wrongPathURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(authorizeURL))
        XCTAssertFalse(EndpointSafety.isAllowedForRefresh(tokenURL))
    }
}

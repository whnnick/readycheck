import XCTest
@testable import ReadyCheckApp

final class ServiceCatalogTests: XCTestCase {
    func testCatalogHasApprovedServicesInTwoBatches() {
        XCTAssertEqual(ServiceCatalog.entries.map(\.id), ["codex", "claude", "gemini", "deepseek", "cursor", "copilot", "bailian", "glm", "kimi", "minimax"])
        XCTAssertEqual(ServiceCatalog.filtered(query: "", batch: 1).count, 5)
        XCTAssertEqual(ServiceCatalog.filtered(query: "", batch: 2).count, 5)
        XCTAssertEqual(ServiceCatalog.entries.filter(\.supported).map(\.id), ["codex", "deepseek"])
    }

    func testSearchMatchesAliasesAndRespectsBatch() {
        XCTAssertEqual(ServiceCatalog.filtered(query: "百炼", batch: 0).map(\.id), ["bailian"])
        XCTAssertEqual(ServiceCatalog.filtered(query: "  CLAUDE  ", batch: 1).map(\.id), ["claude"])
        XCTAssertTrue(ServiceCatalog.filtered(query: "claude", batch: 2).isEmpty)
        XCTAssertTrue(ServiceCatalog.filtered(query: "openrouter", batch: 0).isEmpty)
    }
}

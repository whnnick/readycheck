import Foundation
import XCTest
@testable import ReadyCheckCore

final class UpdateCheckerTests: XCTestCase {
    func testSoftwareVersionComparesSemanticTags() {
        XCTAssertLessThan(SoftwareVersion("0.1.46"), SoftwareVersion("v0.1.47"))
        XCTAssertLessThan(SoftwareVersion("0.1.9"), SoftwareVersion("0.1.10"))
        XCTAssertEqual(SoftwareVersion("v1.2.0"), SoftwareVersion("1.2"))
    }

    func testCheckerReturnsUpdateWhenLatestReleaseIsNewer() async throws {
        let loader = UpdateRecordingHTTPDataLoader(
            data: Data(
                """
                {
                  "tag_name": "v0.1.47",
                  "html_url": "https://github.com/whnnick/readycheck/releases/tag/v0.1.47"
                }
                """.utf8
            ),
            statusCode: 200
        )
        let checker = GitHubReleaseUpdateChecker(loader: loader)

        let result = try await checker.check(currentVersion: "0.1.46")

        XCTAssertEqual(
            result,
            .updateAvailable(
                AppUpdate(
                    version: "v0.1.47",
                    releaseURL: URL(string: "https://github.com/whnnick/readycheck/releases/tag/v0.1.47")!
                )
            )
        )

        let request = try await loader.recordedRequest()
        XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/repos/whnnick/readycheck/releases/latest")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    }

    func testCheckerReturnsUpToDateWhenLatestReleaseMatches() async throws {
        let loader = UpdateRecordingHTTPDataLoader(
            data: Data(
                """
                {
                  "tag_name": "v0.1.46",
                  "html_url": "https://github.com/whnnick/readycheck/releases/tag/v0.1.46"
                }
                """.utf8
            ),
            statusCode: 200
        )
        let checker = GitHubReleaseUpdateChecker(loader: loader)

        let result = try await checker.check(currentVersion: "0.1.46")

        XCTAssertEqual(result, .upToDate)
    }

    func testCheckerFailsOnHTTPError() async throws {
        let loader = UpdateRecordingHTTPDataLoader(data: Data(), statusCode: 500)
        let checker = GitHubReleaseUpdateChecker(loader: loader)

        do {
            _ = try await checker.check(currentVersion: "0.1.46")
            XCTFail("Expected update check to fail")
        } catch {
            XCTAssertEqual(error as? UpdateCheckError, .requestFailed(500))
        }
    }
}

private actor UpdateRecordingHTTPDataLoader: HTTPDataLoading {
    private let data: Data
    private let statusCode: Int
    private var request: URLRequest?

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func recordedRequest() throws -> URLRequest {
        try XCTUnwrap(request)
    }
}

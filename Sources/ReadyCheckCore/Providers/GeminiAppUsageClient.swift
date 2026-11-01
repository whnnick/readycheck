import Foundation

/// Read-only client for an observed web contract; session acquisition is intentionally separate.
public struct GeminiAppUsageClient: Sendable {
    public enum Failure: Error, Equatable { case invalidSession, unauthorized, rateLimited, server, network, invalidResponse }
    private let loader: any HTTPDataLoading

    public init(loader: any HTTPDataLoading = GeminiAppHTTPDataLoader()) { self.loader = loader }

    public func fetch(sessionCookie: String) async throws -> GeminiAppUsageParser.Reading {
        guard !sessionCookie.isEmpty, sessionCookie.utf8.count <= 16_384, sessionCookie.contains("="),
              !sessionCookie.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { throw Failure.invalidSession }
        var components = URLComponents(string: "https://gemini.google.com/_/BardChatUi/graphql/schemas/GEMINI_WEB_GRAPHQL/executeQuery")!
        components.queryItems = [
            URLQueryItem(name: "query_signature", value: "2/dWbCvkVB0X16r9NPnxifeOAAqdCqMf0xeWvau9yPy7g="),
            URLQueryItem(name: "variables", value: #"{"g1Request":{"entrypoints":["GEMINI_USAGE_SETTINGS_UPGRADE_BANNER"]},"workspaceRequest":{"recommendationsForSurfaceRequests":[]}}"#)
        ]
        guard let url = components.url else { throw Failure.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
        let data: Data
        let response: HTTPURLResponse
        do { (data, response) = try await loader.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw Failure.network }
        guard response.url?.scheme == "https", response.url?.host == "gemini.google.com",
              response.url?.port == nil || response.url?.port == 443 else { throw Failure.invalidResponse }
        switch response.statusCode {
        case 200: break
        case 300...399, 401, 403: throw Failure.unauthorized
        case 429: throw Failure.rateLimited
        default: throw Failure.server
        }
        do { return try GeminiAppUsageParser.parse(data) }
        catch GeminiAppUsageParser.Error.signedOut { throw Failure.unauthorized }
        catch { throw Failure.invalidResponse }
    }
}

public struct GeminiAppHTTPDataLoader: HTTPDataLoading {
    public init() {}
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let session = URLSession(configuration: .ephemeral, delegate: GeminiRejectRedirects(), delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw HTTPDataLoaderError.nonHTTPResponse }
        return (data, response)
    }
}

private final class GeminiRejectRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

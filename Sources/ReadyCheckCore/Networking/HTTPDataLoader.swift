import Foundation

public protocol HTTPDataLoading: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionHTTPDataLoader: HTTPDataLoading {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPDataLoaderError.nonHTTPResponse
        }

        return (data, httpResponse)
    }
}

public enum HTTPDataLoaderError: Error, Equatable, Sendable {
    case nonHTTPResponse
}

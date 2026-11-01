import Foundation

public struct DeepSeekBalance: Equatable, Sendable {
    public let currency: String
    public let total: Decimal
    public let granted: Decimal
    public let toppedUp: Decimal
}

public struct DeepSeekBalanceSnapshot: Equatable, Sendable {
    public let isAvailable: Bool
    public let balances: [DeepSeekBalance]
}

public enum DeepSeekBalanceError: Error, Equatable, Sendable {
    case unauthorized, rateLimited, server, network, invalidResponse
}

public struct DeepSeekBalanceClient: Sendable {
    private let loader: any HTTPDataLoading
    public init(loader: any HTTPDataLoading = DeepSeekHTTPDataLoader()) { self.loader = loader }

    public func fetch(apiKey: String) async throws -> DeepSeekBalanceSnapshot {
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/user/balance")!)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let data: Data
        let response: HTTPURLResponse
        do { (data, response) = try await loader.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw DeepSeekBalanceError.network }
        switch response.statusCode {
        case 200: break
        case 401, 403: throw DeepSeekBalanceError.unauthorized
        case 429: throw DeepSeekBalanceError.rateLimited
        default: throw DeepSeekBalanceError.server
        }
        do {
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            guard !payload.balanceInfos.isEmpty else { throw DeepSeekBalanceError.invalidResponse }
            var seen = Set<String>()
            let balances = try payload.balanceInfos.map { item in
                guard ["CNY", "USD"].contains(item.currency), seen.insert(item.currency).inserted else { throw DeepSeekBalanceError.invalidResponse }
                return DeepSeekBalance(currency: item.currency, total: try amount(item.totalBalance), granted: try amount(item.grantedBalance), toppedUp: try amount(item.toppedUpBalance))
            }
            return DeepSeekBalanceSnapshot(isAvailable: payload.isAvailable, balances: balances)
        } catch { throw DeepSeekBalanceError.invalidResponse }
    }

    private func amount(_ value: String) throws -> Decimal {
        guard value.range(of: #"^[0-9]+(\.[0-9]+)?$"#, options: .regularExpression) != nil,
              let result = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")), !result.isNaN else {
            throw DeepSeekBalanceError.invalidResponse
        }
        return result
    }

    private struct Payload: Decodable {
        let isAvailable: Bool
        let balanceInfos: [Balance]
        enum CodingKeys: String, CodingKey { case isAvailable = "is_available", balanceInfos = "balance_infos" }
        struct Balance: Decodable {
            let currency, totalBalance, grantedBalance, toppedUpBalance: String
            enum CodingKeys: String, CodingKey { case currency, totalBalance = "total_balance", grantedBalance = "granted_balance", toppedUpBalance = "topped_up_balance" }
        }
    }
}

public struct DeepSeekHTTPDataLoader: HTTPDataLoading {
    public init() {}
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let session = URLSession(configuration: .ephemeral, delegate: RejectRedirects(), delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw HTTPDataLoaderError.nonHTTPResponse }
        return (data, response)
    }
}

private final class RejectRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

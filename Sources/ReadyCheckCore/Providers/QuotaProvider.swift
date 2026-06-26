import Foundation

public enum RefreshReason: Equatable, Sendable {
    case automatic
    case manual
    case openedPanel
}

public struct ProviderRefreshContext: Equatable, Sendable {
    public let reason: RefreshReason

    public init(reason: RefreshReason) {
        self.reason = reason
    }
}

public protocol QuotaProvider: Sendable {
    var id: String { get }
    var displayName: String { get }

    func fetchSnapshot(context: ProviderRefreshContext) async throws -> ProviderQuotaSnapshot
}

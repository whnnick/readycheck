import Foundation
@testable import ReadyCheckCore

actor OAuthTestCredentials: CredentialStore {
    private var token: CodexOAuthToken?
    private var hold = false
    private var held: CheckedContinuation<String?, Error>?
    private var heldValue: String?
    private let onHeld: @Sendable () -> Void
    init(account: String? = "fixture-account", onHeld: @escaping @Sendable () -> Void = {}) {
        self.token = account.map(Self.makeToken); self.onHeld = onHeld
    }
    private static func makeToken(_ account: String) -> CodexOAuthToken {
        .init(accessToken: "synthetic-access", refreshToken: "synthetic-refresh", idToken: nil, tokenType: "Bearer",
            expiresAt: .distantFuture, accountID: account, email: "fixture@example.com")
    }
    func useAccount(_ account: String?) { token = account.map(Self.makeToken) }
    func holdNextRead() { hold = true }
    func finishHeld(fails: Bool) {
        if fails { held?.resume(throwing: KeychainCredentialStoreError.unexpectedStatus(-25293)) }
        else { held?.resume(returning: heldValue) }
        held = nil
    }
    func loadCredential(for key: CredentialKey) async throws -> String? {
        let value = try token.map { String(data: try JSONEncoder().encode($0), encoding: .utf8)! }
        if hold {
            hold = false; heldValue = value
            return try await withCheckedThrowingContinuation { held = $0; onHeld() }
        }
        return value
    }
    func saveCredential(_ credential: String, for key: CredentialKey) async throws {
        token = try JSONDecoder().decode(CodexOAuthToken.self, from: Data(credential.utf8))
    }
    func removeCredential(for key: CredentialKey) async throws { token = nil }
}

actor OAuthTestHTTP: HTTPDataLoading {
    private var failing = false
    private let usedByAccount: [String: Double]
    init(usedByAccount: [String: Double] = [:]) { self.usedByAccount = usedByAccount }
    func failReads() { failing = true }
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        if failing { throw URLError(.timedOut) }
        let url = request.url!
        let payload: [String: Any]
        if url.path.hasSuffix("rate-limit-reset-credits") { payload = ["available_count": 0, "credits": []] }
        else {
            let used = usedByAccount[request.value(forHTTPHeaderField: "ChatGPT-Account-Id") ?? ""] ?? 20
            payload = ["rate_limit": ["allowed": true, "primary_window": ["used_percent": used,
                "limit_window_seconds": 18000, "reset_at": Int(Date().timeIntervalSince1970) + 7200]], "manual_reset_count": 0]
        }
        return (try JSONSerialization.data(withJSONObject: payload), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

import CryptoKit
import Foundation

public struct CodexOAuthConfiguration: Equatable, Sendable {
    public let authorizationURL: URL
    public let tokenURL: URL
    public let clientID: String
    public let redirectURI: String
    public let scopes: [String]

    public init(
        authorizationURL: URL,
        tokenURL: URL,
        clientID: String,
        redirectURI: String,
        scopes: [String]
    ) {
        self.authorizationURL = authorizationURL
        self.tokenURL = tokenURL
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scopes = scopes
    }

    public static let codexCLI = CodexOAuthConfiguration(
        authorizationURL: URL(string: "https://auth.openai.com/oauth/authorize")!,
        tokenURL: URL(string: "https://auth.openai.com/oauth/token")!,
        clientID: "app_EMoamEEZ73f0CkXaXp7hrann",
        redirectURI: "http://localhost:1455/auth/callback",
        scopes: ["openid", "email", "profile", "offline_access"]
    )
}

public struct OAuthPKCECodes: Equatable, Sendable {
    public let verifier: String
    public let challenge: String

    public init(verifier: String, challenge: String) {
        self.verifier = verifier
        self.challenge = challenge
    }

    public static func generate(byteCount: Int = 32) throws -> OAuthPKCECodes {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            throw CodexOAuthError.pkceGenerationFailed
        }

        let verifier = Data(bytes).base64URLEncodedString()
        let challengeDigest = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(challengeDigest).base64URLEncodedString()
        return OAuthPKCECodes(verifier: verifier, challenge: challenge)
    }
}

public struct OAuthState: Equatable, Sendable {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public static func generate(byteCount: Int = 24) throws -> OAuthState {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            throw CodexOAuthError.stateGenerationFailed
        }

        return OAuthState(value: Data(bytes).base64URLEncodedString())
    }
}

public struct CodexOAuthSession: Equatable, Sendable {
    public let state: String
    public let pkce: OAuthPKCECodes
    public let authorizationURL: URL

    public init(state: String, pkce: OAuthPKCECodes, authorizationURL: URL) {
        self.state = state
        self.pkce = pkce
        self.authorizationURL = authorizationURL
    }
}

public struct OAuthCallback: Equatable, Sendable {
    public let code: String?
    public let state: String?
    public let error: String?
    public let errorDescription: String?

    public init(code: String?, state: String?, error: String?, errorDescription: String?) {
        self.code = code
        self.state = state
        self.error = error
        self.errorDescription = errorDescription
    }
}

public enum OAuthCallbackParser {
    public static func parse(_ callback: String) throws -> OAuthCallback? {
        let trimmed = callback.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let components = URLComponents(string: trimmed) else {
            throw CodexOAuthError.invalidCallbackURL
        }

        let values = Dictionary(
            grouping: components.queryItems ?? [],
            by: \.name
        ).mapValues { $0.last?.value }

        return OAuthCallback(
            code: values["code"] ?? nil,
            state: values["state"] ?? nil,
            error: values["error"] ?? nil,
            errorDescription: values["error_description"] ?? nil
        )
    }
}

public struct CodexOAuthToken: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let idToken: String?
    public let tokenType: String
    public let expiresAt: Date
    public let accountID: String?
    public let email: String?

    public init(
        accessToken: String,
        refreshToken: String,
        idToken: String?,
        tokenType: String,
        expiresAt: Date,
        accountID: String?,
        email: String?
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.accountID = accountID
        self.email = email
    }

    public var loginEmail: String? {
        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedEmail, !trimmedEmail.isEmpty {
            return trimmedEmail
        }

        return nil
    }
}

public enum CodexJWTClaims {
    private static let authClaim = "https://api.openai.com/auth"
    private static let profileClaim = "https://api.openai.com/profile"

    public static func accountID(from token: String?) -> String? {
        guard let payload = decodePayload(from: token),
              let auth = payload[authClaim] as? [String: Any],
              let accountID = auth["chatgpt_account_id"] as? String
        else {
            return nil
        }

        let trimmed = accountID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public static func email(from token: String?) -> String? {
        guard let payload = decodePayload(from: token),
              let profile = payload[profileClaim] as? [String: Any],
              let email = profile["email"] as? String
        else {
            return nil
        }

        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func decodePayload(from token: String?) -> [String: Any]? {
        guard let token else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - payload.count % 4) % 4
        payload.append(String(repeating: "=", count: padding))

        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any]
        else {
            return nil
        }

        return dictionary
    }
}

public struct CodexOAuthTokenStore: Sendable {
    public static let defaultKey = CredentialKey(providerId: "codex-oauth", name: "oauth-token")

    private let credentialStore: any CredentialStore
    private let key: CredentialKey

    public init(credentialStore: any CredentialStore, key: CredentialKey = Self.defaultKey) {
        self.credentialStore = credentialStore
        self.key = key
    }

    public func loadToken() async throws -> CodexOAuthToken? {
        guard let payload = try await credentialStore.loadCredential(for: key) else {
            return nil
        }
        guard let data = payload.data(using: .utf8) else {
            throw CodexOAuthError.invalidStoredToken
        }

        return try JSONDecoder().decode(CodexOAuthToken.self, from: data)
    }

    public func saveToken(_ token: CodexOAuthToken) async throws {
        let data = try JSONEncoder().encode(token)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw CodexOAuthError.invalidStoredToken
        }

        try await credentialStore.saveCredential(payload, for: key)
    }

    public func removeToken() async throws {
        try await credentialStore.removeCredential(for: key)
    }
}

public struct CodexOAuthClient: Sendable {
    private let configuration: CodexOAuthConfiguration
    private let loader: any HTTPDataLoading
    private let now: @Sendable () -> Date

    public init(
        configuration: CodexOAuthConfiguration = .codexCLI,
        loader: any HTTPDataLoading = URLSessionHTTPDataLoader(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.configuration = configuration
        self.loader = loader
        self.now = now
    }

    public func makeAuthorizationSession(
        state: OAuthState,
        pkce: OAuthPKCECodes
    ) throws -> CodexOAuthSession {
        let url = try authorizationURL(state: state.value, pkce: pkce)
        return CodexOAuthSession(state: state.value, pkce: pkce, authorizationURL: url)
    }

    public func authorizationURL(state: String, pkce: OAuthPKCECodes) throws -> URL {
        guard EndpointSafety.isAllowedForOAuth(configuration.authorizationURL) else {
            throw CodexOAuthError.unsafeOAuthEndpoint
        }

        var components = URLComponents(url: configuration.authorizationURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "login"),
            URLQueryItem(name: "id_token_add_organizations", value: "true"),
            URLQueryItem(name: "codex_cli_simplified_flow", value: "true")
        ]

        guard let url = components?.url else {
            throw CodexOAuthError.invalidAuthorizationURL
        }

        return url
    }

    public func exchangeCode(_ code: String, pkce: OAuthPKCECodes) async throws -> CodexOAuthToken {
        try await postTokenRequest(
            form: [
                "grant_type": "authorization_code",
                "client_id": configuration.clientID,
                "code": code,
                "redirect_uri": configuration.redirectURI,
                "code_verifier": pkce.verifier
            ]
        )
    }

    public func refreshToken(_ refreshToken: String) async throws -> CodexOAuthToken {
        try await postTokenRequest(
            form: [
                "grant_type": "refresh_token",
                "client_id": configuration.clientID,
                "refresh_token": refreshToken,
                "scope": "openid profile email"
            ]
        )
    }

    private func postTokenRequest(form: [String: String]) async throws -> CodexOAuthToken {
        guard EndpointSafety.isAllowedForOAuth(configuration.tokenURL) else {
            throw CodexOAuthError.unsafeOAuthEndpoint
        }

        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = form.formURLEncodedData()

        let (data, response) = try await loader.data(for: request)
        guard response.statusCode == 200 else {
            throw CodexOAuthError.tokenRequestFailed(statusCode: response.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(CodexOAuthTokenResponse.self, from: data)
        return CodexOAuthToken(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            idToken: tokenResponse.idToken,
            tokenType: tokenResponse.tokenType,
            expiresAt: now().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
            accountID: CodexJWTClaims.accountID(from: tokenResponse.accessToken),
            email: CodexJWTClaims.email(from: tokenResponse.accessToken)
        )
    }
}

public struct CodexOAuthAuthorizer: Sendable {
    private let client: CodexOAuthClient
    private let tokenStore: CodexOAuthTokenStore

    public init(client: CodexOAuthClient = CodexOAuthClient(), tokenStore: CodexOAuthTokenStore) {
        self.client = client
        self.tokenStore = tokenStore
    }

    public func begin() throws -> CodexOAuthSession {
        try client.makeAuthorizationSession(
            state: OAuthState.generate(),
            pkce: OAuthPKCECodes.generate()
        )
    }

    public func complete(callbackURL: String, session: CodexOAuthSession) async throws -> CodexOAuthToken {
        guard let callback = try OAuthCallbackParser.parse(callbackURL) else {
            throw CodexOAuthError.invalidCallbackURL
        }
        if let error = callback.error {
            throw CodexOAuthError.callbackFailed(error: error, description: callback.errorDescription)
        }
        guard callback.state == session.state else {
            throw CodexOAuthError.stateMismatch
        }
        guard let code = callback.code, !code.isEmpty else {
            throw CodexOAuthError.missingAuthorizationCode
        }

        let token = try await client.exchangeCode(code, pkce: session.pkce)
        try await tokenStore.saveToken(token)
        return token
    }

    public func disconnect() async throws {
        try await tokenStore.removeToken()
    }
}

public struct CodexQuotaHTTPClient: Sendable {
    private let loader: any HTTPDataLoading

    public init(loader: any HTTPDataLoading = URLSessionHTTPDataLoader()) {
        self.loader = loader
    }

    public func fetchReadOnlyPayload(
        from endpoint: URL,
        accessToken: String,
        accountID: String? = nil
    ) async throws -> Data {
        guard EndpointSafety.isAllowedForRefresh(endpoint) else {
            throw CodexQuotaHTTPClientError.unsafeRefreshEndpoint
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ReadyCheck/0.1", forHTTPHeaderField: "User-Agent")
        if let accountID {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let (data, response) = try await loader.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw CodexQuotaHTTPClientError.requestFailed(statusCode: response.statusCode)
        }

        return data
    }
}

public enum CodexOAuthError: Error, Equatable, Sendable {
    case pkceGenerationFailed
    case stateGenerationFailed
    case invalidAuthorizationURL
    case invalidCallbackURL
    case invalidStoredToken
    case unsafeOAuthEndpoint
    case callbackFailed(error: String, description: String?)
    case stateMismatch
    case missingAuthorizationCode
    case tokenRequestFailed(statusCode: Int)
}

public enum CodexQuotaHTTPClientError: Error, Equatable, Sendable {
    case unsafeRefreshEndpoint
    case requestFailed(statusCode: Int)
}

private struct CodexOAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let idToken: String?
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

private extension Dictionary where Key == String, Value == String {
    func formURLEncodedData() -> Data {
        let body = map { key, value in
            "\(key.urlFormEncoded)=\(value.urlFormEncoded)"
        }
        .sorted()
        .joined(separator: "&")

        return Data(body.utf8)
    }
}

private extension String {
    var urlFormEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlFormAllowed) ?? self
    }
}

private extension CharacterSet {
    static let urlFormAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=/?")
        return allowed
    }()
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

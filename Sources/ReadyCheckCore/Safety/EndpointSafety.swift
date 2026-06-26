import Foundation

public enum EndpointSafety {
    private static let deniedRefreshPaths: Set<String> = [
        "/v1/responses",
        "/v1/chat/completions",
        "/v1/completions",
        "/v1/messages"
    ]
    private static let openAIRefreshPaths: Set<String> = [
        "/v1/organization/usage",
        "/v1/organization/costs"
    ]
    private static let chatGPTRefreshPaths: Set<String> = [
        "/backend-api/wham/usage"
    ]
    private static let openAIOAuthPaths: Set<String> = [
        "/oauth/authorize",
        "/oauth/token"
    ]

    public static func isAllowedForRefresh(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https" else { return false }
        guard let host = url.host?.lowercased() else { return false }
        let path = url.path.lowercased()
        guard !hasUnsafeRefreshPath(url, decodedPath: path) else { return false }
        if deniedRefreshPaths.contains(path) {
            return false
        }
        if host == "api.openai.com" {
            return openAIRefreshPaths.contains { path == $0 || path.hasPrefix($0 + "/") }
        }
        if host == "chatgpt.com" {
            return chatGPTRefreshPaths.contains(path)
        }
        if host == "api.anthropic.com" {
            return false
        }
        return false
    }

    public static func isAllowedForOAuth(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https" else { return false }
        guard let host = url.host?.lowercased(), host == "auth.openai.com" else { return false }
        let path = url.path.lowercased()
        guard !hasUnsafeRefreshPath(url, decodedPath: path) else { return false }

        return openAIOAuthPaths.contains(path)
    }

    private static func hasUnsafeRefreshPath(_ url: URL, decodedPath: String) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return true
        }

        let encodedPath = components.percentEncodedPath.lowercased()
        if encodedPath.contains("%2e") || encodedPath.contains("%2f") {
            return true
        }

        return decodedPath.split(separator: "/").contains { segment in
            segment == "." || segment == ".."
        }
    }

    public static func isLocalFileAllowed(_ url: URL) -> Bool {
        url.isFileURL
    }
}

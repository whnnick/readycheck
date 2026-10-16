import Foundation

public struct AppUpdate: Equatable, Sendable {
    public let version: String
    public let releaseURL: URL

    public init(version: String, releaseURL: URL) {
        self.version = version
        self.releaseURL = releaseURL
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case upToDate
    case updateAvailable(AppUpdate)
}

public enum UpdateCheckError: Error, Equatable, Sendable {
    case requestFailed(Int)
    case invalidReleaseURL
}

public struct GitHubReleaseUpdateChecker: Sendable {
    private let repository: String
    private let loader: any HTTPDataLoading

    public init(
        repository: String = "whnnick/readycheck",
        loader: any HTTPDataLoading = URLSessionHTTPDataLoader()
    ) {
        self.repository = repository
        self.loader = loader
    }

    public func check(currentVersion: String) async throws -> UpdateCheckResult {
        let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ReadyCheck/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await loader.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw UpdateCheckError.requestFailed(response.statusCode)
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard let releaseURL = URL(string: release.htmlURL) else {
            throw UpdateCheckError.invalidReleaseURL
        }

        let latestVersion = release.tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if SoftwareVersion(latestVersion) > SoftwareVersion(currentVersion) {
            return .updateAvailable(AppUpdate(version: latestVersion, releaseURL: releaseURL))
        }

        return .upToDate
    }
}

public struct SoftwareVersion: Comparable, Sendable {
    private let parts: [Int]
    private let prerelease: [String]?

    public init(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.hasPrefix("v") || trimmed.hasPrefix("V") ? String(trimmed.dropFirst()) : trimmed
        let withoutBuild = normalized.split(separator: "+", maxSplits: 1).first.map(String.init) ?? normalized
        let components = withoutBuild.split(separator: "-", maxSplits: 1)
        self.parts = (components.first.map(String.init) ?? "").split { $0 == "." || $0 == "_" }.map { Int($0) ?? 0 }
        self.prerelease = components.count == 2 ? components[1].split(separator: ".").map(String.init) : nil
    }

    public static func < (lhs: SoftwareVersion, rhs: SoftwareVersion) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        for index in 0..<count {
            let left = index < lhs.parts.count ? lhs.parts[index] : 0
            let right = index < rhs.parts.count ? rhs.parts[index] : 0
            if left != right {
                return left < right
            }
        }
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, _): return false
        case (_, nil): return true
        case let (left?, right?):
            for (a, b) in zip(left, right) where a != b {
                switch (Int(a), Int(b)) {
                case let (x?, y?): if x != y { return x < y }
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return a < b
                }
            }
            return left.count < right.count
        }
    }

    public static func == (lhs: SoftwareVersion, rhs: SoftwareVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

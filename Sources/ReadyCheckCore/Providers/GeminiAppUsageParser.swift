import CoreFoundation
import Foundation

/// Offline parser for an observed, undocumented Gemini app response. This is not a connection.
public enum GeminiAppUsageParser {
    public enum Error: Swift.Error, Equatable { case signedOut, invalidResponse }

    public struct Window: Equatable, Sendable {
        public let usedFraction: Double
        public let resetsAt: Date?
    }

    public struct Reading: Equatable, Sendable {
        public let fiveHour: Window?
        public let weekly: Window?
    }

    public static func parse(_ data: Data) throws -> Reading {
        guard var body = String(data: data, encoding: .utf8) else { throw Error.invalidResponse }
        if body.hasPrefix(")]}'") {
            guard let newline = body.firstIndex(of: "\n") else { throw Error.invalidResponse }
            body = String(body[body.index(after: newline)...])
        }
        guard let json = body.data(using: .utf8),
              let rows = try? JSONSerialization.jsonObject(with: json) as? [[String: Any]],
              rows.count == 1, let data = rows[0]["data"] as? [String: Any],
              let viewer = data["viewer"] else { throw Error.invalidResponse }
        if viewer is NSNull { throw Error.signedOut }
        guard let viewer = viewer as? [String: Any],
              let rpcs = viewer["rpcs"] as? [String: Any],
              let info = rpcs["getUsageInfo"] as? [String: Any],
              let pools = info["pools"] as? [[String: Any]] else { throw Error.invalidResponse }
        var fiveHour: Window?, weekly: Window?
        for pool in pools {
            guard let type = pool["poolType"] as? String else { throw Error.invalidResponse }
            guard type == "GXU_FIVE_HOURLY" || type == "GXU_WEEKLY" else { continue }
            guard let number = pool["percentageUsed"] as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  number.doubleValue.isFinite, (0...1).contains(number.doubleValue) else { throw Error.invalidResponse }
            var reset: Date?
            if let gxu = pool["gxu"], !(gxu is NSNull) {
                guard let object = gxu as? [String: Any] else { throw Error.invalidResponse }
                if let raw = object["windowRefreshesAt"], !(raw is NSNull) {
                    guard let value = raw as? String, let date = parseDate(value) else { throw Error.invalidResponse }
                    reset = date
                }
            }
            let window = Window(usedFraction: number.doubleValue, resetsAt: reset)
            if type == "GXU_FIVE_HOURLY" {
                guard fiveHour == nil else { throw Error.invalidResponse }
                fiveHour = window
            } else {
                guard weekly == nil else { throw Error.invalidResponse }
                weekly = window
            }
        }
        return Reading(fiveHour: fiveHour, weekly: weekly)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

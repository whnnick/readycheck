import Foundation

enum LaunchAtLoginInstallation {
    static func isComplete(at appURL: URL) -> Bool {
        let contents = appURL.appendingPathComponent("Contents")
        guard appURL.pathExtension == "app",
              let data = try? Data(contentsOf: contents.appendingPathComponent("Info.plist")),
              let info = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              info["CFBundleIdentifier"] as? String == "com.readycheck.app",
              info["CFBundlePackageType"] as? String == "APPL",
              let executable = info["CFBundleExecutable"] as? String,
              !executable.isEmpty,
              executable == (executable as NSString).lastPathComponent else {
            return false
        }
        return FileManager.default.isExecutableFile(
            atPath: contents.appendingPathComponent("MacOS").appendingPathComponent(executable).path
        )
    }
}

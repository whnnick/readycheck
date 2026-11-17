import Foundation

enum ReadyCheckResources {
    private final class Anchor: NSObject {}
    private static let resources = bundle(in: Bundle(for: Anchor.self))

    static func url(forResource name: String, withExtension fileExtension: String) -> URL? {
        resources?.url(forResource: name, withExtension: fileExtension)
    }

    static func bundle(in host: Bundle) -> Bundle? {
        let name = "ReadyCheck_ReadyCheckApp.bundle"
        if let directory = host.resourceURL,
           let resources = Bundle(url: directory.appendingPathComponent(name, isDirectory: true)) {
            return resources
        }

        // Packaged apps must be self-contained. SwiftPM places its resources next to the test bundle.
        guard host.bundleURL.pathExtension != "app" else { return nil }
        for directory in [host.bundleURL, host.bundleURL.deletingLastPathComponent()] {
            if let resources = Bundle(url: directory.appendingPathComponent(name, isDirectory: true)) {
                return resources
            }
        }
        return nil
    }
}

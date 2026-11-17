import XCTest
@testable import ReadyCheckApp

final class ServiceSwitcherIconTests: XCTestCase {
    func testBothSwitcherIconsLoadFromBundledResources() {
        XCTAssertNotNil(ServiceSwitcherIcon.image(name: "readycheck", extension: "png"))
        XCTAssertNotNil(ServiceSwitcherIcon.image(name: "deepseek", extension: "svg"))
    }

    func testPackagedAppResolvesResourcesFromContents() throws {
        try withPackagedApp { app, resourceDirectory in
            let bundle = try XCTUnwrap(ReadyCheckResources.bundle(in: app))
            let resource = try XCTUnwrap(bundle.url(forResource: "MuseSubscription", withExtension: "js"))
            XCTAssertEqual(resource.standardizedFileURL, resourceDirectory.appendingPathComponent("MuseSubscription.js").standardizedFileURL)
        }
    }

    func testPackagedAppWithMissingResourcesReturnsNil() throws {
        try withPackagedApp(includeResources: false) { app, _ in
            XCTAssertNil(ReadyCheckResources.bundle(in: app))
        }
    }

    private func withPackagedApp(
        includeResources: Bool = true,
        _ check: (Bundle, URL) throws -> Void
    ) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let app = directory.appendingPathComponent("ReadyCheck.app", isDirectory: true)
        let contents = app.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources/ReadyCheck_ReadyCheckApp.bundle", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let info = ["CFBundlePackageType": "APPL", "CFBundleIdentifier": "com.readycheck.tests.resources"]
        let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try plist.write(to: contents.appendingPathComponent("Info.plist"))
        if includeResources {
            try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
            try Data("return true".utf8).write(to: resources.appendingPathComponent("MuseSubscription.js"))
        }
        try check(XCTUnwrap(Bundle(url: app)), resources)
    }
}

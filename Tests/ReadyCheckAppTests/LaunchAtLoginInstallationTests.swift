import XCTest
@testable import ReadyCheckApp

final class LaunchAtLoginInstallationTests: XCTestCase {
    private var directory: URL!
    private var app: URL { directory.appendingPathComponent("ReadyCheck.app") }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testMissingPlistIsIncompleteEvenWithExecutablePresent() throws {
        try writeExecutable()
        XCTAssertFalse(LaunchAtLoginInstallation.isComplete(at: app))
    }

    func testValidPlistWithoutExecutableIsIncomplete() throws {
        try writePlist()
        XCTAssertFalse(LaunchAtLoginInstallation.isComplete(at: app))
    }

    func testInvalidPlistIsIncomplete() throws {
        try Data("invalid plist".utf8).write(to: app.appendingPathComponent("Contents/Info.plist"))
        try writeExecutable()
        XCTAssertFalse(LaunchAtLoginInstallation.isComplete(at: app))
    }

    func testWrongIdentityAndNonExecutableFileAreIncomplete() throws {
        try writePlist(identifier: "com.example.other")
        try writeExecutable()
        XCTAssertFalse(LaunchAtLoginInstallation.isComplete(at: app))
        try writePlist()
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: app.appendingPathComponent("Contents/MacOS/ReadyCheckApp").path)
        XCTAssertFalse(LaunchAtLoginInstallation.isComplete(at: app))
    }

    func testCompleteBundleIsAcceptedOutsideApplicationsAndDeletionIsDetected() throws {
        try writePlist()
        try writeExecutable()
        XCTAssertTrue(LaunchAtLoginInstallation.isComplete(at: app))
        try FileManager.default.removeItem(at: app.appendingPathComponent("Contents/Info.plist"))
        XCTAssertFalse(LaunchAtLoginInstallation.isComplete(at: app))
    }

    private func writePlist(identifier: String = "com.readycheck.app") throws {
        let info = ["CFBundleIdentifier": identifier, "CFBundlePackageType": "APPL", "CFBundleExecutable": "ReadyCheckApp"]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: app.appendingPathComponent("Contents/Info.plist"))
    }

    private func writeExecutable() throws {
        let executable = app.appendingPathComponent("Contents/MacOS/ReadyCheckApp")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
    }
}

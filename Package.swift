// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadyCheck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ReadyCheckCore", targets: ["ReadyCheckCore"]),
        .executable(name: "ReadyCheckApp", targets: ["ReadyCheckApp"])
    ],
    targets: [
        .target(
            name: "ReadyCheckCore",
            path: "Sources/ReadyCheckCore"
        ),
        .executableTarget(
            name: "ReadyCheckApp",
            dependencies: ["ReadyCheckCore"],
            path: "Sources/ReadyCheckApp"
        ),
        .testTarget(
            name: "ReadyCheckCoreTests",
            dependencies: ["ReadyCheckCore"],
            path: "Tests/ReadyCheckCoreTests",
            exclude: ["Fixtures/LocalCodex/README.md"]
        )
    ]
)

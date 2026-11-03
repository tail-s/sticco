// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sticco",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Sticco",
            path: "Sources/Sticco",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)

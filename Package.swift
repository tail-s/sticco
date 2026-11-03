// swift-tools-version: 5.10
// Tools 5.10 keeps the Swift 5 language mode without a per-target setting,
// which multi-arch (universal) builds on older Xcode versions reject.
import PackageDescription

let package = Package(
    name: "Sticco",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Sticco", path: "Sources/Sticco")
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nozhichki",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Nozhichki",
            path: "Sources"
        )
    ]
)

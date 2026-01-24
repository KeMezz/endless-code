// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ClaudeCodeWrapper",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        .executable(name: "cc-wrapper", targets: ["ClaudeCodeWrapper"]),
        .library(name: "ClaudeCodeKit", targets: ["ClaudeCodeKit"])
    ],
    targets: [
        .target(
            name: "ClaudeCodeKit",
            path: "Sources/ClaudeCodeKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "ClaudeCodeWrapper",
            dependencies: ["ClaudeCodeKit"],
            path: "Sources/ClaudeCodeWrapper"
        )
    ]
)

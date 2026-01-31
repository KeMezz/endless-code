// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EndlessCode",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EndlessCode",
            targets: ["EndlessCode"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.121.1"),
    ],
    targets: [
        // Shared models and utilities
        .target(
            name: "EndlessCode",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ],
            path: "EndlessCode",
            exclude: [
                "Assets.xcassets",
                "Preview Content",
                "EndlessCode.entitlements",
                "Info.plist",
            ],
            sources: [
                "Shared/Models",
                "Shared/Utilities",
                "Server/Sources",
                "Client/Sources",
            ]
        ),
        .testTarget(
            name: "EndlessCodeTests",
            dependencies: [
                "EndlessCode",
                .product(name: "VaporTesting", package: "vapor"),
            ],
            path: "EndlessCodeTests",
            sources: ["Server", "Client", "Shared", "DiffViewer"]
        ),
    ]
)

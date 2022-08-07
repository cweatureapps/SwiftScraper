// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftScraper",
    platforms: [.iOS(.v9), .macOS(.v10_11)],
    products: [
        .library(
            name: "SwiftScraper",
            targets: ["SwiftScraper"])
    ],
    dependencies: [
        .package(path: "../Observable")
    ],
    targets: [
        .target(
            name: "SwiftScraper",
            dependencies: ["Observable"],
            resources: [.process("Resources/SwiftScraper.js")]
        ),
        .testTarget(
            name: "SwiftScraperTests",
            dependencies: ["SwiftScraper"]
        )
    ]
)

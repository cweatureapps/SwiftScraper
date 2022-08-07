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
    ],
    targets: [
        .target(
            name: "SwiftScraper",
            dependencies: [],
            resources: [.process("Resources/SwiftScraper.js")]
        ),
        .testTarget(
            name: "SwiftScraperTests",
            dependencies: ["SwiftScraper"],
            resources: [
                .process("Resources/page1.html"),
                .process("Resources/page2.html"),
                .process("Resources/waitTest.html"),
                .process("StepRunnerTests.js")
            ]
        )
    ]
)

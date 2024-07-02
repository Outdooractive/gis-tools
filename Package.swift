// swift-tools-version:5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency") // 5.10
    .enableUpcomingFeature("StrictConcurrency") // 6.0
]

let package = Package(
    name: "gis-tools",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "GISTools",
            targets: ["GISTools"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "GISTools",
            swiftSettings: swiftSettings),
        .testTarget(
            name: "GISToolsTests",
            dependencies: ["GISTools"],
            exclude: ["TestData"],
            swiftSettings: swiftSettings),
    ]
)

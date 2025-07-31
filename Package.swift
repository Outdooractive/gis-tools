// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "gis-tools",
    platforms: [
        .iOS(.v15),
        .macOS(.v14),
        .tvOS(.v15),
        .watchOS(.v7),
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
            name: "GISTools"),
        .testTarget(
            name: "GISToolsTests",
            dependencies: ["GISTools"],
            exclude: ["TestData"]),
    ]
)

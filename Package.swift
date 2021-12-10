// swift-tools-version:5.4

import PackageDescription

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
        .target(name: "GISTools"),
        .testTarget(
            name: "GISToolsTests",
            dependencies: ["GISTools"],
            exclude: ["TestData"]),
    ]
)

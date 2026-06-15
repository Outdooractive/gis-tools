// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "gis-tools",
    platforms: [
        .iOS(.v15),
        .macOS(.v15),
        .tvOS(.v15),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "GISTools",
            targets: ["GISTools"]),
    ],
    traits: [
        .trait(name: "EnableConversionExtensions"),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GISTools"),
        .testTarget(
            name: "GISToolsTests",
            dependencies: ["GISTools"],
            exclude: ["TestData"]),
    ]
)

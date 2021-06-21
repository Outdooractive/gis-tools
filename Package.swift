// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "GISTools",
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

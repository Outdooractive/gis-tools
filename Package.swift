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
        .library(
            name: "GISToolsGeoPackage",
            targets: ["GISToolsGeoPackage"]),
    ],
    traits: [
        .trait(
            name: "EnableMeterConversionExtensions",
            description: "Adds conversion properties that return raw Double values in meters."),
        .trait(
            name: "EnableMeasurementConversionExtensions",
            description: "Adds conversion properties that return Measurement<UnitLength> values for unit-aware arithmetic."),
        .trait(
            name: "EnableShapefileSupport",
            description: "Adds Shapefile (.shp/.dbf/.shx/.prj) read and write support."),
        .trait(
            name: "EnableGeoPackageSupport",
            description: "Adds GeoPackage (.gpkg) read and write support."),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GISTools"),
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3",
            providers: [
                .apt(["libsqlite3-dev"]),
                .brew(["sqlite3"]),
            ]),
        .target(
            name: "GISToolsGeoPackage",
            dependencies: [
                "GISTools",
                "CSQLite",
            ]),
        .testTarget(
            name: "GISToolsTests",
            dependencies: ["GISTools"],
            exclude: ["TestData"]),
        .testTarget(
            name: "GISToolsGeoPackageTests",
            dependencies: ["GISToolsGeoPackage"]),
    ]
)

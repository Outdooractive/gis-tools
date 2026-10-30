# Getting started

Add GISTools to a Swift package, choose the package traits you need, and start
working with GeoJSON values.

## Requirements

GISTools requires Swift 6.1 or newer. The declared deployment targets are iOS
15, macOS 15, tvOS 15 and watchOS 7. Linux is supported by Swift Package
Manager. Android and WebAssembly are not continuously verified.

## Add the package

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
        ]),
]
```

## Choose package traits

The core library needs no traits. Optional functionality is enabled with
SwiftPM package traits:

| Trait | Effect |
|---|---|
| `EnableGraphAPI` | Adds graph construction, routing and network analysis. |
| `EnableMeasurementConversionExtensions` | Unit conversion properties return `Measurement<UnitLength>`. |
| `EnableMeterConversionExtensions` | Unit conversion properties return raw `Double` meters. |

The two conversion traits are alternatives: enable one of them. If both are
enabled, `EnableMeasurementConversionExtensions` wins, so turning on every
trait still compiles. Enable the graph trait when you use `Graph` or its
routing APIs:

```swift
.package(
    url: "https://github.com/Outdooractive/gis-tools",
    from: "3.0.0",
    traits: ["EnableGraphAPI"])
```

For local SwiftPM commands, pass `--traits EnableGraphAPI` to `swift build`,
`swift run` or `swift test`.

## Build a GeoJSON object

Geodetic coordinates use the latitude/longitude initializer:

```swift
import GISTools

let coordinate = Coordinate3D(latitude: 48.1372, longitude: 11.5756)
let point = Point(coordinate)
let feature = Feature(
    point,
    properties: [
        "name": "Munich",
        "population": 1_500_000,
    ])
```

Projected coordinates require an explicit projection:

```swift
let webMercator = Coordinate3D(x: 1_293_000.0, y: 6_140_000.0, projection: .epsg3857)
let sameCoordinate = Coordinate3D.epsg3857(x: 1_293_000.0, y: 6_140_000.0)
let local = Coordinate3D.noSRID(x: 12.0, y: 34.0)
```

`Feature.geometry` is optional in 3.0. An explicit GeoJSON `"geometry": null`
creates an unlocated feature; a missing geometry member is still invalid.

## Load and write GeoJSON

```swift
// Decode with the lenient convenience API.
let feature = Feature(jsonString: jsonString)
let collection = FeatureCollection(jsonData: data)

// Parse with diagnostics.
let result = try GeoJsonParser.parse(jsonString: jsonString, mode: .strict)
print(result.issues.map(\.path))

// Encode.
let jsonData = feature.asJsonData(prettyPrinted: true)
let jsonString = feature.asJsonString(prettyPrinted: true)

// Codable works as well.
let encoded = try JSONEncoder().encode(feature)
let decoded = try JSONDecoder().decode(Feature.self, from: encoded)
```

`GeoJsonReader` wraps any GeoJSON value into a feature collection; see
[GeoJSON and WKB/WKT/TWKB][coders] for parser modes, unlocated features, gzip input and the
WKB/WKT/TWKB coders.

## Work with projections

Coordinates keep their projection through operations. Use `projected(to:)` to
change it:

```swift
let utm = coordinate.projected(to: .epsg32632)

let distance = coordinate.distance(to: utm)
```

Algorithms use the receiver's projection as their working frame. See
[Projections and antimeridian handling][projections] for projection selection, custom projections,
datum accuracy and antimeridian handling.

## Next steps

- [Projections and antimeridian handling][projections]
- [GeoJSON and WKB/WKT/TWKB][coders]
- [Query DSL][query-dsl]
- [Graph API][graph-api]
- [Performance and memory notes][performance]
- [Migrating to GISTools 3.0][migration]

[coders]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/geojsonandcoders
[projections]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/projectionsandantimeridian
[query-dsl]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/querydsl
[graph-api]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/graphapi
[performance]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/performanceandmemory
[migration]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/migrationguide

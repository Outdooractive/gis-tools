# GPX

`GISToolsGPX` reads and writes GPX 1.1 and reads GPX 1.0. Waypoints become
``Point`` features, routes become ``LineString`` features and tracks become
``MultiLineString`` features. Garmin fitness and waypoint extensions are exposed
through typed properties.

- Repository: [gis-tools-gpx](https://github.com/Outdooractive/gis-tools-gpx)
- Product: `GISToolsGPX`
- Formats: GPX 1.1 read/write, GPX 1.0 read

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
    .package(
        url: "https://github.com/Outdooractive/gis-tools-gpx",
        from: "3.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
            .product(name: "GISToolsGPX", package: "gis-tools-gpx"),
        ]),
]
```

## Reading and writing

```swift
import GISTools
import GISToolsGPX

let collection = try GPXCoder.read(from: gpxURL)

// Or:
if let collection = FeatureCollection(gpx: gpxURL) {
    print(collection.features.count)
}

try collection.writeGPX(to: outputURL)
```

A feature's origin is available through `gpxType`:

```swift
for feature in collection.features {
    switch feature.gpxType {
    case .waypoint:
        print("Waypoint: \(feature.gpxName ?? "unnamed")")
    case .route:
        print("Route: \(feature.gpxName ?? "unnamed")")
    case .track:
        print("Track: \(feature.gpxName ?? "unnamed")")
    case nil:
        print("Unknown feature")
    }
}
```

Waypoint metadata includes `gpxName`, `gpxSymbol`, `gpxFix`, `gpxSatellites`,
`gpxHDOP`, `gpxTime` and links. Track and route geometry is accessed through
``Feature/geometry``:

```swift
let track = collection.features.first { $0.gpxType == .track }
let segments = (track?.geometry as? MultiLineString)?.lineStrings ?? []

let route = collection.features.first { $0.gpxType == .route }
let points = (route?.geometry as? LineString)?.coordinates ?? []
```

## Garmin TrackPointExtension v2

Point features expose individual sensor values:

```swift
var point = Feature(Point(Coordinate3D(latitude: 52.5, longitude: 13.3)))
point.gpxHeartRate = 145
point.gpxCadence = 90
point.gpxPower = 220
point.gpxSpeed = 12.5
point.gpxCourse = 45.0
point.gpxAirTemperature = 18.5
point.gpxDepth = 2.0
```

Track features accumulate the `<trkpt>` values into parallel arrays aligned with
the flattened geometry:

| Property | Type |
|---|---|
| `gpxHeartRates` | `[Int?]?` |
| `gpxCadences` | `[Int?]?` |
| `gpxPowers` | `[Int?]?` |
| `gpxSpeeds` | `[Double?]?` |
| `gpxAirTemperatures` | `[Double?]?` |
| `gpxElevations` | `[Double?]?` |

```swift
let heartRates = track?.gpxHeartRates ?? []
for (index, heartRate) in heartRates.enumerated() {
    if let heartRate {
        print("Point \(index): \(heartRate) bpm")
    }
}
```

Route features similarly expose per-route-point arrays:
`gpxRouteNames`, `gpxRouteTimes`, `gpxRouteComments`, `gpxRouteLinks` and
`gpxRouteExtensions`.

## Point conversion and slicing

```swift
let points = track?.gpxPointFeatures()

let morning = track?.gpxPointFeatures(from: startDate, to: endDate)
let lastKilometer = track?.gpxPointFeatures(
    from: totalMeters - 1_000.0,
    to: totalMeters)
let middle = track?.gpxPointFeatures(fraction: 0.33, to: 0.66)
```

Each point feature carries its own extension data, so `gpxHeartRate`,
`gpxSpeed` and the other typed accessors work on the generated points.

Reconstruct a track from point features:

```swift
if let points {
    let rebuilt = points.gpxTrackFromPointFeatures()
    let rebuiltViaFeature = Feature(gpxTrackFrom: points)
    print(rebuilt?.gpxHeartRates ?? [], rebuiltViaFeature?.gpxCadences ?? [])
}
```

Non-point features are skipped, and the result is `nil` when no point features
are present. The rebuilt track has one segment.

## Garmin GpxExtensions v3

Waypoints expose structured address, category and phone-number values:

```swift
if let waypoint = collection.features.first(where: { $0.gpxType == .waypoint }) {
    let address = waypoint.gpxAddress
    let categories = waypoint.gpxCategories
    let phoneNumbers = waypoint.gpxPhoneNumbers
}
```

Route-point extensions preserve Garmin autoroute points and other nested data
through `gpxRouteExtensions`. Raw extension dictionaries remain available when
a vendor extension has no typed helper.

## Writing and round-tripping

`GPXCoder.write(_:to:)` and `FeatureCollection.writeGPX(to:)` write valid GPX
1.1 XML. Feature element types, coordinates, properties and supported extension
namespaces are preserved. GPX 1.0 input is read-only; writing always emits GPX
1.1.

## Limitations

- GPX 1.0 is supported for reading only.
- Custom extension namespaces are preserved as raw values rather than typed
  models.
- Track reconstruction produces a single segment without lap splitting.

## Related packages

[CSV][csv], [FIT][fit], [GeoPackage][geopackage], [Shapefile][shapefile], [mvt-tools][mvttools]

[csv]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/csv
[fit]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/fit
[geopackage]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/geopackage
[shapefile]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/shapefile
[mvttools]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/mvttools

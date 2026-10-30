# FIT

`GISToolsFIT` reads and writes Garmin FIT (Flexible and Interoperable Data
Transfer) activity files. Records become a track ``Feature`` with a
``MultiLineString`` geometry, while session, lap, event, file-ID and activity
messages become feature properties and collection metadata.

- Repository: [gis-tools-fit](https://github.com/Outdooractive/gis-tools-fit)
- Product: `GISToolsFIT`
- Formats: FIT 2.0 with CRC validation

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
    .package(
        url: "https://github.com/Outdooractive/gis-tools-fit",
        from: "3.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
            .product(name: "GISToolsFIT", package: "gis-tools-fit"),
        ]),
]
```

## Reading

```swift
import GISTools
import GISToolsFIT

let collection = try FITCoder.read(from: fitURL)

// Or:
if let collection = FeatureCollection(fit: fitURL) {
    print(collection.features.count)
}
```

The record feature has a ``MultiLineString`` geometry. Each line string is one
lap segment:

```swift
let track = collection.features.first { $0.fitType == .record }
let multiLine = track?.geometry as? MultiLineString

print(multiLine?.lineStrings.count ?? 0)
print(multiLine?.lineStrings.flatMap(\.coordinates).count ?? 0)
```

## Per-point data

FIT record sensors are stored as parallel arrays indexed against the flattened
`MultiLineString` coordinates:

| Property | Type | FIT field |
|---|---|---|
| `fitHeartRates` | `[Int?]?` | `record.heart_rate` |
| `fitCadences` | `[Int?]?` | `record.cadence` |
| `fitPowers` | `[Int?]?` | `record.power` |
| `fitSpeeds` | `[Double?]?` | `record.speed` |
| `fitTemperatures` | `[Double?]?` | `record.temperature` |
| `fitAltitudes` | `[Double?]?` | `record.altitude` |
| `fitTimestamps` | `[Date?]?` | `record.timestamp` |

```swift
let heartRates = track?.fitHeartRates ?? []
for (index, heartRate) in heartRates.enumerated() {
    if let heartRate {
        print("Point \(index): \(heartRate) bpm")
    }
}
```

Single-record accessors such as `fitHeartRate`, `fitPower`, `fitSpeed`,
`fitDistance`, `fitPositionLat` and `fitPositionLon` are available for features
that represent one record. Session summaries include `fitAvgHeartRate`,
`fitMaxHeartRate`, `fitTotalDistance`, `fitTotalElapsedTime`,
`fitTotalCalories`, `fitTotalAscent` and `fitTotalDescent`.

## Point features and slicing

```swift
let points = track?.fitPointFeatures()
print(points?.features.count ?? 0)

let firstMinute = track?.fitPointFeatures(from: startDate, to: endDate)
let firstKilometer = track?.fitPointFeatures(from: 0.0, to: 1_000.0)
let middleThird = track?.fitPointFeatures(fraction: 0.33, to: 0.66)

if let points {
    let rebuilt = points.fitTrackFromPointFeatures()
    let rebuiltViaFeature = Feature(fitTrackFrom: points)
    print(rebuilt?.fitHeartRates ?? [], rebuiltViaFeature?.fitCadences ?? [])
}
```

Each point feature carries its own sensor data in `properties`, including
`heart_rate`, `power` and an ISO 8601 `timestamp`.

Non-point features are skipped. The reconstruction returns `nil` when no point
features exist and produces a single track segment.

## Collection metadata

```swift
let records = collection.fitRecords
let device = collection.fitDevice
let activity = collection.fitActivity
let sport = collection.fitSport
```

`fitRecords` returns the record features, `fitDevice` combines file-ID and
device-info metadata, `fitActivity` exposes the activity message and `fitSport`
maps the raw sport value to a name.

Raw enum values can be converted to human-readable names:

```swift
FIT.name(for: "event", value: 9)      // "lap"
FIT.name(for: "sport", value: 1)      // "running"
feature.fitEnumName(for: "event")     // e.g. "timer"
```

## Writing

```swift
try FITCoder.write(from: collection, to: outputURL)
try collection.writeFIT(to: outputURL)
```

The collection must contain a track feature with `fit_type == "record"` and a
`MultiLineString` geometry, as produced by `FITCoder.read(from:)`. The encoder
writes per-point sensor arrays and the session, lap, activity, file-ID, event
and device-info metadata back into the corresponding FIT messages. Round-trip
read → write → read preserves supported coordinates, sensor values and
timestamps.

## Limitations

- Compressed timestamp support is basic.
- Developer fields are parsed but not exposed through the typed API.
- The whole file is decoded in memory; very large activities can use
  significant memory.
- Vendor-specific FIT extensions may not be fully represented.

## Related packages

[CSV][csv], [GeoPackage][geopackage], [GPX][gpx], [Shapefile][shapefile], [mvt-tools][mvttools]

[csv]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/csv
[geopackage]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/geopackage
[gpx]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/gpx
[shapefile]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/shapefile
[mvttools]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/mvttools

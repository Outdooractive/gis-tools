# GeoJSON and WKB, WKT and TWKB

GISTools models every GeoJSON object with the ``GeoJson`` protocol and provides
loading, writing, parsing and binary/text coder APIs around that model.

## GeoJSON model

The geometry types are ``Point``, ``MultiPoint``, ``LineString``,
``MultiLineString``, ``Polygon``, ``MultiPolygon`` and
``GeometryCollection``. A ``Feature`` wraps a geometry with an identifier and
properties, and a ``FeatureCollection`` groups features.

Every object exposes:

- `type`, `projection` and `allCoordinates`
- `foreignMembers` for keys outside the GeoJSON specification
- `boundingBox` and `calculateBoundingBox()` through `BoundingBoxRepresentable`
- `asJson`, `asJsonData` and `asJsonString`
- `init?(json:)`, `init?(jsonData:)` and `init?(jsonString:)` from
  `GeoJsonConvertible`

`Feature.geometry` is optional. An explicit `"geometry": null` is preserved as
an unlocated feature with its identifier, properties and foreign members. A
missing geometry member is still invalid.

## Loading

Use ``GeoJsonReader`` when the concrete type is not known:

```swift
let object = GeoJsonReader.geoJsonFrom(jsonString: jsonString)
let object = GeoJsonReader.geoJsonFrom(jsonData: data)
let object = GeoJsonReader.geoJsonFrom(contentsOf: url)

switch object {
case let point as Point:
    print(point.coordinate)
case let collection as FeatureCollection:
    print(collection.features.count)
default:
    break
}
```

`GeoJsonReader` is lenient and silently drops malformed members. Use
``GeoJsonParser`` when diagnostics matter:

```swift
let result = try GeoJsonParser.parse(
    jsonString: jsonString,
    mode: .lenient)

for issue in result.issues {
    print(issue.path, issue.message)
}

let strict = try GeoJsonParser.parse(
    jsonString: jsonString,
    mode: .strict)
```

Strict mode throws the first ``GeoJsonParseIssue``; lenient mode returns the
parsed object plus every issue. Issues carry a JSON Pointer path. Typed
overloads return the requested concrete type and report a type mismatch as an
issue. The `Data` entry points also detect and decompress gzip input.

## Codable and SwiftData

The model types are `Codable`. `JSONDecoder` and `JSONEncoder` use the same
validated parser and writer as the GeoJSON convenience APIs:

```swift
let data = try JSONEncoder().encode(featureCollection)
let decoded = try JSONDecoder().decode(FeatureCollection.self, from: data)
```

SwiftData does not use the default `Codable` path. Register `GeoJsonTransformer`
before creating the model container, then mark stored GeoJSON properties as
transformable:

```swift
#if canImport(SwiftData)
import GISTools
import SwiftData

GeoJsonTransformer.register()

@Model
final class StoredFeature {
    @Attribute(.unique) var identifier: String

    @Attribute(.transformable(by: GeoJsonTransformer.name.rawValue))
    var geoJson: GeoJson?

    init(identifier: String, geoJson: GeoJson) {
        self.identifier = identifier
        self.geoJson = geoJson
    }
}

let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(
    for: StoredFeature.self,
    configurations: configuration)
let context = ModelContext(container)
let feature = Feature(
    Point(Coordinate3D(latitude: 48.1372, longitude: 11.5756)))

context.insert(StoredFeature(identifier: "munich", geoJson: feature))
try context.save()

let stored = try context.fetch(FetchDescriptor<StoredFeature>())
print(stored.first?.geoJson as Any)
#endif
```

The transformer serializes a `GeoJson` value to GeoJSON `Data` and restores it
through ``GeoJsonReader``. Use the same attribute for concrete geometry types
such as `Point`, `Polygon` or `FeatureCollection`.

Decoding is lenient when a collection contains malformed members, matching
`GeoJsonReader`; use ``GeoJsonParser`` when every malformed member must be
reported. The [SwiftData test cases](https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/SwiftDataTests.swift)
exercise insertion and fetching for every supported geometry type.

## WKB, WKT and TWKB

``WKBCoder``, ``WKTCoder`` and ``TWKBCoder`` support point, line string, linear
ring, polygon, multi-point, multi-line string, multi-polygon,
geometry collection and triangle geometry types.

Curved geometries are linearized into the existing model types while decoding:

| Input | Decoded as |
| --- | --- |
| `CircularString` | `LineString` |
| `CompoundCurve` | `LineString` |
| `CurvePolygon` | `Polygon` |
| `MultiCurve` | `MultiLineString` |
| `MultiSurface` | `MultiPolygon` |

`TIN` and `PolyhedralSurface` decode to a `MultiPolygon`, with every triangle
or patch represented as a `Polygon`. The mapping is lossy: re-encoding writes
the linear type, not the original curve or surface type.

`POINT EMPTY` decodes to an empty `MultiPoint` because the model has no empty
`Point`. The other empty geometries decode as their empty counterparts, and WKT
writes `TYPE EMPTY` when encoding an empty geometry.

WKB accepts both EWKB dimension flags and the ISO SQL/MM dimension codes used
by PostGIS (`+1000` for Z, `+2000` for M, `+3000` for ZM).

Every geometry also has convenience initializers for decoding and `asWKB` and
`asWKT` accessors. Decoding can reproject on the fly:

```swift
let point = try WKBCoder.decode(
    wkb: data,
    sourceProjection: .epsg4326,
    targetProjection: .epsg3857)

let encoded = point.asWKB
```

WKT works the same way:

```swift
let point = try WKTCoder.decode(
    wkt: "POINT Z (1 2 3)",
    sourceProjection: .epsg4326)

let encoded = point.asWKT
```

TWKB is decode-only:

```swift
let point = try TWKBCoder.decode(
    twkb: data,
    sourceProjection: .epsg4326)
```

TWKB empty metadata decodes to the corresponding empty geometry. PostGIS
encodes `TIN` as a `GeometryCollection` of polygons in TWKB, so it decodes as a
collection rather than a `MultiPolygon`. PostGIS rejects curves and
`PolyhedralSurface` when writing TWKB.

A `Feature` or `FeatureCollection` containing an unlocated feature cannot be
encoded to WKB or WKT; encoding returns `nil`.

## Next steps

- <doc:QueryDSL> for filtering features by properties and location.
- <doc:PerformanceAndMemory> for loading and encoding performance.
- <doc:MigrationGuide> for the 3.0 unlocated-feature and parsing changes.

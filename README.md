[![][image-1]][1]  
[![][image-2]][2]  
[![](https://img.shields.io/github/license/Outdooractive/gis-tools)](https://github.com/Outdooractive/gis-tools/blob/main/LICENSE)  
[![](https://img.shields.io/github/v/release/Outdooractive/gis-tools?sort=semver&display_name=tag)](https://github.com/Outdooractive/gis-tools/releases) [![](https://img.shields.io/github/release-date/Outdooractive/gis-tools?display_date=published_at
)](https://github.com/Outdooractive/gis-tools/releases)  
[![](https://img.shields.io/github/issues/Outdooractive/gis-tools
)](https://github.com/Outdooractive/gis-tools/issues) [![](https://img.shields.io/github/issues-pr/Outdooractive/gis-tools
)](https://github.com/Outdooractive/gis-tools/pulls)  
[![](https://img.shields.io/github/check-runs/Outdooractive/gis-tools/main)](https://github.com/Outdooractive/gis-tools/actions)


# GISTools
GIS tools for Swift, including a [GeoJSON][3] implementation and many algorithms ported from [https://turfjs.org][4].

## Table of Contents

- [GISTools](#gistools)
  - [Features](#features)
  - [Notes](#notes)
  - [Requirements](#requirements)
  - [Installation with Swift Package Manager](#installation-with-swift-package-manager)
  - [Package Traits](#package-traits)
  - [Usage](#usage)
- [GeoJSON](#geojson)
  - [GeoJson protocol](#geojson-protocol)
  - [BoundingBoxRepresentable protocol](#boundingboxrepresentable-protocol)
  - [GeoJsonConvertible protocol / GeoJsonCodable](#geojsonconvertible-protocol--geojsoncodable)
  - [GeoJsonReader](#geojsonreader)
  - [Coordinate3D](#coordinate3d)
  - [BoundingBox](#boundingbox)
  - [Point](#point)
  - [MultiPoint](#multipoint)
  - [LineString](#linestring)
  - [MultiLineString](#multilinestring)
  - [Polygon](#polygon)
  - [MultiPolygon](#multipolygon)
  - [GeometryCollection](#geometrycollection)
  - [Feature](#feature)
  - [FeatureCollection](#featurecollection)
- [Projections](#projections)
  - [Implemented projections](#implemented-projections)
- [SwiftData](#swiftdata)
- [WKB/WKT/TWKB](#wbkwkttwkb)
- [Spatial index](#spatial-index)
- [MapTile](#maptile)
- [Polylines](#polylines)
- [Query DSL](#query-dsl)
- [Algorithms](#algorithms)
- [Graph](#graph)
  - [Construction](#construction)
  - [Merge](#merge)
  - [Export](#export)
  - [Graph algorithms](#graph-algorithms)
- [Related packages](#related-packages)
- [Contributing](#contributing)
- [License](#license)
- [Authors](#authors)

## Features

- Supports the full [GeoJSON standard][6]
- Load and write GeoJSON objects from and to `[String:Any]`, `URL`, `Data` and `String`
- Supports `Codable` and `SwiftData` (see below)
- Supports a wide range of projections (see [Projections](#projections)): EPSG:4326 (geodetic), 3857 (web mercator), 4978 (ECEF geocentric), 3395 (World Mercator), 32662 (Plate Carree), 4258 (ETRS89), 4267 (NAD27), 4269 (NAD83), 4277/27700 (OSGB 1936 / British National Grid), 2056/21781 (Swiss CH1903+/LV95 and CH1903/LV03), 29902/29903/2157 (Irish Grid and Irish Transverse Mercator), 25831–25837 (ETRS89/UTM), 26901–26960 (NAD83/UTM), 3035/3034 (EU-wide LAEA and LCC), 5070 (US Conus Albers), 3005 (BC Albers), 3347/3978 (Canadian Lambert), 2154 (French Lambert-93), 28992 (Dutch RD New), 31466–31469 (German DHDN/Gauss-Krüger), 31255–31259 (Austrian MGI/Gauss-Krüger) and all 120 WGS84 UTM zones, plus user-definable custom projections
- Supports WKT/WKB/TWKB, also with different projections
- [**gis-tools-shapefile**](https://github.com/Outdooractive/gis-tools-shapefile) — reads and writes ESRI Shapefiles (.shp/.dbf/.shx/.prj)
- [**gis-tools-geopackage**](https://github.com/Outdooractive/gis-tools-geopackage) — reads and writes OGC GeoPackage (.gpkg) files
- [**gis-tools-gpx**](https://github.com/Outdooractive/gis-tools-gpx) — reads and writes GPX 1.1 files (.gpx)
- [**gis-tools-fit**](https://github.com/Outdooractive/gis-tools-fit) — reads and writes FIT activity files (.fit)
- Spatial search with a R-tree
- Includes many spatial algorithms (ported from turf.js), and more to come
- Many algorithms accept a `gridSize` parameter to snap coordinates to a uniform grid before computation, reducing noise from floating-point precision
- Handles coordinates across the anti-meridian (±180° longitude) — geometries can wrap around the date line
- Has a helper for working with x/y/z map tiles (center/bounding box/resolution/…)
- Can encode/decode Polylines
- Includes a property/spatial query DSL for filtering features (`QueryParser`)
- Includes a `Graph` type for routing and network analysis — Dijkstra, A*, bidirectional search, K-shortest paths, multi-criteria routing, chain contraction, dead-end pruning, bridge/articulation-point detection, betweenness centrality, strongly connected components, minimum spanning tree, Eulerian/Chinese Postman tours, TSP approximation, graph tile merging with spatial deduplication, and export back to GeoJSON
- Pure Swift without external dependencies

## Notes

This package makes some assumptions about what is equal, i.e. coordinates that are inside of `1e-10` degrees are regarded as equal (that's μm precision and is probably overkill). See [GISTool.equalityDelta][5].

Per [RFC 7946 §3.1.9](https://tools.ietf.org/html/rfc7946#section-3.1.9), geometries crossing the anti-meridian (±180°) should be cut into parts.
The `cutAtAntimeridian()` functions return a `FeatureCollection`
with one `Feature` per cut geometry part. This makes iterating the results uniform regardless of the input type.
Works natively for EPSG:4326 and EPSG:3857 (splits at ±180° and ±originShift respectively).
For EPSG:4978 and noSRID, returns the original geometry unchanged (the antimeridian concept does not apply).

## Requirements

This package requires Swift 6.1 or higher (at least Xcode 15), and compiles on iOS (\>= iOS 15), macOS (\>= macOS 15), tvOS (\>= tvOS 15), watchOS (\>= watchOS 7) as well as Linux, Android and Wasm.

## Installation with Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools", from: "2.3.0"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "GISTools", package: "gis-tools"),
    ]),
]
```

## Package Traits

This package provides the following optional traits:

**Unit conversion traits** (mutually exclusive):
- `EnableMeasurementConversionExtensions` — conversion properties return `Measurement<UnitLength>` values, enabling unit-aware arithmetic and formatting.
- `EnableMeterConversionExtensions` — conversion properties return raw `Double` meters, providing a lightweight alternative.

```swift
// With EnableMeasurementConversionExtensions:
let distance: Measurement<UnitLength> = 1000.0.meters
let total = distance + 500.0.feet  // Measurement arithmetic

// With EnableMeterConversionExtensions:
let distance: Double = 1000.0.meters  // raw meters
let total = distance + 500.0.feet     // Double arithmetic (both in meters)
```

## Usage

Please see also the [API documentation][8] (via Swift Package Index).

```swift
import GISTools

var feature = Feature(Point(Coordinate3D(latitude: 3.870163, longitude: 11.518585)))
feature.properties = [
    "test": 1,
    "test2": 5.567,
    "test3": [1, 2, 3],
    "test4": [
        "sub1": 1,
        "sub2": 2
    ]
]

// To and from String:
let jsonString = feature.asJsonString(prettyPrinted: true)
let feature = Feature(jsonString: jsonString)

// To and from Data:
let jsonData = feature.asJsonData(prettyPrinted: true)
let feature = Feature(jsonData: jsonData)

// Using Codable:
let jsonData = try JSONEncoder().encode(feature)
let feature = try JSONDecoder().decode(Feature.self, from: jsonData)

// Generic:
let someGeoJson = GeoJsonReader.geoJsonFrom(json: [
    "type": "Point",
    "coordinates": [100.0, 0.0],
])
let someGeoJson = GeoJsonReader.geoJsonFrom(contentsOf: URL(...))
let someGeoJson = GeoJsonReader.geoJsonFrom(jsonData: Data(...))
let someGeoJson = GeoJsonReader.geoJsonFrom(jsonString: "{\"type\":\"Point\",\"coordinates\":[100.0,0.0]}")

switch someGeoJson {
case let point as Point: ...
}
// or
switch someGeoJson.type {
case .point: ...
}

// Wraps *any* GeoJSON into a FeatureCollection
let featureCollection = FeatureCollection(jsonData: someData)
let featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: someData)

...
```

See the [tests for more examples][9] and also the [API documentation][10].

# GeoJSON
To quote from the [RFC 7946][11]:
> GeoJSON is a geospatial data interchange format based on JavaScript Object Notation (JSON).  
> It defines several types of JSON objects and the manner in which they are combined to represent data about geographic features, their properties, and their spatial extents.  
> GeoJSON uses a geographic coordinate reference system, World Geodetic System 1984, and units of decimal degrees.

Please read the RFC first to get an overview of what GeoJSON is and is not (in the somewhat unlikely case that you don’t already know all of this… 🙂).

## GeoJson protocol
[Implementation][12]

The basics for every GeoJSON object:
```swift
/// All permitted GeoJSON types.
public enum GeoJsonType: String {
    case point              = "Point"
    case multiPoint         = "MultiPoint"
    case lineString         = "LineString"
    case multiLineString    = "MultiLineString"
    case polygon            = "Polygon"
    case multiPolygon       = "MultiPolygon"
    case geometryCollection = "GeometryCollection"
    case feature            = "Feature"
    case featureCollection  = "FeatureCollection"
}

/// GeoJSON object type.
var type: GeoJsonType { get }

/// The GeoJSON's projection, which should typically be EPSG:4326.
var projection: Projection { get }

/// All of the receiver's coordinates.
var allCoordinates: [Coordinate3D] { get }

/// Any foreign members, i.e. keys in the JSON that are
/// not part of the GeoJSON standard.
var foreignMembers: [String: Any] { get set }

/// Try to initialize a GeoJSON object from any JSON and calculate a bounding box if necessary.
init?(json: Any?, calculateBoundingBox: Bool)

/// Type erased equality check.
func isEqualTo(_ other: GeoJson) -> Bool
```

## BoundingBoxRepresentable protocol
[Implementation][13]

All GeoJSON objects may have a bounding box. It is required though if you want to use the R-tree spatial index (see below).

```swift
/// The GeoJSON's projection.
var projection: Projection { get }

/// The receiver's bounding box.
var boundingBox: BoundingBox? { get set }

/// Calculates and returns the receiver's bounding box.
func calculateBoundingBox() -> BoundingBox?

/// Calculates the receiver's bounding box and updates the `boundingBox` property.
///
/// - parameter ifNecessary: Only update the bounding box if the receiver doesn't already have one.
@discardableResult
mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool) -> BoundingBox?

/// Check if the receiver is inside or crosses  the other bounding box.
///
/// - parameter otherBoundingBox: The bounding box to check.
func intersects(_ otherBoundingBox: BoundingBox) -> Bool
```

## GeoJsonConvertible protocol / GeoJsonCodable
[Implementation][14]

GeoJSON objects can be initialized from a variety of sources:
```swift
/// Try to initialize a GeoJSON object from any JSON.
init?(json: Any?)

/// Try to initialize a GeoJSON object from a file.
init?(contentsOf url: URL)

/// Try to initialize a GeoJSON object from a data object.
init?(jsonData: Data)

/// Try to initialize a GeoJSON object from a string.
init?(jsonString: String)

/// Try to initialize a GeoJSON object from a Decoder.
init(from decoder: Decoder) throws
```

They can also be exported in several ways:
```swift
/// Return the GeoJson object as Key/Value pairs.
var asJson: [String: Any] { get }

/// Dump the object as JSON data.
func asJsonData(prettyPrinted: Bool = false) -> Data?

/// Dump the object as a JSON string.
func asJsonString(prettyPrinted: Bool = false) -> String?

/// Write the object in it's JSON represenation to a file.
func write(to url: URL, prettyPrinted: Bool = false) throws

/// Write the GeoJSON object to an Encoder.
func encode(to encoder: Encoder) throws
```

Example:
```swift
let point = Point(jsonString: "{\"type\":\"Point\",\"coordinates\":[100.0,0.0]}")!
print(point.allCoordinates)
print(point.asJsonString(prettyPrinted: true)!)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(point)

// This works because `FeatureCollection` will wrap any valid GeoJSON object.
// This is a good way to enforce a common structure for all loaded objects.
let featureCollection = FeatureCollection(jsonData: data)!
```

Important note: Import and export will always be done in EPSG:4326, with one exception: GeoJSON objects with no SRID will be exported as-is.

## GeoJsonReader
[Implementation][15]

This is a generic way to create GeoJSON objects from anything that looks like GeoJSON:
```swift
/// Try to initialize a GeoJSON object from any JSON.
static func geoJsonFrom(json: Any?) -> GeoJson?

/// Try to initialize a GeoJSON object from a file.
static func geoJsonFrom(contentsOf url: URL) -> GeoJson?

/// Try to initialize a GeoJSON object from a data object.
static func geoJsonFrom(jsonData: Data) -> GeoJson?

/// Try to initialize a GeoJSON object from a string.
static func geoJsonFrom(jsonString: String) -> GeoJson?
```

The reader can also auto-detect a geometry from a string or data payload, regardless of whether it is GeoJSON, WKT (with or without an `SRID=…;` prefix), or hex-encoded WKB/EWKB/TWKB:
```swift
/// Try to initialize a geometry from a string, auto-detecting the format.
static func geometryFrom(string: String, targetProjection: Projection = .epsg4326) -> GeoJsonGeometry?

/// Try to initialize a geometry from data, auto-detecting the format.
static func geometryFrom(data: Data, targetProjection: Projection = .epsg4326) -> GeoJsonGeometry?
```

Example:
```swift
// A PostGIS EWKB hex string (SRID 3857) is decoded and projected to EPSG:4326.
let ewkb = "0102000020110F00000F000000B1AB426CB24C3141FF9A56141D015741..."
let lineString = GeoJsonReader.geometryFrom(string: ewkb) as! LineString

// Plain WKT and SRID-prefixed WKT are both recognized.
let point = GeoJsonReader.geometryFrom(string: "SRID=4326;POINT (11.5 48.1)") as! Point
```

The `geoJsonFrom` methods work on any GeoJSON-shaped input:
```swift
let json: [String: Any] = [
    "type": "Point",
    "coordinates": [100.0, 0.0],
    "other": "something",
]
let geoJson = GeoJsonReader.geoJsonFrom(json: json)!
print("Type is \(geoJson.type.rawValue)")
print("Foreign members: \(geoJson.foreignMembers)")

switch geoJson {
case let point as Point:
    print("It's a Point!")
case let multiPoint as MultiPoint:
    print("It's a MultiPoint!")
case let lineString as LineString:
    print("It's a LineString!")
case let multiLineString as MultiLineString:
    print("It's a MultiLineString!")
case let polygon as Polygon:
    print("It's a Polygon!")
case let multiPolygon as MultiPolygon:
    print("It's a MultiPolygon!")
case let geometryCollection as GeometryCollection:
    print("It's a GeometryCollection!")
case let feature as Feature:
    print("It's a Feature!")
case let featureCollection as FeatureCollection:
    print("It's a FeatureCollection!")
default: 
    assertionFailure("Missed an object type?")
}
```

Important note: Import will always be done in EPSG:4326.

## Coordinate3D
[Implementation][16] / [Coordinate test cases][17]

Coordinates are the most basic building block in this package. Every object and algorithm builds on them:
```swift
/// The coordinates projection, either EPSG:4326 or EPSG:3857.
let projection: Projection

/// The coordinate's `latitude`.
var latitude: CLLocationDegrees
/// The coordinate's `longitude`.
var longitude: CLLocationDegrees
/// The coordinate's `altitude`.
var altitude: CLLocationDistance?

/// Linear referencing, timestamp or whatever you want it to use for.
///
/// The GeoJSON specification doesn't specifiy the meaning of this value,
/// and it doesn't guarantee that parsers won't ignore or discard it. See
/// https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.1.
/// - Important: The JSON for a coordinate will contain a `null` altitude value
///              if `altitude` is `nil` so that `m` won't get lost (since it is
///              the 4th value).
///              This might lead to compatibilty issues with other GeoJSON readers.
var m: Double?

/// Alias for longitude
var x: Double { longitude }

/// Alias for latitude
var y: Double { latitude }

/// Create a coordinate with `latitude`, `longitude`, `altitude` and `m`.
/// Projection will be EPSG:4326.
init(latitude: CLLocationDegrees,
     longitude: CLLocationDegrees,
     altitude: CLLocationDistance? = nil,
     m: Double? = nil)

/// Create a coordinate with ``x``, ``y``, ``z`` and ``m``.
/// Default projection will we EPSG:3857 but can be overridden.
init(
    x: Double,
    y: Double,
    z: Double? = nil,
    m: Double? = nil,
    projection: Projection = .epsg3857)

/// Reproject this coordinate.
func projected(to newProjection: Projection) -> Coordinate3D
```

Example:
```swift
let coordinate = Coordinate3D(latitude: 0.0, longitude: 0.0)
print(coordinate.isZero)
```

# Projections
[Implementation][20]

Coordinates carry their projection with them and all operations keep them in it. Coordinates can be re-projected:

```swift
let coordinate = Coordinate3D(latitude: 41.0, longitude: -71.0)
let utm19 = coordinate.projected(to: .epsg32619)   // UTM zone 19N
let mercator = utm19.projected(to: .epsg3857)
let projectedBack = mercator.projected(to: .epsg4326)
print(coordinate.projection.description, coordinate.projection.srid)
```

UTM zones can also be selected from a coordinate — including the EPSG Norway
("32V") and Svalbard ("31X/32X/33X/35X/37X") banding exceptions:

```swift
let oslo = Coordinate3D(latitude: 59.91149, longitude: 10.75793)
let utm = Projection.utmZone(for: oslo)   // EPSG:32632 (zone 32, the Norwegian exception)
let osloUtm = oslo.projected(to: utm)
```

Densification, buffer, distance etc. automatically take the projection into account. Beyond the built-in projections listed below, custom projections can be registered - registration is add-only, applied for the whole process, typically at startup. Datums of built-in CRSs can be inspected via `Projection.epsg27700.datum` (== `Datum.osgb1936`, Airy 1830):

```swift
let custom = CustomProjection(
    srid: 900_001,
    kind: .planar,
    validExtent: ProjectionExtent(minX: -200_000, minY: -200_000, maxX: 200_000, maxY: 200_000),
    forward: { coordinate in
        Coordinate3D(latitude: coordinate.latitude * 1_000.0,
                     longitude: coordinate.longitude * 1_000.0)
    },
    inverse: { coordinate in
        Coordinate3D(latitude: coordinate.latitude / 1_000.0,
                     longitude: coordinate.longitude / 1_000.0)
    })
Projection.register(custom)

let customProjection = try Projection(srid: 900_001)
```

## Implemented projections

| EPSG | Response | Coordinate units | Transformation | Source |
| --- | --- | --- | --- | --- |
| 4326 | WGS84 geodetic | degrees | pivot | `ProjectionDefinition.swift` |
| 3857 | Web Mercator | meters | spherical Mercator | [Epsg3857Definition.swift][290] |
| 4978 | WGS84 geocentric (ECEF) | meters | geodetic <-> geocentric (WGS84) | [Epsg4978Definition.swift][291] |
| 3395 | WGS84 / World Mercator | meters | ellipsoidal Mercator | [Epsg3395Definition.swift][292] |
| 32662 | WGS84 / Plate Carree | degrees | identity | [Epsg32662Definition.swift][293] |
| 4258 | ETRS89 geodetic | degrees | identity (≈ WGS84) | [Etrs89Definition.swift][294] |
| 4267 | NAD27 geodetic | degrees | Helmert "NAD27 to WGS 84 (4)", ~10 m | [Nad27Definition.swift][295] |
| 4277 | OSGB 1936 geodetic | degrees | Helmert "OSGB 1936 to WGS 84 (6)", ~2 m | [Osgb1936Definition.swift][297] |
| 27700 | OSGB 1936 / British National Grid | meters | Helmert + TM on Airy 1830 | [Osgb1936BngDefinition.swift][296] |
| 32601–32660 | UTM zones 1N–60N | meters | transverse Mercator, Karney series (WGS84) | [UtmDefinition.swift][298] |
| 32701–32760 | UTM zones 1S–60S | meters | transverse Mercator, Karney series (WGS84) | [UtmDefinition.swift][298] |
| 2056 | CH1903+ / LV95 | meters | Helmert "CH1903+ to WGS 84 (1)" + Swiss oblique Mercator on Bessel 1841 | [Ch1903PlusLv95Definition.swift][285] |
| 21781 | CH1903 / LV03 | meters | same projection, false easting/northing shifted | [Ch1903Lv03Definition.swift][286] |
| 29902 | TM65 / Irish Grid | meters | Helmert "TM65 to WGS 84 (2)" + TM on Modified Airy | [IrishGridTM65Definition.swift][287] |
| 29903 | TM75 / Irish Grid | meters | same projection, TM75 datum | [IrishGridTM75Definition.swift][288] |
| 2157 | IRENET95 / Irish Transverse Mercator | meters | TM on GRS80 (≈ WGS84) | [IrishTransverseMercatorDefinition.swift][289] |
| 25831–25837 | ETRS89/UTM zones 31N–37N | meters | transverse Mercator, Karney series (GRS80, ≈ WGS84) | [Etrs89UtmDefinition.swift][299] |
| 3035 | ETRS89-LAEA Europe | meters | Lambert azimuthal equal-area (GRS80, ≈ WGS84) | [Etrs89LaeaDefinition.swift][300] |
| 3034 | ETRS89-LCC Europe | meters | Lambert conformal conic 35°/65° (GRS80, ≈ WGS84) | [Etrs89LccDefinition.swift][301] |
| 2154 | RGF93 / Lambert-93 | meters | Lambert conformal conic 49°/44° (GRS80, ≈ WGS84) | [Lambert93Definition.swift][302] |
| 28992 | Amersfoort / RD New | meters | Helmert "Amersfoort to WGS 84 (4)" + oblique stereographic on Bessel 1841 | [RdNewDefinition.swift][303] |
| 31466–31469 | DHDN / Gauss-Krüger zones 2–5 | meters | Helmert "DHDN to WGS 84 (2)", ~3 m + transverse Mercator, Karney series (Bessel 1841) | [DhdnGkDefinition.swift][304] |
| 31255–31259 | MGI / Austria Gauss-Krüger | meters | Helmert "MGI to WGS 84 (2)", ~1.5 m + transverse Mercator, Karney series (Bessel 1841) | [MgiGkDefinition.swift][305] |
| 4269 | NAD83 geodetic | degrees | identity (≈ WGS84) | [Nad83Definition.swift][306] |
| 26901–26960 | NAD83 / UTM zones 1N–60N | meters | transverse Mercator, Karney series (GRS80, ≈ WGS84) | [Nad83UtmDefinition.swift][307] |
| 5070 | NAD83 / Conus Albers | meters | Albers equal-area (GRS80, ≈ WGS84) | [Epsg5070Definition.swift][308] |
| 3005 | NAD83 / BC Albers | meters | Albers equal-area (GRS80, ≈ WGS84) | [Epsg3005Definition.swift][309] |
| 3347 | NAD83 / Statistics Canada Lambert | meters | Lambert conformal conic (GRS80, ≈ WGS84) | [Epsg3347Definition.swift][310] |
| 3978 | NAD83 / Canada Atlas Lambert | meters | Lambert conformal conic (GRS80, ≈ WGS84) | [Epsg3978Definition.swift][311] |

Custom projections register through `Projection.register(CustomProjection)` (see [CustomProjection.swift][31]); the model types live in `Projection.swift`/`ProjectionKind.swift`/`ProjectionExtent.swift`/`Datum.swift` and the WKT matching / registry in `ProjectionRegistry.swift` resp. `ProjectionDefinition.swift` in `Sources/GISTools/Projections/`.

All algorithms dispatch on the projection *kind* (geographic/planar/geocentric) and honor the definition's capabilities (wraparound extents, valid ranges, world bounding boxes), so custom projections work across the whole library like built-in ones.

### Datum accuracy note
The datum-capable built-in projections (NAD27, OSGB 1936, British National Grid, Swiss LV95/LV03, Irish Grid TM65/TM75 and Dutch RD New) use the published EPSG Helmert transformations ("NAD27 to WGS 84 (4)", ~10 m; "OSGB 1936 to WGS 84 (6)" / EPSG:1314, ~2 m; "CH1903+ to WGS 84 (1)" / EPSG:1676, ~1 m; "TM65 to WGS 84 (2)" / EPSG:1641, ~1 m; "Amersfoort to WGS 84 (4)" / [EPSG:4833](https://epsg.io/4833), ~1 m). Sub-meter-centimeter accuracy for NAD27 (NADCON), Great Britain (OSTN15, EPSG:7709), Switzerland (CHENyx06a.gsb, EPSG:15486) or the Netherlands (RD-transformation grids) requires grid shift files, which the library deliberately does not bundle (see [#248]). Datum transformations are parameterized via `HelmertTransformation` for use in your own `CustomProjection` definitions.

Attribution: EPSG parameter values are based on the EPSG dataset (https://epsg.org) used under its terms; OS transform parameters reference the Ordnance Survey *Guide to Coordinate Systems in Great Britain*. The UTM zones use Karney's transverse Mercator (the Krüger series to 6th order, [arXiv:1002.1417](https://arxiv.org/abs/1002.1417)), accurate to nanometers anywhere within the zones instead of the Snyder series' ±3–4° degradation; compared to the previous Snyder-based values the results shift at the sub-millimeter level in-zone.

# SwiftData

You need to use a transformer for using GeoJson with SwiftData (also have a look at the [SwiftData test cases](https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/SwiftDataTests.swift)).

First, register the transformer like this:
```swift
GeoJsonTransformer.register()
```

Then create your models like this:
```swift
@Attribute(.transformable(by: GeoJsonTransformer.name.rawValue)) var geoJson: GeoJson?
@Attribute(.transformable(by: GeoJsonTransformer.name.rawValue)) var point: Point?
...
```

This is necessary because SwiftData doesn't work well with the default Codable implementation, so you need to do the serialization for yourself...

# WKB/WKT/TWKB
The following geometry types are supported: `point`, `linestring`, `linearring`, `polygon`, `multipoint`, `multilinestring`, `multipolygon`, `geometrycollection` and `triangle`. Please open an issue if you need more.

Every GeoJSON object has convenience methods to encode and decode themselves to and from WKB/WKT, and there are extensions for `Data` and `String` to decode from WKB, WKT and TWKB to GeoJSON. In the end, they all forward to `WKBCoder`, `WKTCoder` and `TWKBCoder` which do the heavy lifting.

## WKB
Also have a look at  the [WKB test cases][40].

Decoding:
```swift
// SELECT 'POINT Z (1 2 3)'::geometry;
private let pointZData = Data(hex: "0101000080000000000000F03F00000000000000400000000000000840")!

// Generic
let point = try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as! Point
let point = pointZData.asGeoJsonGeometry(sourceProjection: .epsg4326) as! Point

// Or create the geometry directly
let point = Point(wkb: pointZData, sourceProjection: .epsg4326)!

// Or create a Feature that contains the geometry
let feature = Feature(wkb: pointZData, sourceProjection: .epsg4326)
let feature = pointZData.asFeature(sourceProjection: .epsg4326)

// Or create a FeatureCollection that contains a feature with the geometry
let featureCollection = FeatureCollection(wkb: pointZData, sourceProjection: .epsg4326)
let featureCollection = pointZData.asFeatureCollection(sourceProjection: .epsg4326)

// Can also reproject on the fly
let point = try WKBCoder.decode(
    wkb: pointData,
    sourceProjection: .epsg4326,
    targetProjection: .epsg3857
) as! Point
print(point.projection)
```

Encoding:
```swift
let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

// Generic
let encodedPoint = WKBCoder.encode(geometry: point, targetProjection: nil)

// Convenience
let encodedPoint = point.asWKB
```

## WKT
This is exactly the same as WKB… Also have a look at the tests to see how it works: [WKT test cases][41]

Decoding:
```swift
private let pointZString = "POINT Z (1 2 3)"

// Generic
let point = try WKTCoder.decode(wkt: pointZString, sourceProjection: .epsg4326) as! Point
let point = pointZString.asGeoJsonGeometry(sourceProjection: .epsg4326) as! Point

// Or create the geometry directly
let point = Point(wkt: pointZString, sourceProjection: .epsg4326)!

// Or create a Feature that contains the geometry
let feature = Feature(wkt: pointZString, sourceProjection: .epsg4326)
let feature = pointZString.asFeature(sourceProjection: .epsg4326)

// Or create a FeatureCollection that contains a feature with the geometry
let featureCollection = FeatureCollection(wkt: pointZString, sourceProjection: .epsg4326)
let featureCollection = pointZString.asFeatureCollection(sourceProjection: .epsg4326)

// Can also reproject on the fly
let point = try WKTCoder.decode(
    wkt: pointZString,
    sourceProjection: .epsg4326,
    targetProjection: .epsg3857
) as! Point
print(point.projection) // EPSG:3857
```

Encoding:
```swift
let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

// Generic
let encodedPoint = WKTCoder.encode(geometry: point, targetProjection: nil)

// Convenience
let encodedPoint = point.asWKT
```

## TWKB
This is a decode-only coder for [Tiny WKB][154]. Also have a look at the [TWKB test cases][155].

Decoding:
```swift
// TWKB Point at (0, 0) with precision 6
private let pointData = Data([0x61, 0x00, 0x00, 0x00])

// Generic
let point = try TWKBCoder.decode(twkb: pointData) as! Point
let point = pointData.asGeoJsonGeometryFromTWKB(sourceProjection: .epsg4326) as! Point

// Or with sourceSrid
let point = try TWKBCoder.decode(twkb: pointData, sourceSrid: 4326) as! Point
let point = pointData.asGeoJsonGeometryFromTWKB(sourceSrid: 4326) as! Point

// Or create the geometry directly
let point = Point(twkb: pointData)!

// Or create a Feature that contains the geometry
let feature = Feature(twkb: pointData)
let feature = pointData.asFeatureFromTWKB(sourceProjection: .epsg4326)

// Or create a FeatureCollection that contains a feature with the geometry
let featureCollection = FeatureCollection(twkb: pointData)
let featureCollection = pointData.asFeatureCollectionFromTWKB(sourceProjection: .epsg4326)

// Can also reproject on the fly
let point = try TWKBCoder.decode(
    twkb: pointData,
    sourceProjection: .epsg4326,
    targetProjection: .epsg3857
) as! Point
print(point.projection) // EPSG:3857
```

# Spatial index
This package includes a simple R-tree implementation: [RTree test cases][42]

```swift
var nodes: [Point] = []
50.times {
    nodes.append(Point(Coordinate3D(
        latitude: Double.random(in: -10.0 ... 10.0),
        longitude: Double.random(in: -10.0 ... 10.0))))
    }

let rTree = RTree(nodes)
let objects = rTree.search(inBoundingBox: boundingBox)
let objectsAround = rTree.search(aroundCoordinate: center, maximumDistance: maximumDistance)
```

# MapTile
This is a helper for working with x/y/z map tiles.

```swift
let tile1 = MapTile(x: 138513, y: 91601, z: 18)
let center = tile1.centerCoordinate(projection: .epsg4326) // default
let boundingBox = tile1.boundingBox(projection: .epsg4326) // default

let tile2 = MapTile(coordinate: Coordinate3D(latitude: 47.56, longitude: 10.22), atZoom: 14)
let parent = tile2.parent
let firstChild = tile2.child
let allChildren = tile2.children

let quadkey = tile1.quadkey
let tile3 = MapTile(quadkey: "1202211303220032")
```

Also, not directly related to map tiles:
```swift
let mpp = MapTile.metersPerPixel(at: 15.0, latitude: 45.0)
```

# Polylines
Provides an encoder/decoder for Polylines.

```swift
let polyline = [Coordinate3D(latitude: 47.56, longitude: 10.22)].encodePolyline()
let coordinates = polyline.decodePolyline()
```

# Query DSL

This package includes a query DSL parser and evaluator for filtering `Feature` objects by their properties and spatial location. The parser uses Reverse Polish Notation (RPN) internally but accepts a natural infix syntax.

## QueryParser

```swift
let parser = QueryParser(string: ".highway == primary and .name =~ '^Main'")
let matches = parser.evaluate(on: someFeature)
```

### Property access

Properties are accessed by prefixing the key with `.`:

| Query | Meaning |
|-------|---------|
| `.name` | Property `name` exists and is truthy |
| `.foo.bar` | Nested property `foo → bar` |
| `."foo.bar"` | Property whose key contains a dot |
| `.foo.[0]` | First element of array property `foo` |
| `.some.0` | Shorthand for array access |

### Comparisons

| Operator | Meaning | Example |
|----------|---------|---------|
| `==` | Equal | `.value == 1` |
| `!=` | Not equal | `.value != 2` |
| `>` | Greater than | `.value > 0` |
| `>=` | Greater or equal | `.value >= 1` |
| `<` | Less than | `.value < 2` |
| `<=` | Less or equal | `.value <= 1` |
| `=~` | Regex match | `.name =~ /^Main/i` |
| `=*` | String contains | `.name =* "ain"` |
| `=^` | String starts with | `.name =^ "Mai"` |
| `=$` | String ends with | `.name =$ "ain"` |

Cross-type numeric comparisons work automatically (e.g. `Int` vs `Double`).

### Set membership

```
.class in ["primary", "secondary"]
.value in [1, 3, 5]
```

### Grouping with parentheses

Expressions can be grouped with `(` and `)` to override default left-to-right evaluation:

```
(.name == "Berlin" OR .name == "Paris") AND .population > 100000
NOT (.bridge exists) OR .oneway == true
(.highway in ["primary", "secondary"] AND .surface == "asphalt") OR .bridge == "yes"
```

Parentheses may be nested up to any depth.

### Boolean logic

| Operator | Meaning | Example |
|----------|---------|---------|
| `and` | Logical AND | `.a == 1 and .b == 2` |
| `or` | Logical OR | `.a == 1 or .b == 1` |
| `not` | Logical NOT | `.a not` |
| `exists` | Truthy check | `.a exists` |

### Spatial predicates

| Predicate | Syntax | Meaning |
|-----------|--------|---------|
| `near` | `near(lat, lon, tolerance)` | Feature centroid is within `tolerance` meters |
| `within` | `within(minLon, minLat, maxLon, maxLat)` | Feature bbox is fully inside the rectangle |
| `intersects` | `intersects(minLon, minLat, maxLon, maxLat)` | Feature geometry intersects the rectangle |

## Convenience methods

```swift
// Filter a FeatureCollection by query string
let hospitals = featureCollection.query(term: ".class == 'hospital'")

// Filter an array of Features
let matches = features.query(term: ".name =~ /hospital/i and near(48.85, 2.35, 1000)")

// Complex grouped query
let result = featureCollection.query(term: "(.amenity == \"restaurant\" AND .stars >= 3) OR .cuisine == \"italian\"")
```

# GeoPackage (.gpkg)

GeoPackage support has been extracted into its own package: [**gis-tools-geopackage**](https://github.com/Outdooractive/gis-tools-geopackage).

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools-geopackage", from: "1.0.0"),
]
```

# Shapefile (.shp / .dbf / .shx / .prj)

Shapefile support has been extracted into its own package: [**gis-tools-shapefile**](https://github.com/Outdooractive/gis-tools-shapefile).

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools-shapefile", from: "1.0.0"),
]
```

# GPX (.gpx)

GPX support has been extracted into its own package: [**gis-tools-gpx**](https://github.com/Outdooractive/gis-tools-gpx).

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools-gpx", from: "1.0.0"),
]
```

# FIT (.fit)

FIT support has been extracted into its own package: [**gis-tools-fit**](https://github.com/Outdooractive/gis-tools-fit).

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools-fit", from: "1.0.0"),
]
```

# Algorithms
Hint: Most algorithms are optimized for EPSG:4326. Using other projections will have a performance penalty due to added projections.<br>
The union algorithm works in EPSG:3857 (Web Mercator) for uniform Cartesian tolerances. This limits its usable latitude range to approximately ±85°.

| Name                        | Example                                                                                                                               |     | Source/Tests                 |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --- | ---------------------------- |
| along                       | `let coordinate = lineString.coordinateAlong(distance: 100.0)`                                                                        |     | [Source][43] / [Tests][44]   |
| antimeridian-cutting        | `let result = lineString.cutAtAntimeridian()`                                                                                         |     | [Source][131] / [Tests][132] |
| area                        | `Polygon(…).area`                                                                                                                     |     | [Source][45]                 |
| bearing                     | `Coordinate3D(…).bearing(to: Coordinate3D(…))`                                                                                        |     | [Source][46] / [Tests][47]   |
| bezier-spline               | `let spline = lineString.bezierSpline()`                                                                                              |     | [Source][217] / [Tests][218] |
| boolean-clockwise           | `Polygon(…).outerRing?.isClockwise`                                                                                                   |     | [Source][48] / [Tests][49]   |
| boolean-concave             | `anyGeometry.isConcave()`                                                                                                             |     | [Source][177] / [Tests][178] |
| boolean-contains/within     | `polygon.contains(lineString)` / `point.isWithin(polygon)`                                                                            |     | [Source][187] / [Tests][188] |
| boolean-crosses             | `lineString.crosses(otherLineString)`                                                                                                  |     | [Source][50] / [Tests][133]  |
| boolean-disjoint            | `let result = polygon.isDisjoint(with: lineString)`                                                                                   |     | [Source][126] / [Tests][127] |
| boolean-intersects          | `let result = polygon.intersects(with: lineString)`                                                                                   |     | [Source][128]                |
| boolean-overlap             | `lineString1.isOverlapping(with: lineString2)`                                                                                        |     | [Source][52] / [Tests][53]   |
| boolean-parallel            | `lineString1.isParallel(to: lineString2)`                                                                                             |     | [Source][54] / [Tests][55]   |
| boolean-point-in-polygon    | `polygon.contains(Coordinate3D(…))`                                                                                                   |     | [Source][56] / [Tests][134]  |
| boolean-point-on-line       | `lineString.checkIsOnLine(Coordinate3D(…))`                                                                                           |     | [Source][57] / [Tests][135]  |
| boolean-touches             | `anyGeometry.touches(other)`                                                                                                          |     | [Source][159] / [Tests][160] |
| boolean-valid               | `anyGeometry.isValid`                                                                                                                 |     | [Source][58] / [Tests][136]  |
| bbox-clip                   | `let clipped = lineString.clipped(to: boundingBox)`                                                                                   |     | [Source][59] / [Tests][60]   |
| boundary                    | `let boundary = anyGeometry.boundary`                                                                                                 |     | [Source][199] / [Tests][200] |
| buffer                      | `let buffered = lineString.buffered(by: 1000.meters)`                                                                                 |     | [Source][61] / [Tests][158]  |
| center-median               | `let median = featureCollection.centerMedian()`                                                                                       |     | [Source][62] / [Tests][137]  |
| center/centroid/center-mean | `let center = polygon.center`                                                                                                         |     | [Source][62] / [Tests][137]  |
| circle                      | `let circle = point.circle(radius: 5000.0)`                                                                                           |     | [Source][63] / [Tests][64]   |
| clean                       | `let cleaned = lineString.cleaned()`                                                                                                  |     | [Source][207] / [Tests][208] |
| clusters-dbscan             | `let result = featureCollection.dbscanClusters(maxDistance: 100.0, minPoints: 3)`                                                     |     | [Source][156] / [Tests][157] |
| clusters-kmeans             | `let result = featureCollection.kmeansClusters(numberOfClusters: 5)`                                                                  |     | [Source][156] / [Tests][157] |
| collect                     | `let result = polygons.collect(from: points, inProperty: "p", outProperty: "vals")`                                                  |     | [Source][215] / [Tests][216] |
| concave-hull                | `anyGeometry.concaveHull(maxEdgeLength: 500.0)`                                                                                     |     | [Source][161] / [Tests][162] |
| conversions/helpers         | `let distance = GISTool.convert(length: 1.0, from: .miles, to: .meters)`                                                              |     | [Source][65] / [Tests][143]  |
| convex-hull                 | `let hull = anyGeometry.convexHull()`                                                                                                   |     | [Source][146] / [Tests][147] |
| coverage-is-valid           | `let valid = multiPolygon.coverageIsValid()`                                                                                           |     | [Source][245] / [Tests][246] |
| coverage-simplify           | `let simplified = multiPolygon.coverageSimplified(tolerance: 5.0)`                                                                     |     | [Source][110] / [Tests][111] |
| coverage-union              | `let merged = multiPolygon.coverageUnion()`                                                                                            |     | [Source][245] / [Tests][246] |
| densify                     | `let dense = anyGeometry.densified(maxSegmentLength: 1.0)`                                                                             |     | [Source][233] / [Tests][234] |
| destination                 | `let destination = coordinate.destination(distance: 1000.0, bearing: 173.0)`                                                          |     | [Source][66] / [Tests][67]   |
| difference                  | `let diff = polygon.difference(with: other)`                                                                                          |     | [Source][227] / [Tests][228] |
| distance                    | `let distance = coordinate1.distance(from: coordinate2)`                                                                              |     | [Source][68] / [Tests][69]   |
| distance-along              | `let dist = lineString.distanceAlong(to: coordinate)`                                                                                 |     | [Source][213] / [Tests][214] |                                                                              |     | [Source][68] / [Tests][69]   |
| ellipse                     | `let ellipse = coordinate.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0)`                                                              |     | [Source][183] / [Tests][184] |
| flatten                     | `let featureCollection = anyGeometry.flattened`                                                                                       |     | [Source][70] / [Tests][71]   |
| flip                        | `let flipped = anyGeometry.flipped()`                                                                                                 |     | [Source][189] / [Tests][190] |
| great-circle                | `let arc = start.greatCircle(to: end)`                                                                                                |     | [Source][144] / [Tests][145] |
| frechetDistance             | `let distance = lineString.frechetDistance(from: other)`                                                                              |     | [Source][72] / [Tests][73]   |
| grid-hex                    | `bbox.hexGrid(cellSide: 1000.0)`                                                                                                      |     | [Source][165] / [Tests][166] |
| grid-point                  | `bbox.pointGrid(cellSide: 1000.0)`                                                                                                    |     | [Source][167] / [Tests][168] |
| grid-rectangle              | `bbox.rectangleGrid(cellWidth: 1000.0, cellHeight: 500.0)`                                                                            |     | [Source][173] / [Tests][174] |
| grid-square                 | `bbox.squareGrid(cellSide: 1000.0)`                                                                                                   |     | [Source][169] / [Tests][170] |
| grid-triangle               | `bbox.triangleGrid(cellSide: 1000.0)`                                                                                                 |     | [Source][171] / [Tests][172] |
| hausdorffDistance           | `let dist = a.hausdorffDistance(from: b)`                                                                                             |     | [Source][239] / [Tests][240] |
| intersect                   | `let overlap = polygon.intersection(with: other)`                                                                                     |     | [Source][225] / [Tests][226] |
| isolines                    | `let result = grid.isolines(breaks: [0, 100, 200])`                                                                   |     | [Source][219] / [Tests][220] |
| kinks                       | `let intersections = anyGeometry.kinks()`                                                                                              |     | [Source][150] / [Tests][151] |
| make-valid                  | `let valid = anyGeometry.madeValid()`                                                                                                 |     | [Source][243] / [Tests][244] |
| length                      | `let length = lineString.length`                                                                                                      |     | [Source][74] / [Tests][75]   |
| line-arc                    | `let lineArc = point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0)`                                                         |     | [Source][76] / [Tests][77]   |
| line-chunk                  | `let chunks = lineString.chunked(segmentLength: 1000.0).lineStrings` `let dividedLine = lineString.evenlyDivided(segmentLength: 1.0)` |     | [Source][78] / [Tests][79]   |
| line-offset                 | `let offset = lineString.offset(by: 50.0)`                                                                                            |     | [Source][185] / [Tests][186] |
| line-intersect              | `let intersections = feature1.intersections(other: feature2)`                                                                         |     | [Source][80] / [Tests][81]   |
| line-merge                  | `let merged = fc.lineMerged()`                                                                                                        |     | [Source][237] / [Tests][238] |
| line-overlap                | `let overlappingSegments = lineString1.overlappingSegments(with: lineString2)`                                                        |     | [Source][82] / [Tests][83]   |
| line-segments               | `let segments = anyGeometry.lineSegments`                                                                                             |     | [Source][84] / [Tests][85]   |
| line-slice                  | `let slice = lineString.slice(start: Coordinate3D(…), end: Coordinate3D(…))`                                                          |     | [Source][86] / [Tests][87]   |
| line-slice-along            | `let sliced = lineString.sliceAlong(startDistance: 50.0, stopDistance: 2000.0)`                                                       |     | [Source][88] / [Tests][89]   |
| line-split                  | `let segments = lineString.lineSplit(with: splitter)`                                                                                 |     | [Source][211] / [Tests][212] |
| mask                        | `let masked = polygon.mask()`                                                                                                         |     | [Source][209] / [Tests][210] |
| midpoint                    | `let middle = coordinate1.midpoint(to: coordinate2)`                                                                                  |     | [Source][90] / [Tests][91]   |
| minkowski-difference        | `let eroded = polygon.minkowskiDifference(with: pattern)`                                                                             |     | [Source][231] / [Tests][232] |
| minkowski-sum               | `let dilated = polygon.minkowskiSum(with: pattern)`                                                                                   |     | [Source][231] / [Tests][232] |
| minimum-bounding-circle     | `let circle = anyGeometry.minimumBoundingCircle()`                                                                                    |     | [Source][203] / [Tests][204] |
| minimum-bounding-radius     | `let r = anyGeometry.minimumBoundingRadius()`                                                                                         |     | [Source][203] / [Tests][204] |
| maximum-inscribed-circle    | `let circle = polygon.maximumInscribedCircle()` / `let r = polygon.maximumInscribedRadius()`                                          |     | [Source][241] / [Tests][242] |
| nearest-point               | `let nearest = anyGeometry.nearestCoordinate(from: Coordinate3D(…))`                                                                  |     | [Source][92] / [Tests][138]  |
| nearest-point-on-feature    | `let nearest = anyGeometry. nearestCoordinateOnFeature(from: Coordinate3D(…))`                                                        |     | [Source][93] / [Tests][139]  |
| nearest-point-on-line       | `let nearest = lineString.nearestCoordinateOnLine(from: Coordinate3D(…))?.coordinate`                                                 |     | [Source][94] / [Tests][95]   |
| nearest-point-to-line       | `let nearest = lineString. nearestCoordinate(outOf: coordinates)`                                                                     |     | [Source][96] / [Tests][140]  |
| oriented-envelope           | `let envelope = anyGeometry.orientedEnvelope()`                                                                                       |     | [Source][205] / [Tests][206] |
| planepoint                  | `let z = triangle.planepoint(point)`                                                                                                  |     | [Source][201] / [Tests][202] |
| point-on-feature            | `let coordinate = anyGeometry.coordinateOnFeature`                                                                                    |     | [Source][97] / [Tests][141]  |
| points-within-polygon       | `let within = polygon.coordinatesWithin(coordinates)`                                                                                 |     | [Source][98] / [Tests][142]  |
| point-to-line-distance      | `let distance = lineString.distanceFrom(coordinate: Coordinate3D(…))`                                                                 |     | [Source][99] / [Tests][100]  |
| pole-of-inaccessibility     | `let pole = polygon.poleOfInaccessibility()`                                                                                           |     | [Source][101] / [Tests][152] |
| polygon-smooth              | `let smoothed = polygon.smooth(iterations: 3)`                                                                                         |     | [Source][148] / [Tests][149] |
| polygon-tangents            | `let tangents = polygon.tangentPoints(to: point)`                                                                                      |     | [Source][195] / [Tests][196] |
| polygon-to-line             | `var lineStrings = polygon.lineStrings`                                                                                               |     | [Source][129]                |
| polygonize                  | `let polygons = multiLineString.polygonized()`                                                                                        |     | [Source][197] / [Tests][198] |
| polygon-hull-simplify       | `let hull = polygon.polygonHullSimplified(tolerance: 5.0)`                                                                            |     | [Source][110] / [Tests][111] |
| random                      | `BoundingBox.randomPoints(count: 10)`                                                                                                 |     | [Source][179] / [Tests][180] |
| reverse                     | `let lineStringReversed = lineString.reversed`                                                                                        |     | [Source][102] / [Tests][103] |
| rhumb-bearing               | `let bearing = start.rhumbBearing(to: end)`                                                                                           |     | [Source][104] / [Tests][105] |
| rhumb-destination           | `let destination = coordinate.rhumbDestination(distance: 1000.0, bearing: 0.0)`                                                       |     | [Source][106] / [Tests][107] |
| rhumb-distance              | `let distance = coordinate1.rhumbDistance(from: coordinate2)`                                                                         |     | [Source][108] / [Tests][109] |
| sample                      | `let sampled = featureCollection.sample(size: 10)`                                                                                    |     | [Source][181] / [Tests][182] |
| sector                      | `let sector = coordinate.sector(radius: 5000.0, bearing1: 0.0, bearing2: 90.0)`                                                       |     | [Source][189] / [Tests][190] |
| shared-paths                | `let shared = a.sharedPaths(with: b)`                                                                                                  |     | [Source][235] / [Tests][236] |
| square                      | `let squared = boundingBox.squared()`                                                                                                 |     | [Source][193] / [Tests][194] |
| symmetric-difference        | `let xor = polygon.symmetricDifference(with: other)`                                                                                  |     | [Source][229] / [Tests][230] |
| simplify                    | `let simplified = lineString.simplified(tolerance: 5.0, highQuality: false)`                                                         |     | [Source][110] / [Tests][111] |
| topology-preserve-simplify | `let valid = lineString.topologyPreservedSimplified(tolerance: 5.0)`                                                                  |     | [Source][110] / [Tests][111] |
| snap-to-grid                | `anyGeometry.snappedToGrid(tolerance: 0.5)`                                                                                           |     | [Source][175] / [Tests][176] |
| tile-cover                  | `let tileCover = anyGeometry.tileCover(atZoom: 14)`                                                                                   |     | [Source][112] / [Tests][113] |
| tin                         | `anyGeometry.tin()`                                                                                                                  |     | [Source][163] / [Tests][164] |
| tesselate                   | `let triangles = polygon.tesselated()`                                                                                               |     | [Source][221] / [Tests][222] |
| tin-to-point-cloud          | `let cloud = tin.tinToPointCloud()`                                                                                                  |     | [Source][201] / [Tests][202] |
| transform-coordinates       | `let transformed = anyGeometry.transformCoordinates({ $0 })`                                                                          |     | [Source][114] / [Tests][115] |
| transform-rotate            | `let transformed = anyGeometry. transformedRotate(angle: 25.0, pivot: Coordinate3D(…))`                                               |     | [Source][116] / [Tests][117] |
| transform-scale             | `let transformed = anyGeometry. transformedScale(factor: 2.5, anchor: .center)`                                                       |     | [Source][118] / [Tests][119] |
| transform-translate         | `let transformed = anyGeometry. transformedTranslate(distance: 1000.0, direction: 25.0)`                                              |     | [Source][120] / [Tests][121] |
| truncate                    | `let truncated = lineString.truncated(precision: 2, removeAltitude: true)`                                                            |     | [Source][122] / [Tests][123] |
| union                       | `let combined = polygon.union(with: otherPolygon)`                                                                                     |     | [Source][124] / [Tests][153] |
| unary-union                 | `let unioned = multiPolygon.unaryUnion()`                                                                                              |     | [Source][245] / [Tests][246] |
| unkink-polygon              | `let simplePolygons = polygon.unkinked(gridSize: 0.001)`                                                                              |     | [Source][150] / [Tests][151] |
| voronoi                     | `let cells = points.voronoiDiagram(boundingBox: bbox)`                                                                                |     | [Source][223] / [Tests][224] |

# Graph

The package includes a `Graph` type for routing and network analysis on GeoJSON `LineString` / `MultiLineString` features. Nodes are created at each line-segment endpoint; coordinates within a configurable `nodeTolerance` (default 1 m) are merged into a single node via a spatial-hash index, giving near O(1) deduplication during construction. The graph supports both undirected and directed (`oneway`-tagged) edges, optional edge filters for mode-restricted routing (e.g. hiking / cycling), and works across all projections (EPSG:4326, EPSG:3857, EPSG:4978, noSRID), including geometries that cross the antimeridian.

## Construction

```swift
// Build a graph from a feature collection of LineStrings / MultiLineStrings.
let graph = Graph(featureCollection: featureCollection)

// Directed graph: features with a truthy "oneway" property become one-way edges.
let directed = Graph(featureCollection: featureCollection, isDirected: true)

// Pick two nodes and route between them.
let start = graph.nodes[0]
let end = graph.nodes[graph.nodeCount - 1]
let path = graph.shortestPath(from: start, to: end)
let length = graph.length(ofPath: path)
```

Nodes can also be added manually with `createNode(at:)`, `addUndirectedEdge(from:to:)`, and `addDirectedEdge(from:to:)`.

A subset of the graph can be extracted as a standalone `Graph` via `subgraph(containing:)`, and the connected components can each be obtained as a `Graph` via `connectedComponentGraphs`:

```swift
// Extract each connected component as its own Graph.
let components = graph.connectedComponentGraphs
for component in components {
    print("\(component.nodeCount) nodes, \(component.directedEdgeCount) edges")
}

// Or extract an arbitrary subset of nodes.
let sub = graph.subgraph(containing: [nodeA, nodeB, nodeC])
```

## Merge

Multiple graphs (e.g. from tiled road networks) can be merged into one. Nodes within `nodeTolerance` are spatially deduplicated, and duplicate edges between the same node pair are removed:

```swift
// Merge an array of graphs (primary API).
let merged = Graph.merged([tile1, tile2, tile3])

// Convenience for merging a single graph into another.
let merged = graph.merged(with: anotherGraph)
```

Edges cut at tile boundaries become degree-2 chain nodes. Call `contracted()` on the merged result to collapse them into continuous edges.

## Export

A graph can be exported back to a `FeatureCollection` for debugging or for use with other GeoJSON tooling:

```swift
let fc = graph.toFeatureCollection()
// Each edge becomes a 2-point LineString feature.
// Original feature properties, id, and edge weight are preserved.
// Directed edges get a "oneway": "yes" property.
```

## Graph algorithms

| Name | Example | Source / Tests |
| ---- | ------- | -------------- |
| A* search | `graph.aStarPath(from: a, to: b)` | [Source][249] / [Tests][250] |
| Articulation points | `graph.articulationPoints()` | [Source][266] / [Tests][267] |
| BFS / DFS | `graph.breadthFirstSearch(from: node)` / `graph.depthFirstSearch(from: node)` | [Source][279] |
| BFS / DFS (callback) | `graph.breadthFirstSearch(from: node) { _ in true }` / `graph.depthFirstSearch(from: node) { _ in true }` | [Source][279] |
| Betweenness centrality | `graph.betweennessCentrality()` | [Source][268] / [Tests][269] |
| Bidirectional Dijkstra | `graph.bidirectionalShortestPath(from: a, to: b)` | [Source][251] / [Tests][252] |
| Bridge detection | `graph.bridges()` | [Source][264] / [Tests][265] |
| Chain contraction | `graph.contracted()` / `graph.contracted { $0.feature?.property(for: "type") == $1.feature?.property(for: "type") }` | [Source][257] / [Tests][258] |
| Chinese Postman tour | `graph.chinesePostmanTour()` | [Source][274] / [Tests][275] |
| Connected components | `graph.connectedComponents` | [Source][279] |
| Connected component graphs | `graph.connectedComponentGraphs` | [Source][279] |
| Contraction-accelerated routing | `graph.shortestPathViaContraction(from: a, to: b)` | [Source][257] / [Tests][259] |
| Cycle detection | `graph.cycles(from: node)` | [Source][278] |
| Dead-end pruning | `graph.prunedDeadEnds()` | [Source][260] / [Tests][261] |
| Eulerian path / circuit | `graph.eulerianPath()` | [Source][274] / [Tests][275] |
| Graph export (to FeatureCollection) | `graph.toFeatureCollection()` | [Source][283] / [Tests][284] |
| Graph merge | `Graph.merged([graph1, graph2])` | [Source][281] / [Tests][282] |
| Graph partitioning (tiling) | `graph.partition(intoGridRows: 4, columns: 4)` | [Source][262] / [Tests][263] |
| K-shortest paths (Yen) | `graph.kShortestPaths(from: a, to: b, k: 3)` | [Source][253] / [Tests][254] |
| Minimum spanning tree | `graph.minimumSpanningTree()` | [Source][272] / [Tests][273] |
| Multi-criteria shortest path | `graph.shortestPath(from: a, to: b) { $0.weight }` | [Source][255] / [Tests][256] |
| Node-on-edge splitting | `graph.nodeOnEdge(near: coordinate)` | [Source][280] |
| Roundabout detection | see `Graph+Cycles.swift` | [Source][278] |
| SCC graphs | `graph.stronglyConnectedComponentGraphs()` | [Source][270] / [Tests][271] |
| Shortest path (Dijkstra) | `graph.shortestPath(from: a, to: b)` | [Source][247] / [Tests][248] |
| Strongly connected components | `graph.stronglyConnectedComponents()` | [Source][270] / [Tests][271] |
| Subgraph extraction | `graph.subgraph(containing: [a, b, c])` | [Source][279] |
| TSP approximation | `graph.travelingSalespersonTour(nodes: [...])` | [Source][276] / [Tests][277] |

# Related packages
Currently only two:
- [mvt-tools][125]: Vector tiles reader/writer for Swift
- [mvt-postgis][130]: Creates vector tiles from Postgis databases

# Contributing
Please [create an issue](https://github.com/Outdooractive/gis-tools/issues) or [open a pull request](https://github.com/Outdooractive/gis-tools/pulls) with a fix or enhancement.

# License
MIT

# Authors
Thomas Rasch, Outdooractive

[1]:	https://swiftpackageindex.com/Outdooractive/gis-tools
[2]:	https://swiftpackageindex.com/Outdooractive/gis-tools
[3]:	https://www.rfc-editor.org/rfc/rfc7946
[4]:	https://github.com/Turfjs/turf/tree/master/packages
[5]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GISTool.swift
[6]:	https://www.rfc-editor.org/rfc/rfc7946
[8]:	https://swiftpackageindex.com/Outdooractive/gis-tools/main/documentation/gistools
[9]:	https://github.com/Outdooractive/gis-tools/tree/main/Tests/GISToolsTests/GeoJson
[10]:	https://swiftpackageindex.com/Outdooractive/gis-tools/main/documentation/gistools
[11]:	https://www.rfc-editor.org/rfc/rfc7946
[12]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/GeoJson.swift "GeoJson.swift"
[13]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/BoundingBoxRepresentable.swift
[14]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/GeoJsonConvertible.swift
[15]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/GeoJsonReader.swift
[16]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Coordinate3D.swift
[17]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/CoordinateTests.swift
[20]:	https://github.com/Outdooractive/gis-tools/tree/main/Sources/GISTools/Projections
[31]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/CustomProjection.swift
[40]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKBTests.swift
[41]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKTTests.swift
[42]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/RTreeTests.swift
[43]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Along.swift "Along"
[44]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/AlongTests.swift "AlongTests"
[45]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Area.swift "Area"
[46]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Bearing.swift "Bearing"
[47]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BearingTests.swift "BearingTests"
[48]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanClockwise.swift "BooleanClockwise"
[49]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanClockwiseTests.swift "BooleanClockwiseTests"
[50]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanCrosses.swift "BooleanCrosses"
[52]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanOverlap.swift "BooleanOverlap"
[53]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanOverlapTests.swift "BooleanOverlapTests"
[54]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanParallel.swift "BooleanParallel"
[55]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanParallelTests.swift "BooleanParallelTests"
[56]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanPointInPolygon.swift "BooleanPointInPolygon"
[57]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanPointOnLine.swift "BooleanPointOnLine"
[58]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Validatable.swift "Validatable"
[59]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BoundingBoxClip.swift "BoundingBoxClip"
[60]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BoundingBoxClipTests.swift "BoundingBoxClipTests"
[61]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Buffer.swift "Buffer"
[62]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Center.swift "Center"
[63]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Circle.swift "Circle"
[64]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/CircleTests.swift "CircleTests"
[65]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Conversions.swift "Conversions"
[66]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Destination.swift "Destination"
[67]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/DestinationTests.swift "DestinationTests"
[68]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Distance.swift "Distance"
[69]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/DistanceTests.swift "DistanceTests"
[70]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Flatten.swift "Flatten"
[71]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/FlattenTests.swift "FlattenTests"
[72]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/FrechetDistance.swift "FrechetDistance"
[73]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/FrechetDistanceTests.swift "FrechetDistanceTests"
[74]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Length.swift "Length"
[75]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LengthTests.swift "LengthTests"
[76]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineArc.swift "LineArc"
[77]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineArcTests.swift "LineArcTests"
[78]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineChunk.swift "LineChunk"
[79]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineChunkTests.swift "LineChunkTests"
[80]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineIntersection.swift "LineIntersection"
[81]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineIntersectionTests.swift "LineIntersectionTests"
[82]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineOverlap.swift "LineOverlap"
[83]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineOverlapTests.swift "LineOverlapTests"
[84]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineSegments.swift "LineSegments"
[85]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineSegmentsTests.swift "LineSegmentsTests"
[86]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineSlice.swift "LineSlice"
[87]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineSliceTests.swift "LineSliceTests"
[88]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineSliceAlong.swift "LineSliceAlong"
[89]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineSliceAlongTests.swift "LineSliceAlongTests"
[90]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/MidPoint.swift "MidPoint"
[91]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/MidPointTests.swift "MidPointTests"
[92]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/NearestPoint.swift "NearestPoint"
[93]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/NearestPointOnFeature.swift "NearestPointOnFeature"
[94]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/NearestPointOnLine.swift "NearestPointOnLine"
[95]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/NearestCoordinateOnLineTests.swift "NearestCoordinateOnLineTests"
[96]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/NearestPointToLine.swift "NearestPointToLine"
[97]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PointOnFeature.swift "PointOnFeature"
[98]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PointsWithinPolygon.swift "PointsWithinPolygon"
[99]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PointToLineDistance.swift "PointToLineDistance"
[100]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PointToLineDistanceTests.swift "PointToLineDistanceTests"
[101]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PoleOfInaccessibility.swift "PoleOfInaccessibility"
[102]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Reverse.swift "Reverse"
[103]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/ReverseTests.swift "ReverseTests"
[104]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/RhumbBearing.swift "RhumbBearing"
[105]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/RhumbBearingTests.swift "RhumbBearingTests"
[106]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/RhumbDestination.swift "RhumbDestination"
[107]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/RhumbDestinationTests.swift "RhumbDestinationTests"
[108]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/RhumbDistance.swift "RhumbDistance"
[109]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/RhumbDistanceTests.swift "RhumbDistanceTests"
[110]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Simplify.swift "Simplify"
[111]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SimplifyTests.swift "SimplifyTests"
[112]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/TileCover.swift "TileCover"
[113]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TileCoverTests.swift "TileCoverTests"
[114]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/TransformCoordinates.swift "TransformCoordinates"
[115]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TransformCoordinatesTests.swift "TransformCoordinatesTests"
[116]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/TransformRotate.swift "TransformRotate"
[117]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TransformRotateTests.swift "TransformRotateTests"
[118]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/TransformScale.swift "TransformScale"
[119]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TransformScaleTests.swift "TransformScaleTests"
[120]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/TransformTranslate.swift "TransformTranslate"
[121]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TransformTranslateTests.swift "TransformTranslateTests"
[122]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Truncate.swift "Truncate"
[123]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TruncateTests.swift "TruncateTests"
[124]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Union.swift "Union"
[125]:	https://github.com/Outdooractive/mvt-tools
[126]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanDisjoint.swift "BooleanDisjoint"
[127]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanDisjointTests.swift "BooleanDisjointTests"
[128]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanIntersects.swift "BooleanIntersects"
[129]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PolygonToLine.swift "PolygonToLine"
[130]:  https://github.com/Outdooractive/mvt-postgis
[131]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/AntimeridianCutting.swift "AntimeridianCutting"
[132]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/AntimeridianCuttingTests.swift "AntimeridianCuttingTests"
[133]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanCrossesTests.swift "BooleanCrossesTests"
[134]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanPointInPolygonTests.swift "BooleanPointInPolygonTests"
[135]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanPointOnLineTests.swift "BooleanPointOnLineTests"
[136]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/ValidatableTests.swift "ValidatableTests"
[137]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/CenterTests.swift "CenterTests"
[138]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/NearestPointTests.swift "NearestPointTests"
[139]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/NearestPointOnFeatureTests.swift "NearestPointOnFeatureTests"
[140]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/NearestPointToLineTests.swift "NearestPointToLineTests"
[141]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PointOnFeatureTests.swift "PointOnFeatureTests"
[142]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PointsWithinPolygonTests.swift "PointsWithinPolygonTests"
[143]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/ConversionTests.swift "ConversionTests"
[144]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/GreatCircle.swift "GreatCircle"
[145]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/GreatCircleTests.swift "GreatCircleTests"
[146]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/ConvexHull.swift "ConvexHull"
[147]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/ConvexHullTests.swift "ConvexHullTests"
[148]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PolygonSmooth.swift "PolygonSmooth"
[149]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PolygonSmoothTests.swift "PolygonSmoothTests"
[150]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Kinks.swift "Kinks"
[151]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/KinksTests.swift "KinksTests"
[152]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PoleOfInaccessibilityTests.swift "PoleOfInaccessibilityTests"
[153]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/UnionTests.swift "UnionTests"
[154]:	https://github.com/TWKB/Specification/blob/master/twkb.md
[155]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/TWKBTests.swift
[156]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Clusters.swift
[157]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/ClustersTests.swift
[158]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BufferTests.swift "BufferTests"
[159]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanTouches.swift "BooleanTouches"
[160]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanTouchesTests.swift "BooleanTouchesTests"
[161]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/ConcaveHull.swift "ConcaveHull"
[162]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/ConcaveHullTests.swift "ConcaveHullTests"
[163]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Tin.swift "Tin"
[164]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TinTests.swift "TinTests"
[165]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/HexGrid.swift "HexGrid"
[166]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/HexGridTests.swift "HexGridTests"
[167]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PointGrid.swift "PointGrid"
[168]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PointGridTests.swift "PointGridTests"
[169]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/SquareGrid.swift "SquareGrid"
[170]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SquareGridTests.swift "SquareGridTests"
[171]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/TriangleGrid.swift "TriangleGrid"
[172]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TriangleGridTests.swift "TriangleGridTests"
[173]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/RectangleGrid.swift "RectangleGrid"
[174]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/RectangleGridTests.swift "RectangleGridTests"
[175]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/SnapToGrid.swift "SnapToGrid"
[176]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SnapToGridTests.swift "SnapToGridTests"
[177]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanConcave.swift "BooleanConcave"
[178]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanConcaveTests.swift "BooleanConcaveTests"
[179]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Random.swift "Random"
[180]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/RandomTests.swift "RandomTests"
[181]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Sample.swift "Sample"
[182]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SampleTests.swift "SampleTests"
[183]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Ellipse.swift "Ellipse"
[184]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/EllipseTests.swift "EllipseTests"
[185]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineOffset.swift "LineOffset"
[186]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineOffsetTests.swift "LineOffsetTests"
[187]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BooleanContains.swift "BooleanContains"
[188]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BooleanContainsTests.swift "BooleanContainsTests"
[189]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Sector.swift "Sector"
[190]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SectorTests.swift "SectorTests"
[193]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/BoundingBox.swift "BoundingBox"
[194]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/BoundingBoxTests.swift "BoundingBoxTests"
[195]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/PolygonTangents.swift "PolygonTangents"
[196]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PolygonTangentsTests.swift "PolygonTangentsTests"
[197]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Polygonize.swift "Polygonize"
[198]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PolygonizeTests.swift "PolygonizeTests"
[199]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Boundary.swift "Boundary"
[200]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BoundaryTests.swift "BoundaryTests"
[201]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Planepoint.swift "Planepoint"
[202]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/PlanepointTests.swift "PlanepointTests"
[203]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/MinimumBoundingCircle.swift "MinimumBoundingCircle"
[204]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/MinimumBoundingCircleTests.swift "MinimumBoundingCircleTests"
[205]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/OrientedEnvelope.swift "OrientedEnvelope"
[206]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/OrientedEnvelopeTests.swift "OrientedEnvelopeTests"
[207]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Clean.swift "Clean"
[208]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/CleanTests.swift "CleanTests"
[209]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Mask.swift "Mask"
[210]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/MaskTests.swift "MaskTests"
[211]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineSplit.swift "LineSplit"
[212]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineSplitTests.swift "LineSplitTests"
[213]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Along.swift "Along"
[214]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineSplitTests.swift "LineSplitTests"
[215]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Collect.swift "Collect"
[216]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/CollectTests.swift "CollectTests"
[217]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/BezierSpline.swift "BezierSpline"
[218]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/BezierSplineTests.swift "BezierSplineTests"
[219]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/IsoLines.swift "IsoLines"
[220]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/IsoLinesTests.swift "IsoLinesTests"
[221]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Tesselate.swift "Tesselate"
[222]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/TesselateTests.swift "TesselateTests"
[223]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Voronoi.swift "Voronoi"
[224]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/VoronoiTests.swift "VoronoiTests"
[225]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Intersection.swift "Intersection"
[226]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/IntersectionTests.swift "IntersectionTests"
[227]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Difference.swift "Difference"
[228]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/DifferenceTests.swift "DifferenceTests"
[229]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/SymmetricDifference.swift "SymmetricDifference"
[230]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SymmetricDifferenceTests.swift "SymmetricDifferenceTests"
[231]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/MinkowskiSum.swift "MinkowskiSum"
[232]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/MinkowskiSumTests.swift "MinkowskiSumTests"
[233]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/Densify.swift "Densify"
[234]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/DensifyTests.swift "DensifyTests"
[235]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/SharedPaths.swift "SharedPaths"
[236]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/SharedPathsTests.swift "SharedPathsTests"
[237]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/LineMerge.swift "LineMerge"
[238]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/LineMergeTests.swift "LineMergeTests"
[239]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/HausdorffDistance.swift "HausdorffDistance"
[240]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/HausdorffDistanceTests.swift "HausdorffDistanceTests"
[241]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/MaximumInscribedCircle.swift "MaximumInscribedCircle"
[242]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/MaximumInscribedCircleTests.swift "MaximumInscribedCircleTests"
[243]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/MakeValid.swift "MakeValid"
[244]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/MakeValidTests.swift "MakeValidTests"
[245]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Algorithms/UnaryUnion.swift "UnaryUnion"
[246]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Algorithms/UnaryUnionTests.swift "UnaryUnionTests"
[247]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+ShortestPath.swift "Graph+ShortestPath"
[248]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/ShortestPathTests.swift "ShortestPathTests"
[249]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+AStar.swift "Graph+AStar"
[250]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/AStarTests.swift "AStarTests"
[251]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Bidirectional.swift "Graph+Bidirectional"
[252]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/BidirectionalShortestPathTests.swift "BidirectionalShortestPathTests"
[253]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+KShortestPaths.swift "Graph+KShortestPaths"
[254]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/KShortestPathsTests.swift "KShortestPathsTests"
[255]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+MultiCriteriaPath.swift "Graph+MultiCriteriaPath"
[256]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/MultiCriteriaShortestPathTests.swift "MultiCriteriaShortestPathTests"
[257]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Contraction.swift "Graph+Contraction"
[258]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/ContractionTests.swift "ContractionTests"
[259]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/ContractionRoutingTests.swift "ContractionRoutingTests"
[260]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+DeadEnds.swift "Graph+DeadEnds"
[261]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/DeadEndPruningTests.swift "DeadEndPruningTests"
[262]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Partitioning.swift "Graph+Partitioning"
[263]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/PartitioningTests.swift "PartitioningTests"
[264]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Bridges.swift "Graph+Bridges"
[265]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/BridgeDetectionTests.swift "BridgeDetectionTests"
[266]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+ArticulationPoints.swift "Graph+ArticulationPoints"
[267]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/ArticulationPointTests.swift "ArticulationPointTests"
[268]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+BetweennessCentrality.swift "Graph+BetweennessCentrality"
[269]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/BetweennessCentralityTests.swift "BetweennessCentralityTests"
[270]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+StronglyConnectedComponents.swift "Graph+StronglyConnectedComponents"
[271]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/StronglyConnectedComponentsTests.swift "StronglyConnectedComponentsTests"
[272]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+MinimumSpanningTree.swift "Graph+MinimumSpanningTree"
[273]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/MinimumSpanningTreeTests.swift "MinimumSpanningTreeTests"
[274]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Eulerian.swift "Graph+Eulerian"
[275]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/EulerianTests.swift "EulerianTests"
[276]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Tsp.swift "Graph+Tsp"
[277]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/TspTests.swift "TspTests"
[278]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Cycles.swift "Graph+Cycles"
[279]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Traversal.swift "Graph+Traversal"
[280]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+NodeOnEdge.swift "Graph+NodeOnEdge"
[281]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Merge.swift "Graph+Merge"
[282]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/GraphMergeTests.swift "GraphMergeTests"
[283]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Graph/Graph+Convenience.swift "Graph+Convenience"
[284]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Graph/GraphExportTests.swift "GraphExportTests"

[285]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Ch1903PlusLv95Definition.swift
[286]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Ch1903Lv03Definition.swift
[287]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/IrishGridTM65Definition.swift
[288]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/IrishGridTM75Definition.swift
[289]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/IrishTransverseMercatorDefinition.swift

[290]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg3857Definition.swift
[291]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg4978Definition.swift
[292]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg3395Definition.swift
[293]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg32662Definition.swift
[294]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Etrs89Definition.swift
[295]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Nad27Definition.swift
[296]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Osgb1936BngDefinition.swift
[297]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Osgb1936Definition.swift
[298]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/UtmDefinition.swift
[299]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Etrs89UtmDefinition.swift
[300]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Etrs89LaeaDefinition.swift
[301]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Etrs89LccDefinition.swift
[302]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Lambert93Definition.swift
[303]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/RdNewDefinition.swift
[304]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/DhdnGkDefinition.swift
[305]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/MgiGkDefinition.swift
[306]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Nad83Definition.swift
[307]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Nad83UtmDefinition.swift
[308]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg5070Definition.swift
[309]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg3005Definition.swift
[310]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg3347Definition.swift
[311]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Projections/Definitions/Epsg3978Definition.swift

[#248]:	https://github.com/Outdooractive/gis-tools/issues/248

[image-1]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dswift-versions
[image-2]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dplatforms

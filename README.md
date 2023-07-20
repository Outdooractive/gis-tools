[![][image-1]][1]
[![][image-2]][2]

# GISTools
GIS tools for Swift, including a [GeoJSON][3] implementation and many algorithms ported from [https://turfjs.org][4].

## Notes

This package makes some assumptions about what is equal, i.e. coordinates that are inside of `1e-10` degrees are regarded as equal. See [GISTool.equalityDelta][5].

## Requirements

This package requires Swift 5.7 or higher (at least Xcode 13), and compiles on iOS (\>= iOS 13), macOS (\>= macOS 10.15), tvOS (\>= tvOS 13), watchOS (\>= watchOS 6) as well as Linux.

## Installation with Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools", from: "0.7.0"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "GISTools", package: "gis-tools"),
    ]),
]
```

## Features

- Supports the full [GeoJSON standard][6], with some exceptions (see [TODO.md][7])
- Load and write GeoJSON objects from and to `[String:Any]`, `URL`, `Data` and `String`
- Supports `Codable`
- Supports EPSG:3857 (web mercator) and EPSG:4326 (geodetic) conversions
- Supports WKT/WKB, also with different projections
- Spatial search with a R-tree
- Includes many spatial algorithms, and more to come
- Has a helper for working with x/y/z map tiles

Please see also the [API documentation][8].

## Usage
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
```
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

Example:
```swift
let json: [String: Any] = [
    "type": "Point",
    "coordinates": [100.0, 0.0],
    "other": "something",
]
let geoJson = GeoJsonReader.geoJsonFrom(json: json)!
print("Type is \(geoJson.type.rawValue)")
print("Foreign members: \(geoJson.foreignMembers)")

case geoJson {
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
/// - Important: `asJson` will output `m` only if the coordinate also has an `altitude`.
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

## BoundingBox
[Implementation][18] / [BoundingBox test cases][19]

Each GeoJSON object can have a rectangular BoundingBox (see `BoundingBoxRepresentable` above):
```swift
/// The bounding box's `projection`.
let projection: Projection

/// The bounding boxes south-west (bottom-left) coordinate.
var southWest: Coordinate3D
/// The bounding boxes north-east (upper-right) coordinate.
var northEast: Coordinate3D

/// Create a bounding box with a `southWest` and `northEast` coordinate.
init(southWest: Coordinate3D, northEast: Coordinate3D)

/// Create a bounding box from `coordinates` and an optional padding in kilometers.
init?(coordinates: [Coordinate3D], paddingKilometers: Double = 0.0)

/// Create a bounding box from other bounding boxes.
init?(boundingBoxes: [BoundingBox])

/// Reproject this bounding box.
func projected(to newProjection: Projection) -> BoundingBox
```

Example:
```swift
let point = Point(Coordinat3D(latitude: 47.56, longitude: 10.22), calculateBoundingBox: true)
print(point.boundingBox!)
```

## Point
[Implementation][20] / [Point test cases][21]

A `Point` is a wrapper around a single coordinate:
```swift
/// The receiver's coordinate.
let coordinate: Coordinate3D

/// Initialize a Point with a coordinate.
init(_ coordinate: Coordinate3D, calculateBoundingBox: Bool = false)

/// Reproject the Point.
func projected(to newProjection: Projection) -> Point
```

Example:
```swift
let point = Point(Coordinate3D(latitude: 47.56, longitude: 10.22))
```

## MultiPoint
[Implementation][22] / [MultiPoint test cases][23]

A `MultiPoint` is an array of coordinates:
```swift
/// The receiver's coordinates.
let coordinates: [Coordinate3D]

/// The receiver’s coordinates converted to Points.
var points: [Point]

/// Try to initialize a MultiPoint with some coordinates.
init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false)

/// Try to initialize a MultiPoint with some Points.
init?(_ points: [Point], calculateBoundingBox: Bool = false)

/// Reproject the MultiPoint.
func projected(to newProjection: Projection) -> MultiPoint
```

Example:
```swift
let multiPoint = MultiPoint([
    Coordinate3D(latitude: 0.0, longitude: 100.0),
    Coordinate3D(latitude: 1.0, longitude: 101.0)
])!
```

## LineString
[Implementation][24] / [LineString test cases][25]

`LineString` is an array of two or more coordinates that form a line:
```swift
/// The LineString's coordinates.
let coordinates: [Coordinate3D]

/// Try to initialize a LineString with some coordinates.
init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false)

/// Initialize a LineString with a LineSegment.
init(_ lineSegment: LineSegment, calculateBoundingBox: Bool = false)

/// Try to initialize a LineString with some LineSegments.
init?(_ lineSegments: [LineSegment], calculateBoundingBox: Bool = false)

/// Reproject the LineString.
func projected(to newProjection: Projection) -> LineString
```

Example:
```swift
let lineString = LineString([
    Coordinate3D(latitude: 0.0, longitude: 100.0),
    Coordinate3D(latitude: 1.0, longitude: 101.0)
])!

let segment = LineSegment(
    first: Coordinate3D(latitude: 0.0, longitude: 100.0),
    second: Coordinate3D(latitude: 1.0, longitude: 101.0))
let lineString = LineString(lineSegment)
```

## MultiLineString
[Implementation][26] / [MultiLineString test cases][27]

A `MultiLineString` is array of `LineString`s:
```swift
/// The MultiLineString's coordinates.
let coordinates: [[Coordinate3D]]

/// The receiver’s coordinates converted to LineStrings.
var lineStrings: [LineString]

/// Try to initialize a MultiLineString with some coordinates.
init?(_ coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false)

/// Try to initialize a MultiLineString with some LineStrings.
init?(_ lineStrings: [LineString], calculateBoundingBox: Bool = false)

/// Try to initialize a MultiLineString with some LineSegments. Each LineSegment will result in one LineString.
init?(_ lineSegments: [LineSegment], calculateBoundingBox: Bool = false)

/// Reproject the MultiLineString.
func projected(to newProjection: Projection) -> MultiLineString
```

Example:
```swift
let multiLineString = MultiLineString([
    [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)],
    [Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 3.0, longitude: 103.0)],
])!
```

## Polygon
[Implementation][28] / [Polygon test cases][29]

A `Polygon` is a shape consisting of one or more rings, where the first ring is the outer ring bounding the surface, and the inner rings bound holes within the surface. Please see [section 3.1.6][30] in the RFC for more information.
```swift
/// The receiver's coordinates.
let coordinates: [[Coordinate3D]]

/// The receiver's outer ring.
var outerRing: Ring?

/// All of the receiver's inner rings.
var innerRings: [Ring]?

/// All of the receiver's rings (outer + inner).
var rings: [Ring]

/// Try to initialize a Polygon with some coordinates.
init?(_ coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false)

/// Try to initialize a Polygon with some Rings.
init?(_ rings: [Ring], calculateBoundingBox: Bool = false)

/// Reproject the Polygon.
func projected(to newProjection: Projection) -> Polygon
```

Example:
```swift
let polygonWithHole = Polygon([
    [
        Coordinate3D(latitude: 0.0, longitude: 100.0),
        Coordinate3D(latitude: 0.0, longitude: 101.0),
        Coordinate3D(latitude: 1.0, longitude: 101.0),
        Coordinate3D(latitude: 1.0, longitude: 100.0),
        Coordinate3D(latitude: 0.0, longitude: 100.0)
    ],
    [
        Coordinate3D(latitude: 1.0, longitude: 100.8),
        Coordinate3D(latitude: 0.0, longitude: 100.8),
        Coordinate3D(latitude: 0.0, longitude: 100.2),
        Coordinate3D(latitude: 1.0, longitude: 100.2),
        Coordinate3D(latitude: 1.0, longitude: 100.8)
    ],
])!
print(polygonWithHole.area)
```

## MultiPolygon
[Implementation][31] / [MultiPolygon test cases][32]

A `MultiPolygon` is an array of `Polygon`s:
```swift
/// The receiver's coordinates.
let coordinates: [[[Coordinate3D]]]

/// The receiver’s coordinates converted to Polygons.
var polygons: [Polygon]

/// Try to initialize a MultiPolygon with some coordinates.
init?(_ coordinates: [[[Coordinate3D]]], calculateBoundingBox: Bool = false)

/// Try to initialize a MultiPolygon with some Polygons.
init?(_ polygons: [Polygon], calculateBoundingBox: Bool = false)

/// Reproject the MultiPolygon.
func projected(to newProjection: Projection) -> MultiPolygon
```

Example:
```swift
let multiPolygon = MultiPolygon([
    [
        [
            Coordinate3D(latitude: 2.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 102.0),
        ]
    ],
    [
        [
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0),
        ],
        [
            Coordinate3D(latitude: 0.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.8),
            Coordinate3D(latitude: 0.0, longitude: 100.8),
            Coordinate3D(latitude: 0.0, longitude: 100.2),
        ]
    ]
])!
```

## GeometryCollection
[Implementation][33] / [GeometryCollection test cases][34]

A `GeometryCollection` is an array of GeoJSON geometries, i.e. `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`, `MultiPolygon` or even `GeometryCollection`, though the latter is not recommended. Please see [section 3.1.8][35] in the RFC for more information.
```swift
/// The GeometryCollection's geometry objects.
let geometries: [GeoJsonGeometry]

/// Initialize a GeometryCollection with a geometry object.
init(_ geometry: GeoJsonGeometry, calculateBoundingBox: Bool = false)

/// Initialize a GeometryCollection with some geometry objects.
init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false)

/// Reproject the GeometryCollection.
func projected(to newProjection: Projection) -> GeometryCollection
```

## Feature
[Implementation][36] / [Feature test cases][37]

A `Feature` is sort of a container for exactly one GeoJSON geometry (`Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`, `MultiPolygon`, `GeometryCollection`) together with some `properties` and an optional `id`:
```swift
/// A GeoJSON identifier that can either be a string or number.
enum Identifier: Equatable, Hashable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
}

/// An arbitrary identifier.
var id: Identifier?

/// The `Feature`s geometry object.
let geometry: GeoJsonGeometry

/// Only 'Feature' objects may have properties.
var properties: [String: Any]

/// Create a ``Feature`` from any ``GeoJsonGeometry`` object.
init(_ geometry: GeoJsonGeometry,
     id: Identifier? = nil,
     properties: [String: Any] = [:],
     calculateBoundingBox: Bool = false)

/// Reproject the Feature.
func projected(to newProjection: Projection) -> Feature
```

## FeatureCollection
[Implementation][38] / [FeatureCollection test cases][39]

A `FeatureCollection` is an array of `Feature` objects:
```swift
/// The FeatureCollection's Feature objects.
private(set) var features: [Feature]

/// Initialize a FeatureCollection with one Feature.
init(_ feature: Feature, calculateBoundingBox: Bool = false)

/// Initialize a FeatureCollection with some geometry objects.
init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false)

/// Normalize any GeoJSON object into a FeatureCollection.
init?(_ geoJson: GeoJson?, calculateBoundingBox: Bool = false)

/// Reproject the FeatureCollection.
func projected(to newProjection: Projection) -> FeatureCollection
```

This type is somewhat special since its initializers will accept any valid GeoJSON object and return a `FeatureCollection` with the input wrapped in `Feature` objects if the input are geometries, or by collecting the input if it’s a `Feature`.

# WKB/WKT
The following geometry types are supported: `point`, `linestring`, `linearring`, `polygon`, `multipoint`, `multilinestring`, `multipolygon`, `geometrycollection` and `triangle`. Please open an issue if you need more.

Every GeoJSON object has convenience methods to encode and decode themselves to and from WKB/WKT, and there are extensions for `Data` and `String` to decode from WKB and WKT to GeoJSON. In the end, they all forward to `WKBCoder` and `WKTCoder` which do the heavy lifting.

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
let center = tile1.centerCoordinate
let boundingBox = tile1.boundingBox(projection: .epsg4326)

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

# Algorithms

| Name                        | Example                                                                                  |     | Source/Tests                 |
| --------------------------- | ---------------------------------------------------------------------------------------- | --- | ---------------------------- |
| along                       | `let coordinate = lineString.coordinateAlong(distance: 100.0)`                           |     | [Source][43] / [Tests][44]   |
| area                        | `Polygon(…).area`                                                                        |     | [Source][45]                 |
| bearing                     | `Coordinate3D(…).bearing(to: Coordinate3D(…))`                                           |     | [Source][46] / [Tests][47]   |
| boolean-clockwise           | `Polygon(…).outerRing?.isClockwise`                                                      |     | [Source][48] / [Tests][49]   |
| boolean-crosses             | TODO                                                                                     |     | [Source][50]                 |
| boolean-intersects          | TODO                                                                                     |     | [Source][51]                 |
| boolean-overlap             | `lineString1.isOverlapping(with: lineString2)`                                           |     | [Source][52] / [Tests][53]   |
| boolean-parallel            | `lineString1.isParallel(to: lineString2)`                                                |     | [Source][54] / [Tests][55]   |
| boolean-point-in-polygon    | `polygon.contains(Coordinate3D(…))`                                                      |     | [Source][56]                 |
| boolean-point-on-line       | `lineString.checkIsOnLine(Coordinate3D(…))`                                              |     | [Source][57]                 |
| boolean-valid               | `anyGeometry.isValid`                                                                    |     | [Source][58]                 |
| bbox-clip                   | `let clipped = lineString.clipped(to: boundingBox)`                                      |     | [Source][59] / [Tests][60]   |
| buffer                      | TODO                                                                                     |     | [Source][61]                 |
| center/centroid/center-mean | `let center = polygon.center`                                                            |     | [Source][62]                 |
| circle                      | `let circle = point.circle(radius: 5000.0)`                                              |     | [Source][63] / [Tests][64]   |
| conversions/helpers         | `let distance = GISTool.convert(length: 1.0, from: .miles, to: .meters)`                 |     | [Source][65]                 |
| destination                 | `let destination = coordinate.destination(distance: 1000.0, bearing: 173.0)`             |     | [Source][66] / [Tests][67]   |
| distance                    | `let distance = coordinate1.distance(from: coordinate2)`                                 |     | [Source][68] / [Tests][69]   |
| flatten                     | `let featureCollection = anyGeometry.flattened`                                          |     | [Source][70] / [Tests][71]   |
| length                      | `let length = lineString.length`                                                         |     | [Source][72] / [Tests][73]   |
| line-arc                    | `let lineArc = point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0)`            |     | [Source][74] / [Tests][75]   |
| line-chunk                  | `let chunks = lineString.chunked(segmentLength: 1000.0).lineStrings`                     |     | [Source][76] / [Tests][77]   |
| line-intersect              | `let intersections = feature1.intersections(other: feature2)`                            |     | [Source][78] / [Tests][79]   |
| line-overlap                | `let overlappingSegments = lineString1.overlappingSegments(with: lineString2)`           |     | [Source][80] / [Tests][81]   |
| line-segments               | `let segments = anyGeometry.lineSegments`                                                |     | [Source][82] / [Tests][83]   |
| line-slice                  | `let slice = lineString.slice(start: Coordinate3D(…), end: Coordinate3D(…))`             |     | [Source][84] / [Tests][85]   |
| line-slice-along            | `let sliced = lineString.sliceAlong(startDistance: 50.0, stopDistance: 2000.0)`          |     | [Source][86] / [Tests][87]   |
| midpoint                    | `let middle = coordinate1.midpoint(to: coordinate2)`                                     |     | [Source][88] / [Tests][89]   |
| nearest-point               | `let nearest = anyGeometry.nearestCoordinate(from: Coordinate3D(…))`                     |     | [Source][90]                 |
| nearest-point-on-feature    | `let nearest = anyGeometry. nearestCoordinateOnFeature(from: Coordinate3D(…))`           |     | [Source][91]                 |
| nearest-point-on-line       | `let nearest = lineString.nearestCoordinateOnLine(from: Coordinate3D(…))?.coordinate`    |     | [Source][92] / [Tests][93]   |
| nearest-point-to-line       | `let nearest = lineString. nearestCoordinate(outOf: coordinates)`                        |     | [Source][94]                 |
| point-on-feature            | `let coordinate = anyGeometry.coordinateOnFeature`                                       |     | [Source][95]                 |
| points-within-polygon       | `let within = polygon.coordinatesWithin(coordinates)`                                    |     | [Source][96]                 |
| point-to-line-distance      | `let distance = lineString.distanceFrom(coordinate: Coordinate3D(…))`                    |     | [Source][97] / [Tests][98]   |
| pole-of-inaccessibility     | TODO                                                                                     |     | [Source][99]                 |
| reverse                     | `let lineStringReversed = lineString.reversed`                                           |     | [Source][100] / [Tests][101] |
| rhumb-bearing               | `let bearing = start.rhumbBearing(to: end)`                                              |     | [Source][102] / [Tests][103] |
| rhumb-destination           | `let destination = coordinate.rhumbDestination(distance: 1000.0, bearing: 0.0)`          |     | [Source][104] / [Tests][105] |
| rhumb-distance              | `let distance = coordinate1.rhumbDistance(from: coordinate2)`                            |     | [Source][106] / [Tests][107] |
| simplify                    | `let simplified = lineString. simplified(tolerance: 5.0, highQuality: false)`            |     | [Source][108] / [Tests][109] |
| transform-coordinates       | `let transformed = anyGeometry.transformCoordinates({ $0 })`                             |     | [Source][110] / [Tests][111] |
| transform-rotate            | `let transformed = anyGeometry. transformedRotate(angle: 25.0, pivot: Coordinate3D(…))`  |     | [Source][112] / [Tests][113] |
| transform-scale             | `let transformed = anyGeometry. transformedScale(factor: 2.5, anchor: .center)`          |     | [Source][114] / [Tests][115] |
| transform-translate         | `let transformed = anyGeometry. transformedTranslate(distance: 1000.0, direction: 25.0)` |     | [Source][116] / [Tests][117] |
| truncate                    | `let truncated = lineString.truncated(precision: 2, removeAltitude: true)`               |     | [Source][118] / [Tests][119] |
| union                       | TODO                                                                                     |     | [Source][120]                |

# Related packages
Currently only one:
- [mvt-tools][121]: Vector tiles reader/writer for Swift

# Contributing
Please create an issue or open a pull request with a fix or enhancement.

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
[7]:	https://github.com/Outdooractive/gis-tools/blob/main/TODO.md
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
[18]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/BoundingBox.swift
[19]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/BoundingBoxTests.swift
[20]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Point.swift
[21]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/PointTests.swift
[22]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/MultiPoint.swift
[23]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiPointTests.swift
[24]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/LineString.swift
[25]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/LineStringTests.swift
[26]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/MultiLineString.swift
[27]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiLineStringTests.swift
[28]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Polygon.swift
[29]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/PolygonTests.swift
[30]:	https://www.rfc-editor.org/rfc/rfc7946#section-3.1.6 "3.1.6"
[31]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/MultiPolygon.swift
[32]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiPolygonTests.swift
[33]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/GeometryCollection.swift
[34]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/GeometryCollectionTests.swift
[35]:	https://www.rfc-editor.org/rfc/rfc7946#section-3.1.8 "3.1.8"
[36]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Feature.swift
[37]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/FeatureTests.swift
[38]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/FeatureCollection.swift
[39]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/FeatureCollectionTests.swift
[40]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKBTests.swift
[41]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKTTests.swift
[42]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/RTreeTests.swift
[43]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Along.swift
[44]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/AlongTests.swift "AlongTests.swift"
[45]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Area.swift
[46]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Bearing.swift
[47]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BearingTests.swift "BearingTests.swift"
[48]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanClockwise.swift
[49]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanClockwiseTests.swift "BooleanClockwiseTests.swift"
[50]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanCrosses.swift
[51]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanIntersects.swift
[52]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanOverlap.swift
[53]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanOverlapTests.swift "BooleanOverlapTests.swift"
[54]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanParallel.swift
[55]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanParallelTests.swift "BooleanParallelTests.swift"
[56]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanPointInPolygon.swift
[57]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanPointOnLine.swift
[58]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Validatable.swift "Validatable.swift"
[59]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BoundingBoxClip.swift
[60]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BoundingBoxClipTests.swift "BoundingBoxClipTests.swift"
[61]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Buffer.swift
[62]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Center.swift
[63]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Circle.swift
[64]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/CircleTests.swift "CircleTests.swift"
[65]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Conversions.swift
[66]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Destination.swift
[67]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/DestinationTests.swift "DestinationTests.swift"
[68]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Distance.swift
[69]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/DistanceTests.swift "DistanceTests.swift"
[70]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Flatten.swift
[71]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/FlattenTests.swift "FlattenTests.swift"
[72]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Length.swift
[73]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LengthTests.swift "LengthTests.swift"
[74]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineArc.swift
[75]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineArcTests.swift "LineArcTests.swift"
[76]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineChunk.swift
[77]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineChunkTests.swift "LineChunkTests.swift"
[78]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineIntersect.swift
[79]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineIntersectionTests.swift "LineIntersectionTests.swift"
[80]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineOverlap.swift
[81]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineOverlapTests.swift "LineOverlapTests.swift"
[82]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSegments.swift
[83]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineSegmentsTests.swift "LineSegmentsTests.swift"
[84]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSlice.swift
[85]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineSliceTests.swift "LineSliceTests.swift"
[86]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSliceAlong.swift
[87]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineSliceAlongTests.swift "LineSliceAlongTests.swift"
[88]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/MidPoint.swift
[89]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/MidPointTests.swift "MidPointTests.swift"
[90]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPoint.swift
[91]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPointOnFeature.swift
[92]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPointOnLine.swift
[93]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/NearestCoordinateOnLineTests.swift "NearestCoordinateOnLineTests.swift"
[94]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPointToLine.swift "NearestPointToLine.swift"
[95]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PointOnFeature.swift "PointOnFeature.swift"
[96]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PointsWithinPolygon.swift "PointsWithinPolygon.swift"
[97]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PointToLineDistance.swift "PointToLineDistance.swift"
[98]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/PointToLineDistanceTests.swift "PointToLineDistanceTests.swift"
[99]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PoleOfInaccessibility.swift "PoleOfInaccessibility.swift"
[100]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Reverse.swift "Reverse.swift"
[101]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/ReverseTests.swift "ReverseTests.swift"
[102]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbBearing.swift "RhumbBearing.swift"
[103]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbBearingTests.swift "RhumbBearingTests.swift"
[104]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbDestination.swift "RhumbDestination.swift"
[105]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbDestinationTests.swift "RhumbDestinationTests.swift"
[106]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbDistance.swift "RhumbDistance.swift"
[107]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbDistanceTests.swift "RhumbDistanceTests.swift"
[108]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Simplify.swift "Simplify.swift"
[109]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/SimplifyTests.swift "SimplifyTests.swift"
[110]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformCoordinates.swift "TransformCoordinates.swift"
[111]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TransformCoordinatesTests.swift "TransformCoordinatesTests.swift"
[112]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformRotate.swift "TransformRotate.swift"
[113]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TransformRotateTests.swift "TransformRotateTests.swift"
[114]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformScale.swift "TransformScale.swift"
[115]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TransformScaleTests.swift "TransformScaleTests.swift"
[116]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformTranslate.swift "TransformTranslate.swift"
[117]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TransformTranslateTests.swift "TransformTranslateTests.swift"
[118]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Truncate.swift "Truncate.swift"
[119]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TruncateTests.swift "TruncateTests.swift"
[120]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Union.swift
[121]:	https://github.com/Outdooractive/mvt-tools

[image-1]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dswift-versions
[image-2]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dplatforms
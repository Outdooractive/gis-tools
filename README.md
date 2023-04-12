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
    .package(url: "https://github.com/Outdooractive/gis-tools", from: "0.5.2"),
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
- Supports WKT/WKB
- Spatial search with a R-tree
- Supports EPSG:3857 (web mercator) and EPSG:4326 (geodetic) conversions
- Includes many spatial algorithms, and more to come

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

## Coordinate3D
[Implementation][16] / [Coordinate test cases][17]

Coordinates are the most basic building block in this package. Every object and algorithm builds on them:
```swift
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

/// Create a coordinate with `latitude`, `longitude`, `altitude` and `m`.
init(latitude: CLLocationDegrees,
     longitude: CLLocationDegrees,
     altitude: CLLocationDistance? = nil,
     m: Double? = nil)
```

Example:
```swift
let coordinate = Coordinate3D(latitude: 0.0, longitude: 0.0)
print(coordinate.isZero)
```

## CoordinateXY
[Implementation][18] / [Coordinate test cases][19]

These coordinates are mainly used for WKB/WKT when reading EPSG:3857 data:
```swift
/// The coordinates easting.
var x: Double
/// The coordinates northing.
var y: Double
/// The coordinates altitude.
var z: Double?

/// Linear referencing or whatever you want it to use for.
var m: Double?

/// Creates a coordinate with `x`, `y`, `altitude` and `m`.
init(x: Double,
     y: Double,
     z: Double? = nil,
     m: Double? = nil)

var projectedToEpsg4326: Coordinate3D
```

Example:
```swift
let coordinate = CoordinateXY(x: 10.0, y: 15.0)
print(coordinate.projectedToEpsg4326)
```

## BoundingBox
[Implementation][20] / [BoundingBox test cases][21]

Each GeoJSON object can have a rectangular BoundingBox (see `BoundingBoxRepresentable` above):
```swift
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
```

Example:
```swift
let point = Point(Coordinat3D(latitude: 47.56, longitude: 10.22), calculateBoundingBox: true)
print(point.boundingBox!)
```

## Point
[Implementation][22] / [Point test cases][23]

A `Point` is a wrapper around a single coordinate:
```swift
/// The receiver's coordinate.
let coordinate: Coordinate3D

/// Initialize a Point with a coordinate.
init(_ coordinate: Coordinate3D, calculateBoundingBox: Bool = false)
```

Example:
```swift
let point = Point(Coordinate3D(latitude: 47.56, longitude: 10.22))
```

## MultiPoint
[Implementation][24] / [MultiPoint test cases][25]

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
```

Example:
```swift
let multiPoint = MultiPoint([
    Coordinate3D(latitude: 0.0, longitude: 100.0),
    Coordinate3D(latitude: 1.0, longitude: 101.0)
])!
```

## LineString
[Implementation][26] / [LineString test cases][27]

`LineString` is an array of two or more coordinates that form a line:
```swift
/// The LineString's coordinates.
let coordinates: [Coordinate3D]

/// Try to initialize a LineString with some coordinates.
init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false)

/// Initialize a LineString with a LineSegment.
init(_ lineSegment: LineSegment, calculateBoundingBox: Bool = false)
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
[Implementation][28] / [MultiLineString test cases][29]

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

/// Try to initialize a MultiLineString with some LineSegments.
init?(_ lineSegments: [LineSegment], calculateBoundingBox: Bool = false)
```

Example:
```swift
let multiLineString = MultiLineString([
    [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)],
    [Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 3.0, longitude: 103.0)],
])!
```

## Polygon
[Implementation][30] / [Polygon test cases][31]

A `Polygon` is a shape consisting of one or more rings, where the first ring is the outer ring bounding the surface, and the inner rings bound holes within the surface. Please see [chapter 3.1.6][32] in the RFC for more information.
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
```

Example:
```swift
let polygonWithHoles = Polygon([
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
print(polygonWithHoles.area)
```

## MultiPolygon
[Implementation][33] / [MultiPolygon test cases][34]

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
[Implementation][35] / [GeometryCollection test cases][36]

A `GeometryCollection` is an array of GeoJSON geometries, i.e. `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`, `MultiPolygon` or even `GeometryCollection`, though the latter is not recommended. Please see [chapter 3.1.8][37] in the RFC for more information.
```swift
/// The GeometryCollection's geometry objects.
let geometries: [GeoJsonGeometry]

/// Initialize a GeometryCollection with a geometry object.
init(_ geometry: GeoJsonGeometry, calculateBoundingBox: Bool = false)

/// Initialize a GeometryCollection with some geometry objects.
init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false)
```

## Feature
[Implementation][38] / [Feature test cases][39]

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
```

## FeatureCollection
[Implementation][40] / [FeatureCollection test cases][41]

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
```

This type is somewhat special since its initializers will accept any valid GeoJSON object and return a `FeatureCollection` with the input wrapped in `Feature` objects if the input are geometries, or by collecting the input if it’s a `Feature`.

# WKB/WKT
The following geometry types are supported: `point`, `linestring`, `linearring`, `polygon`, `multipoint`, `multilinestring`, `multipolygon`, `geometrycollection` and `triangle`. Please open an issue if you need more.

Every GeoJSON object has convenience methods to encode and decode themselves to and from WKB/WKT, and there are extensions for `Data` and `String` to decode from WKB and WKT to GeoJSON. In the end, they all forward to `WKBCoder` and `WKTCoder` which do the heavy lifting.

## WKB
Also have a look at  the tests: [WKB test cases][42]

Decoding:
```swift
// SELECT 'POINT Z (1 2 3)'::geometry;
private let pointZData = Data(hex: "0101000080000000000000F03F00000000000000400000000000000840")!

// Generic
let point = try WKBCoder.decode(wkb: pointData, projection: .epsg4326) as! Point
let point = pointZData.asGeoJsonGeometry(projection: .epsg4326) as! Point

// Or create the geometry directly
let point = Point(wkb: pointZData, projection: .epsg4326)!

// Or create a Feature that contains the geometry
let feature = Feature(wkb: pointZData, projection: .epsg4326)
let feature = pointZData.asFeature(projection: .epsg4326)

// Or create a FeatureCollection that contains a feature with the geometry
let featureCollection = FeatureCollection(wkb: pointZData, projection: .epsg4326)
let featureCollection = pointZData.asFeatureCollection(projection: .epsg4326)
```

Encoding:
```swift
let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

// Generic
let encodedPoint = WKBCoder.encode(geometry: point, projection: nil)

// Convenience
let encodedPoint = point.asWKB
```

## WKT
This is exactly the same as WKB… Also have a look at the tests to see how it works: [WKT test cases][43]

Decoding:
```swift
private let pointZString = "POINT Z (1 2 3)"

// Generic
let point = try WKTCoder.decode(wkt: pointZString, projection: .epsg4326) as! Point
let point = pointZString.asGeoJsonGeometry(projection: .epsg4326) as! Point

// Or create the geometry directly
let point = Point(wkt: pointZString, projection: .epsg4326)!

// Or create a Feature that contains the geometry
let feature = Feature(wkt: pointZString, projection: .epsg4326)
let feature = pointZString.asFeature(projection: .epsg4326)

// Or create a FeatureCollection that contains a feature with the geometry
let featureCollection = FeatureCollection(wkt: pointZString, projection: .epsg4326)
let featureCollection = pointZString.asFeatureCollection(projection: .epsg4326)
```

Encoding:
```swift
let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

// Generic
let encodedPoint = WKTCoder.encode(geometry: point, projection: nil)

// Convenience
let encodedPoint = point.asWKT
```

# Spatial index
This package includes a simple R-tree implementation: [RTree test cases][44]

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

# Algorithms

| Name                        | Examples                                                                                 | Source/Tests                 |
| --------------------------- | ---------------------------------------------------------------------------------------- | ---------------------------- |
| along                       | `let coordinate = lineString.coordinateAlong(distance: 100.0)`                           | [Source][45] / [Tests][46]   |
| area                        | `Polygon(…).area`                                                                        | [Source][47]                 |
| bearing                     | `Coordinate3D(…).bearing(to: Coordinate3D(…))`                                           | [Source][48] / [Tests][49]   |
| boolean-clockwise           | `Polygon(…).outerRing?.isClockwise`                                                      | [Source][50] / [Tests][51]   |
| boolean-crosses             | TODO                                                                                     | [Source][52]                 |
| boolean-intersects          | TODO                                                                                     | [Source][53]                 |
| boolean-overlap             | `lineString1.isOverlapping(with: lineString2)`                                           | [Source][54] / [Tests][55]   |
| boolean-parallel            | `lineString1.isParallel(to: lineString2)`                                                | [Source][56] / [Tests][57]   |
| boolean-point-in-polygon    | `polygon.contains(Coordinate3D(…))`                                                      | [Source][58]                 |
| boolean-point-on-line       | `lineString.checkIsOnLine(Coordinate3D(…))`                                              | [Source][59]                 |
| boolean-valid               | `anyGeometry.isValid`                                                                    | [Source][60]                 |
| bbox-clip                   | `let clipped = lineString.clipped(to: boundingBox)`                                      | [Source][61] / [Tests][62]   |
| buffer                      | TODO                                                                                     | [Source][63]                 |
| center/centroid/center-mean | `let center = polygon.center`                                                            | [Source][64]                 |
| circle                      | `let circle = point.circle(radius: 5000.0)`                                              | [Source][65] / [Tests][66]   |
| conversions/helpers         | `let distance = GISTool.convert(length: 1.0, from: .miles, to: .meters)`                 | [Source][67]                 |
| destination                 | `let destination = coordinate.destination(distance: 1000.0, bearing: 173.0)`             | [Source][68] / [Tests][69]   |
| distance                    | `let distance = coordinate1.distance(from: coordinate2)`                                 | [Source][70] / [Tests][71]   |
| flatten                     | `let featureCollection = anyGeometry.flattened`                                          | [Source][72] / [Tests][73]   |
| length                      | `let length = lineString.length`                                                         | [Source][74]                 |
| line-arc                    | `let lineArc = point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0)`            | [Source][75] / [Tests][76]   |
| line-chunk                  | `let chunks = lineString.chunked(segmentLength: 1000.0).lineStrings`                     | [Source][77] / [Tests][78]   |
| line-intersect              | `let intersections = feature1.intersections(other: feature2)`                            | [Source][79] / [Tests][80]   |
| line-overlap                | `let overlappingSegments = lineString1.overlappingSegments(with: lineString2)`           | [Source][81] / [Tests][82]   |
| line-segments               | `let segments = anyGeometry.lineSegments`                                                | [Source][83]                 |
| line-slice                  | `let slice = lineString.slice(start: Coordinate3D(…), end: Coordinate3D(…))`             | [Source][84] / [Tests][85]   |
| line-slice-along            | `let sliced = lineString.sliceAlong(startDistance: 50.0, stopDistance: 2000.0)`          | [Source][86] / [Tests][87]   |
| midpoint                    | `let middle = coordinate1.midpoint(to: coordinate2)`                                     | [Source][88] / [Tests][89]   |
| nearest-point               | `let nearest = anyGeometry.nearestCoordinate(from: Coordinate3D(…))`                     | [Source][90]                 |
| nearest-point-on-feature    | `let nearest = anyGeometry. nearestCoordinateOnFeature(from: Coordinate3D(…))`           | [Source][91]                 |
| nearest-point-on-line       | `let nearest = lineString.nearestCoordinateOnLine(from: Coordinate3D(…))?.coordinate`    | [Source][92] / [Tests][93]   |
| nearest-point-to-line       | `let nearest = lineString. nearestCoordinate(outOf: coordinates)`                        | [Source][94]                 |
| point-on-feature            | `let coordinate = anyGeometry.coordinateOnFeature`                                       | [Source][95]                 |
| points-within-polygon       | `let within = polygon.coordinatesWithin(coordinates)`                                    | [Source][96]                 |
| point-to-line-distance      | `let distance = lineString.distanceFrom(coordinate: Coordinate3D(…))`                    | [Source][97] / [Tests][98]   |
| pole-of-inaccessibility     | TODO                                                                                     | [Source][99]                 |
| projection                  | `let coordinateXY = coordinate3D.projectedToEpsg3857`                                    | [Source][100] / [Tests][101] |
| reverse                     | `let lineStringReversed = lineString.reversed`                                           | [Source][102] / [Tests][103] |
| rhumb-bearing               | `let bearing = start.rhumbBearing(to: end)`                                              | [Source][104] / [Tests][105] |
| rhumb-destination           | `let destination = coordinate.rhumbDestination(distance: 1000.0, bearing: 0.0)`          | [Source][106] / [Tests][107] |
| rhumb-distance              | `let distance = coordinate1.rhumbDistance(from: coordinate2)`                            | [Source][108] / [Tests][109] |
| simplify                    | `let simplified = lineString. simplified(tolerance: 5.0, highQuality: false)`            | [Source][110] / [Tests][111] |
| transform-coordinates       | `let transformed = anyGeometry.transformCoordinates({ $0 })`                             | [Source][112]                |
| transform-rotate            | `let transformed = anyGeometry. transformedRotate(angle: 25.0, pivot: Coordinate3D(…))`  | [Source][113]                |
| transform-scale             | `let transformed = anyGeometry. transformedScale(factor: 2.5, anchor: .center)`          | [Source][114]                |
| transform-translate         | `let transformed = anyGeometry. transformedTranslate(distance: 1000.0, direction: 25.0)` | [Source][115]                |
| truncate                    | `let truncated = lineString.truncated(precision: 2, removeAltitude: true)`               | [Source][116] / [Tests][117] |

# Related packages
Currently only one:
- [mvt-tools][118]: Vector tiles reader/writer for Swift

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
[18]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/CoordinateXY.swift
[19]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/CoordinateTests.swift
[20]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/BoundingBox.swift
[21]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/BoundingBoxTests.swift
[22]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Point.swift
[23]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/PointTests.swift
[24]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/MultiPoint.swift
[25]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiPointTests.swift
[26]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/LineString.swift
[27]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/LineStringTests.swift
[28]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/MultiLineString.swift
[29]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiLineStringTests.swift
[30]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Polygon.swift
[31]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/PolygonTests.swift
[32]:	https://www.rfc-editor.org/rfc/rfc7946#section-3.1.6 "3.1.6"
[33]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/MultiPolygon.swift
[34]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiPolygonTests.swift
[35]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/GeometryCollection.swift
[36]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/GeometryCollectionTests.swift
[37]:	https://www.rfc-editor.org/rfc/rfc7946#section-3.1.8 "3.1.8"
[38]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/Feature.swift
[39]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/FeatureTests.swift
[40]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/GeoJson/FeatureCollection.swift
[41]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/FeatureCollectionTests.swift
[42]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKBTests.swift
[43]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKTTests.swift
[44]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/RTreeTests.swift
[45]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Along.swift
[46]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/AlongTests.swift "AlongTests.swift"
[47]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Area.swift
[48]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Bearing.swift
[49]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BearingTests.swift "BearingTests.swift"
[50]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanClockwise.swift
[51]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanClockwiseTests.swift "BooleanClockwiseTests.swift"
[52]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanCrosses.swift
[53]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanIntersects.swift
[54]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanOverlap.swift
[55]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanOverlapTests.swift "BooleanOverlapTests.swift"
[56]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanParallel.swift
[57]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanParallelTests.swift "BooleanParallelTests.swift"
[58]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanPointInPolygon.swift
[59]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanPointOnLine.swift
[60]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Validatable.swift "Validatable.swift"
[61]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BoundingBoxClip.swift
[62]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BoundingBoxClipTests.swift "BoundingBoxClipTests.swift"
[63]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Buffer.swift
[64]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Center.swift
[65]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Circle.swift
[66]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/CircleTests.swift "CircleTests.swift"
[67]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Conversions.swift
[68]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Destination.swift
[69]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/DestinationTests.swift "DestinationTests.swift"
[70]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Distance.swift
[71]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/DistanceTests.swift "DistanceTests.swift"
[72]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Flatten.swift
[73]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/FlattenTests.swift "FlattenTests.swift"
[74]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Length.swift
[75]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineArc.swift
[76]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineArcTests.swift "LineArcTests.swift"
[77]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineChunk.swift
[78]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineChunkTests.swift "LineChunkTests.swift"
[79]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineIntersect.swift
[80]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineIntersectionTests.swift "LineIntersectionTests.swift"
[81]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineOverlap.swift
[82]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineOverlapTests.swift "LineOverlapTests.swift"
[83]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSegments.swift
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
[100]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Projection.swift "Projection.swift"
[101]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/ProjectionTests.swift "ProjectionTests.swift"
[102]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Reverse.swift "Reverse.swift"
[103]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/ReverseTests.swift "ReverseTests.swift"
[104]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbBearing.swift "RhumbBearing.swift"
[105]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbBearingTests.swift "RhumbBearingTests.swift"
[106]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbDestination.swift "RhumbDestination.swift"
[107]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbDestinationTests.swift "RhumbDestinationTests.swift"
[108]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbDistance.swift "RhumbDistance.swift"
[109]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbDistanceTests.swift "RhumbDistanceTests.swift"
[110]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Simplify.swift "Simplify.swift"
[111]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/SimplifyTests.swift "SimplifyTests.swift"
[112]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformCoordinates.swift "TransformCoordinates.swift"
[113]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformRotate.swift "TransformRotate.swift"
[114]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformScale.swift "TransformScale.swift"
[115]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformTranslate.swift "TransformTranslate.swift"
[116]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Truncate.swift "Truncate.swift"
[117]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TruncateTests.swift "TruncateTests.swift"
[118]:	https://github.com/Outdooractive/mvt-tools

[image-1]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dswift-versions
[image-2]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dplatforms
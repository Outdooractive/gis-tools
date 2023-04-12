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

## GeoJSON

### Coordinate3D/CoordinateXY
Tests: [Coordinate test cases][11]

### BoundingBox
Tests: [BoundingBox test cases][12]

### Point
Tests: [Point test cases][13]

### MultiPoint
Tests: [MultiPoint test cases][14]

### LineString
Tests: [LineString test cases][15]

### MultiLineString
Tests: [MultiLineString test cases][16]

### Polygon
Tests: [Polygon test cases][17]

### MultiPolygon
Tests: [MultiPolygon test cases][18]

### GeometryCollection
Tests: [GeometryCollection test cases][19]

### Feature
Tests: [Feature test cases][20]

### FeatureCollection
Tests: [FeatureCollection test cases][21]

## WKB/WKT
The following geometry types are supported: `point`, `linestring`, `linearring`, `polygon`, `multipoint`, `multilinestring`, `multipolygon`, `geometrycollection` and `triangle`. Please open an issue if you need more.

Every GeoJSON object has convenience methods to encode and decode themselves to and from WKB/WKT, and there are extensions for `Data` and `String` to decode from WKB and WKT to GeoJSON. In the end, they all forward to `WKBCoder` and `WKTCoder` which do the heavy lifting.

### WKB
Also have a look at  the tests: [WKB test cases][22]

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

### WKT
This is exactly the same as WKB… Also have a look at the tests to see how it works: [WKT test cases][23]

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

## Spatial index
This package includes a simple R-tree implementation: [RTree test cases][24]

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

## Algorithms

| Name                        | Examples                                                                               | Source/Tests            |
| --------------------------- | -------------------------------------------------------------------------------------- | ----------------------- |
| along                       | let coordinate = lineString.coordinateAlong(distance: 100.0)                           | [Source][25][Tests][26] |
| area                        | Polygon(…).area                                                                        | [Source][27]            |
| bearing                     | Coordinate3D(…).bearing(to: Coordinate3D(…))                                           | [Source][28][Tests][29] |
| boolean-clockwise           | Polygon(…).outerRing?.isClockwise                                                      | [Source][30][Tests][31] |
| boolean-crosses             | TODO                                                                                   | [Source][32]            |
| boolean-intersects          | TODO                                                                                   | [Source][33]            |
| boolean-overlap             | lineString1.isOverlapping(with: lineString2)                                           | [Source][34][Tests][35] |
| boolean-parallel            | lineString1.isParallel(to: lineString2)                                                | [Source][36][Tests][37] |
| boolean-point-in-polygon    | polygon.contains(Coordinate3D(…))                                                      | [Source][38]            |
| boolean-point-on-line       | lineString.checkIsOnLine(Coordinate3D(…))                                              | [Source][39]            |
| boolean-valid               | anyGeometry.isValid                                                                    | [Source][40]            |
| bbox-clip                   | let clipped = lineString.clipped(to: boundingBox)                                      | [Source][41][Tests][42] |
| buffer                      | TODO                                                                                   | [Source][43]            |
| center/centroid/center-mean | let center = polygon.center                                                            | [Source][44]            |
| circle                      | let circle = point.circle(radius: 5000.0)                                              | [Source][45][Tests][46] |
| conversions/helpers         | let distance = GISTool.convert(length: 1.0, from: .miles, to: .meters)                 | [Source][47]            |
| destination                 | let destination = coordinate.destination(distance: 1000.0, bearing: 173.0)             | [Source][48][Tests][49] |
| distance                    | let distance = coordinate1.distance(from: coordinate2)                                 | [Source][50][Tests][51] |
| flatten                     | let featureCollection = anyGeometry.flattened                                          | [Source][52][Tests][53] |
| length                      | let length = lineString.length                                                         | [Source][54]            |
| line-arc                    | let lineArc = point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0)            | [Source][55][Tests][56] |
| line-chunk                  | let chunks = lineString.chunked(segmentLength: 1000.0).lineStrings                     | [Source][57][Tests][58] |
| line-intersect              | let intersections = feature1.intersections(other: feature2)                            | [Source][59][Tests][60] |
| line-overlap                | let overlappingSegments = lineString1.overlappingSegments(with: lineString2)           | [Source][61][Tests][62] |
| line-segments               | let segments = anyGeometry.lineSegments                                                | [Source][63]            |
| line-slice                  | let slice = lineString.slice(start: Coordinate3D(…), end: Coordinate3D(…))             | [Source][64][Tests][65] |
| line-slice-along            | let sliced = lineString.sliceAlong(startDistance: 50.0, stopDistance: 2000.0)          | [Source][66][Tests][67] |
| midpoint                    | let middle = coordinate1.midpoint(to: coordinate2)                                     | [Source][68][Tests][69] |
| nearest-point               | let nearest = anyGeometry.nearestCoordinate(from: Coordinate3D(…))                     | [Source][70]            |
| nearest-point-on-feature    | let nearest = anyGeometry. nearestCoordinateOnFeature(from: Coordinate3D(…))           | [Source][71]            |
| nearest-point-on-line       | let nearest = lineString.nearestCoordinateOnLine(from: Coordinate3D(…))?.coordinate    | [Source][72][Tests][73] |
| nearest-point-to-line       | let nearest = lineString. nearestCoordinate(outOf: coordinates)                        | [Source][74]            |
| point-on-feature            | let coordinate = anyGeometry.coordinateOnFeature                                       | [Source][75]            |
| points-within-polygon       | let within = polygon.coordinatesWithin(coordinates)                                    | [Source][76]            |
| point-to-line-distance      | let distance = lineString.distanceFrom(coordinate: Coordinate3D(…))                    | [Source][77][Tests][78] |
| pole-of-inaccessibility     | TODO                                                                                   | [Source][79]            |
| projection                  | let coordinateXY = coordinate3D.projectedToEpsg3857                                    | [Source][80][Tests][81] |
| reverse                     | let lineStringReversed = lineString.reversed                                           | [Source][82][Tests][83] |
| rhumb-bearing               | let bearing = start.rhumbBearing(to: end)                                              | [Source][84][Tests][85] |
| rhumb-destination           | let destination = coordinate.rhumbDestination(distance: 1000.0, bearing: 0.0)          | [Source][86][Tests][87] |
| rhumb-distance              | let distance = coordinate1.rhumbDistance(from: coordinate2)                            | [Source][88][Tests][89] |
| simplify                    | let simplified = lineString. simplified(tolerance: 5.0, highQuality: false)            | [Source][90][Tests][91] |
| transform-coordinates       | let transformed = anyGeometry.transformCoordinates({ $0 })                             | [Source][92]            |
| transform-rotate            | let transformed = anyGeometry. transformedRotate(angle: 25.0, pivot: Coordinate3D(…))  | [Source][93]            |
| transform-scale             | let transformed = anyGeometry. transformedScale(factor: 2.5, anchor: .center)          | [Source][94]            |
| transform-translate         | let transformed = anyGeometry. transformedTranslate(distance: 1000.0, direction: 25.0) | [Source][95]            |
| truncate                    | let truncated = lineString.truncated(precision: 2, removeAltitude: true)               | [Source][96][Tests][97] |
[Algorithms ported from Turf]

## Related packages
Currently only one:
- [mvt-tools][98]: Vector tiles reader/writer for Swift

## Contributing
Please create an issue or open a pull request with a fix or enhancement.

## License
MIT

## Author
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
[11]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/CoordinateTests.swift
[12]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/BoundingBoxTests.swift
[13]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/PointTests.swift
[14]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiPointTests.swift
[15]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/LineStringTests.swift
[16]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiLineStringTests.swift
[17]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/PolygonTests.swift
[18]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/MultiPolygonTests.swift
[19]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/GeometryCollectionTests.swift
[20]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/FeatureTests.swift
[21]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/FeatureCollectionTests.swift
[22]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKBTests.swift
[23]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/WKTTests.swift
[24]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/GeoJson/RTreeTests.swift
[25]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Along.swift
[26]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/AlongTests.swift "AlongTests.swift"
[27]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Area.swift
[28]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Bearing.swift
[29]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BearingTests.swift "BearingTests.swift"
[30]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanClockwise.swift
[31]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanClockwiseTests.swift "BooleanClockwiseTests.swift"
[32]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanCrosses.swift
[33]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanIntersects.swift
[34]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanOverlap.swift
[35]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanOverlapTests.swift "BooleanOverlapTests.swift"
[36]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanParallel.swift
[37]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BooleanParallelTests.swift "BooleanParallelTests.swift"
[38]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanPointInPolygon.swift
[39]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BooleanPointOnLine.swift
[40]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Validatable.swift "Validatable.swift"
[41]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/BoundingBoxClip.swift
[42]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/BoundingBoxClipTests.swift "BoundingBoxClipTests.swift"
[43]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Buffer.swift
[44]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Center.swift
[45]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Circle.swift
[46]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/CircleTests.swift "CircleTests.swift"
[47]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Conversions.swift
[48]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Destination.swift
[49]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/DestinationTests.swift "DestinationTests.swift"
[50]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Distance.swift
[51]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/DistanceTests.swift "DistanceTests.swift"
[52]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Flatten.swift
[53]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/FlattenTests.swift "FlattenTests.swift"
[54]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Length.swift
[55]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineArc.swift
[56]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineArcTests.swift "LineArcTests.swift"
[57]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineChunk.swift
[58]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineChunkTests.swift "LineChunkTests.swift"
[59]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineIntersect.swift
[60]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineIntersectionTests.swift "LineIntersectionTests.swift"
[61]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineOverlap.swift
[62]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineOverlapTests.swift "LineOverlapTests.swift"
[63]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSegments.swift
[64]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSlice.swift
[65]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineSliceTests.swift "LineSliceTests.swift"
[66]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/LineSliceAlong.swift
[67]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/LineSliceAlongTests.swift "LineSliceAlongTests.swift"
[68]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/MidPoint.swift
[69]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/MidPointTests.swift "MidPointTests.swift"
[70]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPoint.swift
[71]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPointOnFeature.swift
[72]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPointOnLine.swift
[73]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/NearestCoordinateOnLineTests.swift "NearestCoordinateOnLineTests.swift"
[74]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/NearestPointToLine.swift "NearestPointToLine.swift"
[75]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PointOnFeature.swift "PointOnFeature.swift"
[76]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PointsWithinPolygon.swift "PointsWithinPolygon.swift"
[77]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PointToLineDistance.swift "PointToLineDistance.swift"
[78]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/PointToLineDistanceTests.swift "PointToLineDistanceTests.swift"
[79]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/PoleOfInaccessibility.swift "PoleOfInaccessibility.swift"
[80]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Projection.swift "Projection.swift"
[81]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/ProjectionTests.swift "ProjectionTests.swift"
[82]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Reverse.swift "Reverse.swift"
[83]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/ReverseTests.swift "ReverseTests.swift"
[84]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbBearing.swift "RhumbBearing.swift"
[85]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbBearingTests.swift "RhumbBearingTests.swift"
[86]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbDestination.swift "RhumbDestination.swift"
[87]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbDestinationTests.swift "RhumbDestinationTests.swift"
[88]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/RhumbDistance.swift "RhumbDistance.swift"
[89]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/RhumbDistanceTests.swift "RhumbDistanceTests.swift"
[90]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Simplify.swift "Simplify.swift"
[91]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/SimplifyTests.swift "SimplifyTests.swift"
[92]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformCoordinates.swift "TransformCoordinates.swift"
[93]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformRotate.swift "TransformRotate.swift"
[94]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformScale.swift "TransformScale.swift"
[95]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/TransformTranslate.swift "TransformTranslate.swift"
[96]:	https://github.com/Outdooractive/gis-tools/blob/main/Sources/GISTools/Turf/Truncate.swift "Truncate.swift"
[97]:	https://github.com/Outdooractive/gis-tools/blob/main/Tests/GISToolsTests/Turf/TruncateTests.swift "TruncateTests.swift"
[98]:	https://github.com/Outdooractive/mvt-tools

[image-1]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dswift-versions
[image-2]:	https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dplatforms
import Foundation
@testable import GISTools
@testable import struct GISTools.Polygon
import Testing

struct WKTTests {

    // MARK: - Point

    private let pointData = "POINT(1 2)"
    private let pointZData = "POINT Z (1 2 3)"
    private let pointMData = "POINT M (1 2 4)"
    private let pointZMData = "POINTZM(1 2 3 4)"

    /// Validates decoding WKT Point types (XY, XYZ, XYM, XYZM).
    @Test
    func pointDecoding() throws {
        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as? Point)
        #expect(point.coordinate.longitude == 1)
        #expect(point.coordinate.latitude == 2)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326) as? Point)
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326) as? Point)
        #expect(pointM.coordinate.longitude == 1)
        #expect(pointM.coordinate.latitude == 2)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326) as? Point)
        #expect(pointZM.coordinate.longitude == 1)
        #expect(pointZM.coordinate.latitude == 2)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates decoding WKT Point with reprojection from EPSG:4326 to EPSG:3857.
    @Test
    func pointDecoding4326To3857() throws {
        let expectedX = 111_319.49079327357
        let expectedY = 222_684.20850554455

        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(point.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(point.coordinate.y - expectedY) < 0.00000001)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(pointZ.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(pointZ.coordinate.y - expectedY) < 0.00000001)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(pointM.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(pointM.coordinate.y - expectedY) < 0.00000001)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(pointZM.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(pointZM.coordinate.y - expectedY) < 0.00000001)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates decoding WKT Point with reprojection from EPSG:3857 to EPSG:4326.
    @Test
    func pointDecoding3857To4326() throws {
        let expectedLongitude = 0.000008983152841195214
        let expectedLatitude = 0.000017966305681987637

        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(point.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(point.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(pointZ.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(pointZ.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(pointM.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(pointM.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(pointZM.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(pointZM.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates decoding WKT Point with no SRID (noSRID).
    @Test
    func pointDecodingNoSRID() throws {
        let expected = Coordinate3D(x: 1, y: 2, projection: .noSRID)

        #expect(throws: WKTCoder.WKTCoderError.self) {
            try WKTCoder.decode(wkt: pointData, sourceProjection: .noSRID) as? Point
        }

        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(point.coordinate.x == expected.x)
        #expect(point.coordinate.y == expected.y)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKTCoder.decode(wkt: pointZData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKTCoder.decode(wkt: pointMData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKTCoder.decode(wkt: pointZMData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates encoding a Point to WKT string.
    @Test
    func pointEncoding() throws {
        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as? Point)
        let encodedPoint = WKTCoder.encode(geometry: point, targetProjection: nil)
        #expect(encodedPoint == "POINT(1.0 2.0)")

        let pointZ = try #require(try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326) as? Point)
        let encodedPointZ = WKTCoder.encode(geometry: pointZ, targetProjection: nil)
        #expect(encodedPointZ == "POINTZ(1.0 2.0 3.0)")

        let pointM = try #require(try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326) as? Point)
        let encodedPointM = WKTCoder.encode(geometry: pointM, targetProjection: nil)
        #expect(encodedPointM == "POINTM(1.0 2.0 4.0)")

        let pointZM = try #require(try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326) as? Point)
        let encodedPointZM = WKTCoder.encode(geometry: pointZM, targetProjection: nil)
        #expect(encodedPointZM == "POINTZM(1.0 2.0 3.0 4.0)")
    }

    /// Validates encoding a Point to WKT with SRID prefix for target projections.
    @Test
    func pointEncodingWithProjections() throws {
        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as? Point)
        let encodedPoint = WKTCoder.encode(geometry: point, targetProjection: .epsg4326)
        #expect(encodedPoint == "SRID=4326;POINT(\(point.coordinate.x) \(point.coordinate.y))")

        let expected = Coordinate3D(latitude: 2, longitude: 1).projected(to: .epsg3857)
        let encodedPoint3857 = WKTCoder.encode(geometry: point, targetProjection: .epsg3857)
        #expect(encodedPoint3857 == "SRID=3857;POINT(\(expected.x) \(expected.y))")

        let encodedPointNoSRID = WKTCoder.encode(geometry: point, targetProjection: .noSRID)
        #expect(encodedPointNoSRID == "SRID=0;POINT(\(point.coordinate.x) \(point.coordinate.y))")
    }

    // MARK: - MultiPoint

    private let multiPointData = "MULTIPOINT((0 0),(1 2))"

    /// Validates decoding a WKT MultiPoint.
    @Test
    func multiPointDecoding() throws {
        let multiPoint = try #require(try WKTCoder.decode(wkt: multiPointData, sourceProjection: .epsg4326) as? MultiPoint)
        #expect(multiPoint.coordinates.count == 2)
        #expect(multiPoint.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0))
        #expect(multiPoint.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1))
    }

    /// Validates encoding a MultiPoint to WKT.
    @Test
    func multiPointEncoding() throws {
        let multiPoint = try #require(try WKTCoder.decode(wkt: multiPointData, sourceProjection: .epsg4326) as? MultiPoint)
        let encodedMultiPoint = WKTCoder.encode(geometry: multiPoint, targetProjection: nil)
        #expect(encodedMultiPoint == "MULTIPOINT(0.0 0.0,1.0 2.0)")
    }

    // MARK: - MultiPoint with SRID

    private let multiPointZSRIDData = "SRID=4326;MULTIPOINTZ(0 0 0,1 2 1)"

    /// Validates decoding a WKT MultiPoint with SRID prefix.
    @Test
    func multiPointSRIDDecoding() throws {
        let multiPointZSRID = try #require(try WKTCoder.decode(wkt: multiPointZSRIDData, sourceSrid: nil) as? MultiPoint)
        #expect(multiPointZSRID.coordinates.count == 2)
        #expect(multiPointZSRID.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0, altitude: 0))
        #expect(multiPointZSRID.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1, altitude: 1))
    }

    /// Validates encoding a MultiPoint with SRID back to WKT.
    @Test
    func multiPointSRIDEncoding() throws {
        let multiPointZSRID = try #require(try WKTCoder.decode(wkt: multiPointZSRIDData, sourceSrid: nil) as? MultiPoint)
        let encodedMultiPointZSRID = WKTCoder.encode(geometry: multiPointZSRID, targetProjection: .epsg4326)
        #expect(encodedMultiPointZSRID == "SRID=4326;MULTIPOINTZ(0.0 0.0 0.0,1.0 2.0 1.0)")
    }

    // MARK: - LineString

    private let lineStringData = "LINESTRING (1 1, 1 2, 1 3, 2 2)"
    private let lineStringZData = "LINESTRING Z (1 1 5, 1 2 5, 1 3 5, 2 2 5)"
    private let lineStringMData = "LINESTRING M (1 1 0, 1 2 0, 1 3 1, 2 2 0)"
    private let lineStringZMData = "LINESTRING ZM (1 1 5 0, 1 2 5 0, 1 3 5 1, 2 2 5 0)"
    private let linearRingZData = "LINEARRING (0 0 0, 4 0 0, 4 4 0, 0 4 0, 0 0 0)"

    /// Validates decoding WKT LineString and LinearRing types.
    @Test
    func lineStringDecoding() throws {
        let lineString = try #require(try WKTCoder.decode(wkt: lineStringData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineString.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ])

        let lineStringZ = try #require(try WKTCoder.decode(wkt: lineStringZData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineStringZ.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0, altitude: 5.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0, altitude: 5.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0, altitude: 5.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0, altitude: 5.0),
        ])

        let lineStringM = try #require(try WKTCoder.decode(wkt: lineStringMData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineStringM.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0, m: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0, m: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0, m: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0, m: 0.0),
        ])

        let lineStringZM = try #require(try WKTCoder.decode(wkt: lineStringZMData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineStringZM.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0, altitude: 5.0, m: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0, altitude: 5.0, m: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0, altitude: 5.0, m: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0, altitude: 5.0, m: 0.0),
        ])

        let linearRingZ = try #require(try WKTCoder.decode(wkt: linearRingZData, sourceProjection: .epsg4326) as? LineString)
        #expect(linearRingZ.coordinates == [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])
    }

    /// Validates encoding a LineString to WKT.
    @Test
    func lineStringEncoding() throws {
        let lineString = try #require(try WKTCoder.decode(wkt: lineStringData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineString = WKTCoder.encode(geometry: lineString, targetProjection: nil)
        #expect(encodedLineString == "LINESTRING(1.0 1.0,1.0 2.0,1.0 3.0,2.0 2.0)")

        let lineStringZ = try #require(try WKTCoder.decode(wkt: lineStringZData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineStringZ = WKTCoder.encode(geometry: lineStringZ, targetProjection: nil)
        #expect(encodedLineStringZ == "LINESTRINGZ(1.0 1.0 5.0,1.0 2.0 5.0,1.0 3.0 5.0,2.0 2.0 5.0)")

        let lineStringM = try #require(try WKTCoder.decode(wkt: lineStringMData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineStringM = WKTCoder.encode(geometry: lineStringM, targetProjection: nil)
        #expect(encodedLineStringM == "LINESTRINGM(1.0 1.0 0.0,1.0 2.0 0.0,1.0 3.0 1.0,2.0 2.0 0.0)")

        let lineStringZM = try #require(try WKTCoder.decode(wkt: lineStringZMData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineStringZM = WKTCoder.encode(geometry: lineStringZM, targetProjection: nil)
        #expect(encodedLineStringZM == "LINESTRINGZM(1.0 1.0 5.0 0.0,1.0 2.0 5.0 0.0,1.0 3.0 5.0 1.0,2.0 2.0 5.0 0.0)")
    }

    // MARK: - MultiLineString

    private let multiLineStringData = "MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))"

    /// Validates decoding a WKT MultiLineString.
    @Test
    func multiLineStringDecoding() throws {
        let multiLineString = try #require(try WKTCoder.decode(wkt: multiLineStringData, sourceProjection: .epsg4326) as? MultiLineString)
        #expect(multiLineString.coordinates == [
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 1.0),
            ],
            [
                Coordinate3D(latitude: 3.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 3.0),
                Coordinate3D(latitude: 4.0, longitude: 5.0),
            ],
        ])
    }

    /// Validates encoding a MultiLineString to WKT.
    @Test
    func multiLineStringEncoding() throws {
        let multiLineString = try #require(try WKTCoder.decode(wkt: multiLineStringData, sourceProjection: .epsg4326) as? MultiLineString)
        let encodedMultiLineString = WKTCoder.encode(geometry: multiLineString, targetProjection: nil)
        #expect(encodedMultiLineString == "MULTILINESTRING((0.0 0.0,1.0 1.0,1.0 2.0),(2.0 3.0,3.0 2.0,5.0 4.0))")
    }

    // MARK: - Polygon

    private let polygonData = "POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))"
    private let polygonZData = "POLYGON Z ((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))"
    private let polygonMData = "POLYGON M ((0 0 2, 0 1 2, 1 1 2, 1 0 2, 0 0 2))"
    private let polygonZMData = "POLYGON ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 1 0 0 2, 0 0 0 2))"
    private let polygonWithHoleData = "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 1 2, 2 2, 2 1, 1 1))"

    /// Validates decoding WKT Polygon types (XY, XYZ, XYM, XYZM, with hole).
    @Test
    func polygonDecoding() throws {
        let expectedOuter = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try #require(try WKTCoder.decode(wkt: polygonData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygon.coordinates == [expectedOuter])

        let polygonZ = try #require(try WKTCoder.decode(wkt: polygonZData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonZ.coordinates == [expectedOuter.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0)
        }])

        let polygonM = try #require(try WKTCoder.decode(wkt: polygonMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonM.coordinates == [expectedOuter.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, m: 2.0)
        }])

        let polygonZM = try #require(try WKTCoder.decode(wkt: polygonZMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonZM.coordinates == [expectedOuter.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0, m: 2.0)
        }])

        let polygonWithHole = try #require(try WKTCoder.decode(wkt: polygonWithHoleData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonWithHole.coordinates == [
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 1.0, longitude: 2.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
            ],
        ])
    }

    /// Validates encoding a Polygon to WKT.
    @Test
    func polygonEncoding() throws {
        let polygon = try #require(try WKTCoder.decode(wkt: polygonData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygon = WKTCoder.encode(geometry: polygon, targetProjection: nil)
        #expect(encodedPolygon == "POLYGON((0.0 0.0,0.0 1.0,1.0 1.0,1.0 0.0,0.0 0.0))")

        let polygonZ = try #require(try WKTCoder.decode(wkt: polygonZData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonZ = WKTCoder.encode(geometry: polygonZ, targetProjection: nil)
        #expect(encodedPolygonZ == "POLYGONZ((0.0 0.0 0.0,0.0 1.0 0.0,1.0 1.0 0.0,1.0 0.0 0.0,0.0 0.0 0.0))")

        let polygonM = try #require(try WKTCoder.decode(wkt: polygonMData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonM = WKTCoder.encode(geometry: polygonM, targetProjection: nil)
        #expect(encodedPolygonM == "POLYGONM((0.0 0.0 2.0,0.0 1.0 2.0,1.0 1.0 2.0,1.0 0.0 2.0,0.0 0.0 2.0))")

        let polygonZM = try #require(try WKTCoder.decode(wkt: polygonZMData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonZM = WKTCoder.encode(geometry: polygonZM, targetProjection: nil)
        #expect(encodedPolygonZM == "POLYGONZM((0.0 0.0 0.0 2.0,0.0 1.0 0.0 2.0,1.0 1.0 0.0 2.0,1.0 0.0 0.0 2.0,0.0 0.0 0.0 2.0))")

        let polygonWithHole = try #require(try WKTCoder.decode(wkt: polygonWithHoleData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonWithHole = WKTCoder.encode(geometry: polygonWithHole, targetProjection: nil)
        #expect(encodedPolygonWithHole == "POLYGON((0.0 0.0,10.0 0.0,10.0 10.0,0.0 10.0,0.0 0.0),(1.0 1.0,1.0 2.0,2.0 2.0,2.0 1.0,1.0 1.0))")
    }

    // MARK: - MultiPolygon

    private let multiPolygonData = "MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))"

    /// Validates decoding a WKT MultiPolygon.
    @Test
    func multiPolygonDecoding() throws {
        let multiPolygon = try #require(try WKTCoder.decode(wkt: multiPolygonData, sourceProjection: .epsg4326) as? MultiPolygon)
        #expect(multiPolygon.coordinates == [
            [
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 0.0, longitude: 4.0),
                    Coordinate3D(latitude: 4.0, longitude: 4.0),
                    Coordinate3D(latitude: 4.0, longitude: 0.0),
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                ],
                [
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                    Coordinate3D(latitude: 1.0, longitude: 2.0),
                    Coordinate3D(latitude: 2.0, longitude: 2.0),
                    Coordinate3D(latitude: 2.0, longitude: 1.0),
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                ],
            ],
            [[
                Coordinate3D(latitude: -1.0, longitude: -1.0),
                Coordinate3D(latitude: -2.0, longitude: -1.0),
                Coordinate3D(latitude: -2.0, longitude: -2.0),
                Coordinate3D(latitude: -1.0, longitude: -2.0),
                Coordinate3D(latitude: -1.0, longitude: -1.0),
            ]],
        ])
    }

    /// Validates encoding a MultiPolygon to WKT.
    @Test
    func multiPolygonEncoding() throws {
        let multiPolygon = try #require(try WKTCoder.decode(wkt: multiPolygonData, sourceProjection: .epsg4326) as? MultiPolygon)
        let encodedMultiPolygon = WKTCoder.encode(geometry: multiPolygon, targetProjection: nil)
        #expect(encodedMultiPolygon == "MULTIPOLYGON(((0.0 0.0,4.0 0.0,4.0 4.0,0.0 4.0,0.0 0.0),(1.0 1.0,2.0 1.0,2.0 2.0,1.0 2.0,1.0 1.0)),((-1.0 -1.0,-1.0 -2.0,-2.0 -2.0,-2.0 -1.0,-1.0 -1.0)))")
    }

    // MARK: - GeometryCollection

    private let geometryCollectionData = "GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))"

    /// Validates decoding a WKT GeometryCollection.
    @Test
    func geometryCollectionDecoding() throws {
        let geometryCollection = try #require(try WKTCoder.decode(wkt: geometryCollectionData, sourceProjection: .epsg4326) as? GeometryCollection)
        #expect(geometryCollection.geometries.count == 2)
        #expect(geometryCollection.geometries[0].type == .point)
        #expect(geometryCollection.geometries[1].type == .polygon)
    }

    /// Validates encoding a GeometryCollection to WKT.
    @Test
    func geometryCollectionEncoding() throws {
        let geometryCollection = try #require(try WKTCoder.decode(wkt: geometryCollectionData, sourceProjection: .epsg4326) as? GeometryCollection)
        let encodedGeometryCollection = WKTCoder.encode(geometry: geometryCollection, targetProjection: nil)
        #expect(encodedGeometryCollection == "GEOMETRYCOLLECTION(POINT(2.0 0.0),POLYGON((0.0 0.0,1.0 0.0,1.0 1.0,0.0 1.0,0.0 0.0)))")
    }

    // MARK: - Triangle

    private let triangleData = "TRIANGLE((0 0, 0 1, 1 1, 0 0))"
    private let triangleZData = "TRIANGLE Z ((0 0 0, 0 1 0, 1 1 0, 0 0 0))"
    private let triangleMData = "TRIANGLE M ((0 0 2, 0 1 2, 1 1 2, 0 0 2))"
    private let triangleZMData = "TRIANGLE ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 0 0 0 2))"

    /// Validates decoding WKT Triangle types (XY, XYZ, XYM, XYZM) as Polygon.
    @Test
    func triangleDecoding() throws {
        let expected = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]

        let triangle = try #require(try WKTCoder.decode(wkt: triangleData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangle.coordinates == [expected])

        let triangleZ = try #require(try WKTCoder.decode(wkt: triangleZData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangleZ.coordinates == [expected.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0)
        }])

        let triangleM = try #require(try WKTCoder.decode(wkt: triangleMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangleM.coordinates == [expected.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, m: 2.0)
        }])

        let triangleZM = try #require(try WKTCoder.decode(wkt: triangleZMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangleZM.coordinates == [expected.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0, m: 2.0)
        }])
    }

    // MARK: - GeoJsonGeometry convenience

    /// Validates parsing a geometry from WKT with a source SRID.
    @Test
    func geoJsonGeometryParseSourceSrid() {
        let geometry = GeometryCollection.parse(wkt: pointData, sourceSrid: 4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.longitude == 1)
    }

    /// Validates parsing a geometry from WKT with a source projection.
    @Test
    func geoJsonGeometryParseSourceProjection() {
        let geometry = GeometryCollection.parse(wkt: pointData, sourceProjection: .epsg4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.longitude == 1)
    }

    /// Validates encoding a geometry to WKT string.
    @Test
    func geoJsonGeometryAsWKT() throws {
        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as? Point)
        #expect(point.asWKT?.uppercased().contains("POINT") == true)
    }

    // MARK: - Feature convenience

    /// Validates creating a Feature from WKT with a source SRID.
    @Test
    func featureInitSourceSrid() {
        let feature = Feature(
            wkt: pointZData,
            sourceSrid: 4326,
            id: .string("f1"),
            properties: ["key": "value"])
        #expect(feature?.id == .string("f1"))
        #expect(feature?.geometry is Point)
        #expect(feature?.properties["key"] as? String == "value")
    }

    /// Validates creating a Feature from WKT with a source projection.
    @Test
    func featureInitSourceProjection() {
        let feature = Feature(
            wkt: pointZData,
            sourceProjection: .epsg4326,
            id: .string("f2"))
        #expect(feature?.id == .string("f2"))
        #expect(feature?.geometry is Point)
    }

    /// Validates encoding a Feature to WKT string.
    @Test
    func featureAsWKT() throws {
        let point = try #require(try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as? Point)
        let feature = Feature(point)
        #expect(feature.asWKT?.uppercased().contains("POINT") == true)
    }

    // MARK: - FeatureCollection convenience

    /// Validates creating a FeatureCollection from WKT with a source SRID.
    @Test
    func featureCollectionInitSourceSrid() {
        let fc = FeatureCollection(wkt: pointData, sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    /// Validates creating a FeatureCollection from WKT with a source projection.
    @Test
    func featureCollectionInitSourceProjection() {
        let fc = FeatureCollection(wkt: pointData, sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    // MARK: - String convenience

    /// Validates decoding a WKT string to a geometry using a source SRID.
    @Test
    func stringAsGeoJsonGeometrySourceSrid() {
        let geometry = pointZData.asGeoJsonGeometry(sourceSrid: 4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.altitude == 3)
    }

    /// Validates decoding a WKT string to a geometry using a source projection.
    @Test
    func stringAsGeoJsonGeometrySourceProjection() {
        let geometry = pointZData.asGeoJsonGeometry(sourceProjection: .epsg4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.altitude == 3)
    }

    /// Validates decoding a WKT string to a Feature using a source SRID.
    @Test
    func stringAsFeatureSourceSrid() {
        let feature = pointZData.asFeature(sourceSrid: 4326, id: .string("s1"))
        #expect(feature?.id == .string("s1"))
        #expect(feature?.geometry is Point)
    }

    /// Validates decoding a WKT string to a Feature using a source projection.
    @Test
    func stringAsFeatureSourceProjection() {
        let feature = pointZData.asFeature(sourceProjection: .epsg4326)
        #expect(feature?.geometry is Point)
    }

    /// Validates decoding a WKT string to a FeatureCollection using a source SRID.
    @Test
    func stringAsFeatureCollectionSourceSrid() {
        let fc = pointData.asFeatureCollection(sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    /// Validates decoding a WKT string to a FeatureCollection using a source projection.
    @Test
    func stringAsFeatureCollectionSourceProjection() {
        let fc = pointData.asFeatureCollection(sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

}

// MARK: - GeoJSON audit regressions

extension WKTTests {

    @Test(arguments: [
        "POINT (1 2",
        "POINT (1 2) trailing",
        "POINT (1 2, 3 4)",
        "LINESTRING ()",
        "MULTILINESTRING ()",
        "MULTIPOLYGON ()",
    ])
    func malformedWKTIsRejected(wkt: String) {
        #expect(throws: WKTCoder.WKTCoderError.self) {
            try WKTCoder.decode(wkt: wkt, sourceProjection: .epsg4326)
        }
    }

    /// Nested WKT components must be encoded in the requested projection.
    @Test
    func wktNestedGeometryUsesTargetProjection() throws {
        let point = Point(Coordinate3D(
            x: 1_000_000.0,
            y: 2_000_000.0,
            projection: .epsg3857))
        let collection = GeometryCollection([point])
        let wkt = try #require(WKTCoder.encode(
            geometry: collection,
            targetProjection: .epsg3857))
        let decoded = try #require(try WKTCoder.decode(
            wkt: wkt,
            sourceSrid: nil,
            targetProjection: .epsg3857) as? GeometryCollection)
        let decodedPoint = try #require(decoded.geometries.first as? Point)

        #expect(decodedPoint.coordinate.longitude == 1_000_000.0)
        #expect(decodedPoint.coordinate.latitude == 2_000_000.0)
    }

    /// MultiPoint accepts whitespace between the outer and inner parentheses.
    @Test
    func wktMultiPointWithWhitespace() throws {
        let multiPoint = try #require(try WKTCoder.decode(
            wkt: "MULTIPOINT ( (1 2), (3 4) )",
            sourceProjection: .epsg4326) as? MultiPoint)

        #expect(multiPoint.coordinates == [
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 4.0, longitude: 3.0),
        ])
    }

    /// A nil WKT target projection uses the geometry's native projection.
    @Test
    func wktNilTargetProjectionUsesNativeProjection() throws {
        let point = Point(Coordinate3D(
            x: 1_000_000.0,
            y: 2_000_000.0,
            projection: .epsg3857))
        let wkt = try #require(WKTCoder.encode(
            geometry: point,
            targetProjection: nil))

        #expect(wkt == "POINT(1000000.0 2000000.0)")
    }

    // MARK: - Curves and surfaces

    /// Validates that CIRCULARSTRING is linearized into a LineString.
    @Test
    func wktCircularStringDecoding() throws {
        let lineString = try #require(try WKTCoder.decode(
            wkt: "CIRCULARSTRING(0 0, 1 1, 2 0)",
            sourceProjection: .epsg4326) as? LineString)

        #expect(lineString.coordinates.count > 3)
        #expect(lineString.coordinates.first == Coordinate3D(latitude: 0, longitude: 0))
        #expect(lineString.coordinates.last == Coordinate3D(latitude: 0, longitude: 2))
        #expect(lineString.coordinates.contains { coordinate in
            abs(coordinate.longitude - 1.0) < 1e-6 && abs(coordinate.latitude - 1.0) < 1e-6
        })
    }

    /// Validates that COMPOUNDCURVE is linearized into a LineString.
    @Test
    func wktCompoundCurveDecoding() throws {
        let lineString = try #require(try WKTCoder.decode(
            wkt: "COMPOUNDCURVE(CIRCULARSTRING(0 0, 1 1, 2 0), (2 0, 3 1))",
            sourceProjection: .epsg4326) as? LineString)

        #expect(lineString.coordinates.first == Coordinate3D(latitude: 0, longitude: 0))
        #expect(lineString.coordinates.last == Coordinate3D(latitude: 1, longitude: 3))
        #expect(lineString.coordinates.contains { coordinate in
            abs(coordinate.longitude - 2.0) < 1e-9 && abs(coordinate.latitude - 0.0) < 1e-9
        })
    }

    /// Validates that CURVEPOLYGON is linearized into a Polygon.
    @Test
    func wktCurvePolygonDecoding() throws {
        let polygon = try #require(try WKTCoder.decode(
            wkt: "CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0))",
            sourceProjection: .epsg4326) as? Polygon)

        #expect(polygon.coordinates.count == 1)
        #expect(polygon.coordinates[0].count > 4)
        #expect(polygon.coordinates[0].first == polygon.coordinates[0].last)
    }

    /// Validates that MULTICURVE is linearized into a MultiLineString.
    @Test
    func wktMultiCurveDecoding() throws {
        let multiLineString = try #require(try WKTCoder.decode(
            wkt: "MULTICURVE(CIRCULARSTRING(0 0, 1 1, 2 0), (2 0, 3 1))",
            sourceProjection: .epsg4326) as? MultiLineString)

        #expect(multiLineString.coordinates.count == 2)
        #expect(multiLineString.coordinates[1].last == Coordinate3D(latitude: 1, longitude: 3))
    }

    /// Validates that MULTISURFACE is linearized into a MultiPolygon.
    @Test
    func wktMultiSurfaceDecoding() throws {
        let multiPolygon = try #require(try WKTCoder.decode(
            wkt: "MULTISURFACE(CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0)))",
            sourceProjection: .epsg4326) as? MultiPolygon)

        #expect(multiPolygon.polygons.count == 1)
        #expect(multiPolygon.polygons[0].coordinates[0].count > 4)
    }

    /// Validates that TIN and POLYHEDRALSURFACE decode to a MultiPolygon.
    @Test
    func wktTinAndPolyhedralSurfaceDecoding() throws {
        let tin = try #require(try WKTCoder.decode(
            wkt: "TIN(((0 0, 1 0, 0 1, 0 0)))",
            sourceProjection: .epsg4326) as? MultiPolygon)
        #expect(tin.polygons.count == 1)
        #expect(tin.polygons[0].coordinates[0].count == 4)

        let polyhedralSurface = try #require(try WKTCoder.decode(
            wkt: "POLYHEDRALSURFACE(((0 0, 1 0, 0 1, 0 0)))",
            sourceProjection: .epsg4326) as? MultiPolygon)
        #expect(polyhedralSurface.polygons.count == 1)
        #expect(polyhedralSurface.polygons[0].coordinates[0].count == 4)
    }

    /// Validates that POINT EMPTY becomes an empty MultiPoint.
    @Test
    func wktEmptyPointDecoding() throws {
        let multiPoint = try #require(try WKTCoder.decode(
            wkt: "POINT EMPTY",
            sourceProjection: .epsg4326) as? MultiPoint)

        #expect(multiPoint.points.isEmpty)
    }

    /// Validates EMPTY for the other geometry types.
    @Test
    func wktEmptyGeometryDecoding() throws {
        #expect(try WKTCoder.decode(wkt: "LINESTRING EMPTY", sourceProjection: .epsg4326) is LineString)
        #expect(try WKTCoder.decode(wkt: "POLYGON EMPTY", sourceProjection: .epsg4326) is Polygon)
        #expect(try WKTCoder.decode(wkt: "MULTIPOINT EMPTY", sourceProjection: .epsg4326) is MultiPoint)
        #expect(try WKTCoder.decode(wkt: "MULTILINESTRING EMPTY", sourceProjection: .epsg4326) is MultiLineString)
        #expect(try WKTCoder.decode(wkt: "MULTIPOLYGON EMPTY", sourceProjection: .epsg4326) is MultiPolygon)
        #expect(try WKTCoder.decode(wkt: "GEOMETRYCOLLECTION EMPTY", sourceProjection: .epsg4326) is GeometryCollection)
    }

    /// Validates that empty geometries encode with the WKT EMPTY keyword.
    @Test
    func wktEmptyGeometryEncoding() {
        #expect(WKTCoder.encode(geometry: MultiPoint(), targetProjection: nil) == "MULTIPOINT EMPTY")
        #expect(WKTCoder.encode(geometry: LineString(), targetProjection: nil) == "LINESTRING EMPTY")
        #expect(WKTCoder.encode(geometry: Polygon(), targetProjection: nil) == "POLYGON EMPTY")
        #expect(WKTCoder.encode(geometry: MultiLineString(), targetProjection: nil) == "MULTILINESTRING EMPTY")
        #expect(WKTCoder.encode(geometry: MultiPolygon(), targetProjection: nil) == "MULTIPOLYGON EMPTY")
        #expect(WKTCoder.encode(geometry: GeometryCollection([]), targetProjection: nil) == "GEOMETRYCOLLECTION EMPTY")
    }

    /// Validates Z coordinates and dimension suffixes inside curved types.
    @Test
    func wktCurvedGeometryZDecoding() throws {
        let multiSurface = try #require(try WKTCoder.decode(
            wkt: "MULTISURFACE Z (CURVEPOLYGON Z (CIRCULARSTRING Z (0 0 1, 1 1 2, 2 0 3, 1 -1 4, 0 0 1)))",
            sourceProjection: .epsg4326) as? MultiPolygon)

        let ring = try #require(multiSurface.polygons.first?.coordinates.first)
        #expect(ring.first?.altitude == 1)
        #expect(ring.contains { $0.altitude == 2 })

        let compoundCurve = try #require(try WKTCoder.decode(
            wkt: "COMPOUNDCURVE Z (CIRCULARSTRING Z (0 0 1, 1 1 2, 2 0 3), (2 0 3, 3 1 4))",
            sourceProjection: .epsg4326) as? LineString)

        #expect(compoundCurve.coordinates.first?.altitude == 1)
        #expect(compoundCurve.coordinates.last?.altitude == 4)
    }

}

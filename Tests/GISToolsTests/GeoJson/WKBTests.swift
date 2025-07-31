import Foundation
@testable import GISTools
@testable import struct GISTools.Polygon
import Testing

struct WKBTests {

    // MARK: - Point

    // SELECT 'POINT(1 2)'::geometry;
    private let pointData = Data(hex: "0101000000000000000000F03F0000000000000040")!
    // SELECT 'POINT Z (1 2 3)'::geometry;
    private let pointZData = Data(hex: "0101000080000000000000F03F00000000000000400000000000000840")!
    // SELECT 'POINT M (1 2 4)'::geometry;
    private let pointMData = Data(hex: "0101000040000000000000F03F00000000000000400000000000001040")!
    // SELECT 'POINT ZM (1 2 3 4)'::geometry;
    private let pointZMData = Data(hex: "01010000C0000000000000F03F000000000000004000000000000008400000000000001040")!

    @Test
    func pointDecoding() async throws {
        let point = try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as! Point
        #expect(point.coordinate.longitude == 1)
        #expect(point.coordinate.latitude == 2)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg4326) as! Point
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg4326) as! Point
        #expect(pointM.coordinate.longitude == 1)
        #expect(pointM.coordinate.latitude == 2)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg4326) as! Point
        #expect(pointZM.coordinate.longitude == 1)
        #expect(pointZM.coordinate.latitude == 2)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointDecoding4326To3857() async throws {
        let expected = Coordinate3D(latitude: 2, longitude: 1).projected(to: .epsg3857)

        let point = try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(point.coordinate.x == expected.x)
        #expect(point.coordinate.y == expected.y)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointDecoding3857To4326() async throws {
        let expected = Coordinate3D(x: 1, y: 2).projected(to: .epsg4326)

        let point = try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(point.coordinate.longitude == expected.longitude)
        #expect(point.coordinate.latitude == expected.latitude)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointDecodingNoSRID() async throws {
        let expected = Coordinate3D(x: 1, y: 2, projection: .noSRID)

        #expect(throws: WKBCoder.WKBCoderError.self) {
            try WKBCoder.decode(wkb: pointData, sourceProjection: .noSRID) as! Point
        }

        let point = try WKBCoder.decode(wkb: pointData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(point.coordinate.x == expected.x)
        #expect(point.coordinate.y == expected.y)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKBCoder.decode(wkb: pointZData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKBCoder.decode(wkb: pointMData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointEncoding() async throws {
        let point = try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as! Point
        let encodedPoint = WKBCoder.encode(geometry: point, targetProjection: nil)
        #expect(encodedPoint == pointData)

        let pointZ = try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg4326) as! Point
        let encodedPointZ = WKBCoder.encode(geometry: pointZ, targetProjection: nil)
        #expect(encodedPointZ == pointZData)

        let pointM = try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg4326) as! Point
        let encodedPointM = WKBCoder.encode(geometry: pointM, targetProjection: nil)
        #expect(encodedPointM == pointMData)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg4326) as! Point
        let encodedPointZM = WKBCoder.encode(geometry: pointZM, targetProjection: nil)
        #expect(encodedPointZM == pointZMData)
    }

    @Test
    func pointConvenienceDecoding() async throws {
        let pointZ = Point(wkb: pointZData, sourceProjection: .epsg4326)!
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)
    }

    @Test
    func pointDataConvenienceDecoding() async throws {
        let pointZ = pointZData.asGeoJsonGeometry(sourceProjection: .epsg4326) as! Point
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)

        let feature = pointZData.asFeature(sourceProjection: .epsg4326)
        #expect(feature?.geometry.allCoordinates.first?.longitude == 1)
        #expect(feature?.geometry.allCoordinates.first?.latitude == 2)
        #expect(feature?.geometry.allCoordinates.first?.altitude == 3)
    }

    // SELECT ST_ClipByBox2D(ToPoint('POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))'::geometry), ST_MakeEnvelope(0,0,0.2,0.2));
    private let invalidPointData = Data(hex: "0101000000000000000000F87F000000000000F87F")!

    @Test
    func invalidPointDecoding() async throws {
        #expect(throws: WKBCoder.WKBCoderError.self) {
            try WKBCoder.decode(wkb: invalidPointData, sourceProjection: .epsg4326) as? Point
        }
    }

    // MARK: - MultiPoint

    // SELECT 'MULTIPOINT((0 0),(1 2))'::geometry;
    private let multiPointData = Data(hex: "0104000000020000000101000000000000000000000000000000000000000101000000000000000000F03F0000000000000040")!

    @Test
    func multiPointDecoding() async throws {
        let multiPoint = try WKBCoder.decode(wkb: multiPointData, sourceProjection: .epsg4326) as! MultiPoint
        #expect(multiPoint.coordinates.count == 2)
        #expect(multiPoint.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0))
        #expect(multiPoint.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1))
    }

    @Test
    func multiPointEncoding() async throws {
        let multiPoint = try WKBCoder.decode(wkb: multiPointData, sourceProjection: .epsg4326) as! MultiPoint
        let encodedMultiPoint = WKBCoder.encode(geometry: multiPoint, targetProjection: nil)
        #expect(encodedMultiPoint == multiPointData)
    }

    // MARK: - MultiPoint with SRID

    // SELECT 'SRID=4326;MULTIPOINTZ(0 0 0,1 2 1)'::geometry;
    private let multiPointZSRIDData = Data(hex: "01040000A0E61000000200000001010000800000000000000000000000000000000000000000000000000101000080000000000000F03F0000000000000040000000000000F03F")!

    @Test
    func multiPointSRIDDecoding() async throws {
        let multiPointZSRID = try WKBCoder.decode(wkb: multiPointZSRIDData, sourceSrid: nil) as! MultiPoint
        #expect(multiPointZSRID.coordinates.count == 2)
        #expect(multiPointZSRID.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0, altitude: 0))
        #expect(multiPointZSRID.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1, altitude: 1))
    }

    @Test
    func multiPointSRIDEncoding() async throws {
        let multiPointZSRID = try WKBCoder.decode(wkb: multiPointZSRIDData, sourceSrid: nil) as! MultiPoint
        let encodedMultiPointZSRID = WKBCoder.encode(geometry: multiPointZSRID, targetProjection: .epsg4326)
        #expect(encodedMultiPointZSRID == multiPointZSRIDData)
    }

    // MARK: - LineString

    // SELECT 'LINESTRING (1 1, 1 2, 1 3, 2 2)'::geometry;
    private let lineStringData = Data(hex: "010200000004000000000000000000F03F000000000000F03F000000000000F03F0000000000000040000000000000F03F000000000000084000000000000000400000000000000040")!
    // SELECT 'LINESTRING Z (1 1 5, 1 2 5, 1 3 5, 2 2 5)'::geometry;
    private let lineStringZData = Data(hex: "010200008004000000000000000000F03F000000000000F03F0000000000001440000000000000F03F00000000000000400000000000001440000000000000F03F00000000000008400000000000001440000000000000004000000000000000400000000000001440")!
    // SELECT 'LINESTRING M (1 1 0, 1 2 0, 1 3 1, 2 2 0)'::geometry;
    private let lineStringMData = Data(hex: "010200004004000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000400000000000000000000000000000F03F0000000000000840000000000000F03F000000000000004000000000000000400000000000000000")!
    // SELECT 'LINESTRING ZM (1 1 5 0, 1 2 5 0, 1 3 5 1, 2 2 5 0)'::geometry;
    private let lineStringZMData = Data(hex: "01020000C004000000000000000000F03F000000000000F03F00000000000014400000000000000000000000000000F03F000000000000004000000000000014400000000000000000000000000000F03F00000000000008400000000000001440000000000000F03F0000000000000040000000000000004000000000000014400000000000000000")!

    @Test
    func lineStringDecoding() async throws {
        let lineString = try WKBCoder.decode(wkb: lineStringData, sourceProjection: .epsg4326) as! LineString
        #expect(lineString.coordinates.count == 4)

        let lineStringZ = try WKBCoder.decode(wkb: lineStringZData, sourceProjection: .epsg4326) as! LineString
        #expect(lineStringZ.coordinates.count == 4)

        let lineStringM = try WKBCoder.decode(wkb: lineStringMData, sourceProjection: .epsg4326) as! LineString
        #expect(lineStringM.coordinates.count == 4)

        let lineStringZM = try WKBCoder.decode(wkb: lineStringZMData, sourceProjection: .epsg4326) as! LineString
        #expect(lineStringZM.coordinates.count == 4)
    }

    @Test
    func lineStringEncoding() async throws {
        let lineString = try WKBCoder.decode(wkb: lineStringData, sourceProjection: .epsg4326) as! LineString
        let encodedLineString = WKBCoder.encode(geometry: lineString, targetProjection: nil)
        #expect(encodedLineString == lineStringData)

        let lineStringZ = try WKBCoder.decode(wkb: lineStringZData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringZ = WKBCoder.encode(geometry: lineStringZ, targetProjection: nil)
        #expect(encodedLineStringZ == lineStringZData)

        let lineStringM = try WKBCoder.decode(wkb: lineStringMData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringM = WKBCoder.encode(geometry: lineStringM, targetProjection: nil)
        #expect(encodedLineStringM == lineStringMData)

        let lineStringZM = try WKBCoder.decode(wkb: lineStringZMData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringZM = WKBCoder.encode(geometry: lineStringZM, targetProjection: nil)
        #expect(encodedLineStringZM == lineStringZMData)
    }

    // MARK: - MultiLineString

    // SELECT 'MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))'::geometry;
    private let multiLineStringData = Data(hex: "01050000000200000001020000000300000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F0000000000000040010200000003000000000000000000004000000000000008400000000000000840000000000000004000000000000014400000000000001040")!

    @Test
    func multiLineStringDecoding() async throws {
        let multiLineString = try WKBCoder.decode(wkb: multiLineStringData, sourceProjection: .epsg4326) as! MultiLineString
        #expect(multiLineString.lineStrings.count == 2)
    }

    @Test
    func multiLineStringEncoding() async throws {
        let multiLineString = try WKBCoder.decode(wkb: multiLineStringData, sourceProjection: .epsg4326) as! MultiLineString
        let encodedMultiLineString = WKBCoder.encode(geometry: multiLineString, targetProjection: nil)
        #expect(encodedMultiLineString == multiLineStringData)
    }

    // MARK: - Polygon

    // SELECT 'POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))'::geometry;
    private let polygonData = Data(hex: "01030000000100000005000000000000000000000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F000000000000F03F000000000000000000000000000000000000000000000000")!
    // SELECT 'POLYGON Z ((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))'::geometry;
    private let polygonZData = Data(hex: "010300008001000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000000000000000000000000000000000000000000000000000000000000000000000")!
    // SELECT 'POLYGON M ((0 0 2, 0 1 2, 1 1 2, 1 0 2, 0 0 2))'::geometry;
    private let polygonMData = Data(hex: "010300004001000000050000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F0000000000000040000000000000F03F000000000000F03F0000000000000040000000000000F03F00000000000000000000000000000040000000000000000000000000000000000000000000000040")!
    // SELECT 'POLYGON ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 1 0 0 2, 0 0 0 2))'::geometry;
    private let polygonZMData = Data(hex: "01030000C0010000000500000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F00000000000000000000000000000040000000000000F03F000000000000F03F00000000000000000000000000000040000000000000F03F0000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000040")!
    // SELECT 'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 1 2, 2 2, 2 1, 1 1))'::geometry;
    private let polygonWithHoleData = Data(hex: "01030000000200000005000000000000000000000000000000000000000000000000002440000000000000000000000000000024400000000000002440000000000000000000000000000024400000000000000000000000000000000005000000000000000000F03F000000000000F03F000000000000F03F0000000000000040000000000000004000000000000000400000000000000040000000000000F03F000000000000F03F000000000000F03F")!

    @Test
    func polygonDecoding() async throws {
        let polygon = try WKBCoder.decode(wkb: polygonData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygon.rings.count == 1)
        #expect(polygon.outerRing!.coordinates.count == 5)

        let polygonZ = try WKBCoder.decode(wkb: polygonZData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonZ.rings.count == 1)
        #expect(polygonZ.outerRing!.coordinates.count == 5)

        let polygonM = try WKBCoder.decode(wkb: polygonMData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonM.rings.count == 1)
        #expect(polygonM.outerRing!.coordinates.count == 5)

        let polygonZM = try WKBCoder.decode(wkb: polygonZMData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonZM.rings.count == 1)
        #expect(polygonZM.outerRing!.coordinates.count == 5)

        let polygonWithHole = try WKBCoder.decode(wkb: polygonWithHoleData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonWithHole.rings.count == 2)
        #expect(polygonWithHole.outerRing!.coordinates.count == 5)
        #expect(polygonWithHole.innerRings![0].coordinates.count == 5)
    }

    @Test
    func polygonEncoding() async throws {
        let polygon = try WKBCoder.decode(wkb: polygonData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygon = WKBCoder.encode(geometry: polygon, targetProjection: nil)
        #expect(encodedPolygon == polygonData)

        let polygonZ = try WKBCoder.decode(wkb: polygonZData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonZ = WKBCoder.encode(geometry: polygonZ, targetProjection: nil)
        #expect(encodedPolygonZ == polygonZData)

        let polygonM = try WKBCoder.decode(wkb: polygonMData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonM = WKBCoder.encode(geometry: polygonM, targetProjection: nil)
        #expect(encodedPolygonM == polygonMData)

        let polygonZM = try WKBCoder.decode(wkb: polygonZMData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonZM = WKBCoder.encode(geometry: polygonZM, targetProjection: nil)
        #expect(encodedPolygonZM == polygonZMData)

        let polygonWithHole = try WKBCoder.decode(wkb: polygonWithHoleData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonWithHole = WKBCoder.encode(geometry: polygonWithHole, targetProjection: nil)
        #expect(encodedPolygonWithHole == polygonWithHoleData)
    }

    // MARK: - MultiPolygon

    // SELECT 'MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))'::geometry;
    private let multiPolygonData = Data(hex: "01060000000200000001030000000200000005000000000000000000000000000000000000000000000000001040000000000000000000000000000010400000000000001040000000000000000000000000000010400000000000000000000000000000000005000000000000000000F03F000000000000F03F0000000000000040000000000000F03F00000000000000400000000000000040000000000000F03F0000000000000040000000000000F03F000000000000F03F01030000000100000005000000000000000000F0BF000000000000F0BF000000000000F0BF00000000000000C000000000000000C000000000000000C000000000000000C0000000000000F0BF000000000000F0BF000000000000F0BF")!

    @Test
    func multiPolygonDecoding() async throws {
        let multiPolygon = try WKBCoder.decode(wkb: multiPolygonData, sourceProjection: .epsg4326) as! MultiPolygon
        #expect(multiPolygon.polygons.count == 2)
    }

    @Test
    func multiPolygonEncoding() async throws {
        let multiPolygon = try WKBCoder.decode(wkb: multiPolygonData, sourceProjection: .epsg4326) as! MultiPolygon
        let encodedMultiPolygon = WKBCoder.encode(geometry: multiPolygon, targetProjection: nil)
        #expect(encodedMultiPolygon == multiPolygonData)
    }

    // MARK: - GeometryCollection

    // SELECT 'GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))'::geometry;
    private let geometryCollectionData = Data(hex: "0107000000020000000101000000000000000000004000000000000000000103000000010000000500000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000000000000000000000")!

    @Test
    func geometryCollectionDecoding() async throws {
        let geometryCollection = try WKBCoder.decode(wkb: geometryCollectionData, sourceProjection: .epsg4326) as! GeometryCollection
        #expect(geometryCollection.geometries.count == 2)
        #expect(geometryCollection.geometries[0].type == .point)
        #expect(geometryCollection.geometries[1].type == .polygon)
    }

    @Test
    func geometryCollectionEncoding() async throws {
        let geometryCollection = try WKBCoder.decode(wkb: geometryCollectionData, sourceProjection: .epsg4326) as! GeometryCollection
        let encodedGeometryCollection = WKBCoder.encode(geometry: geometryCollection, targetProjection: nil)
        #expect(encodedGeometryCollection == geometryCollectionData)
    }

    // MARK: - Triangle

    // SELECT 'TRIANGLE((0 0, 0 1, 1 1, 0 0))'::geometry;
    private let triangleData = Data(hex: "01110000000100000004000000000000000000000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F00000000000000000000000000000000")!
    // SELECT 'TRIANGLE Z ((0 0 0, 0 1 0, 1 1 0, 0 0 0))'::geometry;
    private let triangleZData = Data(hex: "011100008001000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000000000000000000000000000000000000000")!
    // SELECT 'TRIANGLE M ((0 0 2, 0 1 2, 1 1 2, 0 0 2))'::geometry;
    private let triangleMData = Data(hex: "011100004001000000040000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F0000000000000040000000000000F03F000000000000F03F0000000000000040000000000000000000000000000000000000000000000040")!
    // SELECT 'TRIANGLE ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 0 0 0 2))'::geometry;
    private let triangleZMData = Data(hex: "01110000C0010000000400000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F00000000000000000000000000000040000000000000F03F000000000000F03F000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000040")!

    @Test
    func triangleDecoding() async throws {
        let triangle = try WKBCoder.decode(wkb: triangleData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangle.rings.count == 1)
        #expect(triangle.outerRing!.coordinates.count == 4)

        let triangleZ = try WKBCoder.decode(wkb: triangleZData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangleZ.rings.count == 1)
        #expect(triangleZ.outerRing!.coordinates.count == 4)

        let triangleM = try WKBCoder.decode(wkb: triangleMData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangleM.rings.count == 1)
        #expect(triangleM.outerRing!.coordinates.count == 4)

        let triangleZM = try WKBCoder.decode(wkb: triangleZMData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangleZM.rings.count == 1)
        #expect(triangleZM.outerRing!.coordinates.count == 4)
    }

}

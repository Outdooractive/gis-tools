@testable import GISTools
@testable import struct GISTools.Polygon
import XCTest

final class WKBTests: XCTestCase {

    // MARK: - Point

    // SELECT 'POINT(1 2)'::geometry;
    private let pointData = Data(hex: "0101000000000000000000F03F0000000000000040")!
    // SELECT 'POINT Z (1 2 3)'::geometry;
    private let pointZData = Data(hex: "0101000080000000000000F03F00000000000000400000000000000840")!
    // SELECT 'POINT M (1 2 4)'::geometry;
    private let pointMData = Data(hex: "0101000040000000000000F03F00000000000000400000000000001040")!
    // SELECT 'POINT ZM (1 2 3 4)'::geometry;
    private let pointZMData = Data(hex: "01010000C0000000000000F03F000000000000004000000000000008400000000000001040")!

    func testPointDecoding() throws {
        let point = try WKBCoder.decode(wkb: pointData, projection: .epsg4326) as! Point
        XCTAssertEqual(point.coordinate.longitude, 1)
        XCTAssertEqual(point.coordinate.latitude, 2)
        XCTAssertNil(point.coordinate.altitude)

        let pointZ = try WKBCoder.decode(wkb: pointZData, projection: .epsg4326) as! Point
        XCTAssertEqual(pointZ.coordinate.longitude, 1)
        XCTAssertEqual(pointZ.coordinate.latitude, 2)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)

        let pointM = try WKBCoder.decode(wkb: pointMData, projection: .epsg4326) as! Point
        XCTAssertEqual(pointM.coordinate.longitude, 1)
        XCTAssertEqual(pointM.coordinate.latitude, 2)
        XCTAssertEqual(pointM.coordinate.m, 4)
        XCTAssertNil(pointM.coordinate.altitude)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, projection: .epsg4326) as! Point
        XCTAssertEqual(pointZM.coordinate.longitude, 1)
        XCTAssertEqual(pointZM.coordinate.latitude, 2)
        XCTAssertEqual(pointZM.coordinate.altitude, 3)
        XCTAssertEqual(pointZM.coordinate.m, 4)
    }

    func testPointEncoding() throws {
        let point = try WKBCoder.decode(wkb: pointData, projection: .epsg4326) as! Point
        let encodedPoint = WKBCoder.encode(geometry: point, projection: nil)
        XCTAssertEqual(encodedPoint, pointData)

        let pointZ = try WKBCoder.decode(wkb: pointZData, projection: .epsg4326) as! Point
        let encodedPointZ = WKBCoder.encode(geometry: pointZ, projection: nil)
        XCTAssertEqual(encodedPointZ, pointZData)

        let pointM = try WKBCoder.decode(wkb: pointMData, projection: .epsg4326) as! Point
        let encodedPointM = WKBCoder.encode(geometry: pointM, projection: nil)
        XCTAssertEqual(encodedPointM, pointMData)

        let pointZM = try WKBCoder.decode(wkb: pointZMData, projection: .epsg4326) as! Point
        let encodedPointZM = WKBCoder.encode(geometry: pointZM, projection: nil)
        XCTAssertEqual(encodedPointZM, pointZMData)
    }

    func testPointConvenienceDecoding() throws {
        let pointZ = Point(wkb: pointZData, projection: .epsg4326)!
        XCTAssertEqual(pointZ.coordinate.longitude, 1)
        XCTAssertEqual(pointZ.coordinate.latitude, 2)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)
    }

    func testPointDataConvenienceDecoding() throws {
        let pointZ = pointZData.asGeoJsonGeometry(projection: .epsg4326) as! Point
        XCTAssertEqual(pointZ.coordinate.longitude, 1)
        XCTAssertEqual(pointZ.coordinate.latitude, 2)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)

        let feature = pointZData.asFeature(projection: .epsg4326)
        XCTAssertEqual(feature?.geometry.allCoordinates.first?.longitude, 1)
        XCTAssertEqual(feature?.geometry.allCoordinates.first?.latitude, 2)
        XCTAssertEqual(feature?.geometry.allCoordinates.first?.altitude, 3)
    }

    // MARK: - MultiPoint

    // SELECT 'MULTIPOINT((0 0),(1 2))'::geometry;
    private let multiPointData = Data(hex: "0104000000020000000101000000000000000000000000000000000000000101000000000000000000F03F0000000000000040")!

    func testMultiPointDecoding() throws {
        let multiPoint = try WKBCoder.decode(wkb: multiPointData, projection: .epsg4326) as! MultiPoint
        XCTAssertEqual(multiPoint.coordinates.count, 2)
        XCTAssertEqual(multiPoint.coordinates[0], Coordinate3D(latitude: 0, longitude: 0))
        XCTAssertEqual(multiPoint.coordinates[1], Coordinate3D(latitude: 2, longitude: 1))
    }

    func testMultiPointEncoding() throws {
        let multiPoint = try WKBCoder.decode(wkb: multiPointData, projection: .epsg4326) as! MultiPoint
        let encodedMultiPoint = WKBCoder.encode(geometry: multiPoint, projection: nil)
        XCTAssertEqual(encodedMultiPoint, multiPointData)
    }

    // MARK: - MultiPoint with SRID

    // SELECT 'SRID=4326;MULTIPOINTZ(0 0 0,1 2 1)'::geometry;
    private let multiPointZSRIDData = Data(hex: "01040000A0E61000000200000001010000800000000000000000000000000000000000000000000000000101000080000000000000F03F0000000000000040000000000000F03F")!

    func testMultiPointSRIDDecoding() throws {
        let multiPointZSRID = try WKBCoder.decode(wkb: multiPointZSRIDData, srid: nil) as! MultiPoint
        XCTAssertEqual(multiPointZSRID.coordinates.count, 2)
        XCTAssertEqual(multiPointZSRID.coordinates[0], Coordinate3D(latitude: 0, longitude: 0, altitude: 0))
        XCTAssertEqual(multiPointZSRID.coordinates[1], Coordinate3D(latitude: 2, longitude: 1, altitude: 1))
    }

    func testMultiPointSRIDEncoding() throws {
        let multiPointZSRID = try WKBCoder.decode(wkb: multiPointZSRIDData, srid: nil) as! MultiPoint
        let encodedMultiPointZSRID = WKBCoder.encode(geometry: multiPointZSRID, projection: .epsg4326)
        XCTAssertEqual(encodedMultiPointZSRID, multiPointZSRIDData)
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

    func testLineStringDecoding() throws {
        let lineString = try WKBCoder.decode(wkb: lineStringData, projection: .epsg4326) as! LineString
        XCTAssertEqual(lineString.coordinates.count, 4)

        let lineStringZ = try WKBCoder.decode(wkb: lineStringZData, projection: .epsg4326) as! LineString
        XCTAssertEqual(lineStringZ.coordinates.count, 4)

        let lineStringM = try WKBCoder.decode(wkb: lineStringMData, projection: .epsg4326) as! LineString
        XCTAssertEqual(lineStringM.coordinates.count, 4)

        let lineStringZM = try WKBCoder.decode(wkb: lineStringZMData, projection: .epsg4326) as! LineString
        XCTAssertEqual(lineStringZM.coordinates.count, 4)
    }

    func testLineStringEncoding() throws {
        let lineString = try WKBCoder.decode(wkb: lineStringData, projection: .epsg4326) as! LineString
        let encodedLineString = WKBCoder.encode(geometry: lineString, projection: nil)
        XCTAssertEqual(encodedLineString, lineStringData)

        let lineStringZ = try WKBCoder.decode(wkb: lineStringZData, projection: .epsg4326) as! LineString
        let encodedLineStringZ = WKBCoder.encode(geometry: lineStringZ, projection: nil)
        XCTAssertEqual(encodedLineStringZ, lineStringZData)

        let lineStringM = try WKBCoder.decode(wkb: lineStringMData, projection: .epsg4326) as! LineString
        let encodedLineStringM = WKBCoder.encode(geometry: lineStringM, projection: nil)
        XCTAssertEqual(encodedLineStringM, lineStringMData)

        let lineStringZM = try WKBCoder.decode(wkb: lineStringZMData, projection: .epsg4326) as! LineString
        let encodedLineStringZM = WKBCoder.encode(geometry: lineStringZM, projection: nil)
        XCTAssertEqual(encodedLineStringZM, lineStringZMData)
    }

    // MARK: - MultiLineString

    // SELECT 'MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))'::geometry;
    private let multiLineStringData = Data(hex: "01050000000200000001020000000300000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F0000000000000040010200000003000000000000000000004000000000000008400000000000000840000000000000004000000000000014400000000000001040")!

    func testMultiLineStringDecoding() throws {
        let multiLineString = try WKBCoder.decode(wkb: multiLineStringData, projection: .epsg4326) as! MultiLineString
        XCTAssertEqual(multiLineString.lineStrings.count, 2)
    }

    func testMultiLineStringEncoding() throws {
        let multiLineString = try WKBCoder.decode(wkb: multiLineStringData, projection: .epsg4326) as! MultiLineString
        let encodedMultiLineString = WKBCoder.encode(geometry: multiLineString, projection: nil)
        XCTAssertEqual(encodedMultiLineString, multiLineStringData)
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

    func testPolygonDecoding() throws {
        let polygon = try WKBCoder.decode(wkb: polygonData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(polygon.rings.count, 1)
        XCTAssertEqual(polygon.outerRing!.coordinates.count, 5)

        let polygonZ = try WKBCoder.decode(wkb: polygonZData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonZ.rings.count, 1)
        XCTAssertEqual(polygonZ.outerRing!.coordinates.count, 5)

        let polygonM = try WKBCoder.decode(wkb: polygonMData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonM.rings.count, 1)
        XCTAssertEqual(polygonM.outerRing!.coordinates.count, 5)

        let polygonZM = try WKBCoder.decode(wkb: polygonZMData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonZM.rings.count, 1)
        XCTAssertEqual(polygonZM.outerRing!.coordinates.count, 5)

        let polygonWithHole = try WKBCoder.decode(wkb: polygonWithHoleData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonWithHole.rings.count, 2)
        XCTAssertEqual(polygonWithHole.outerRing!.coordinates.count, 5)
        XCTAssertEqual(polygonWithHole.innerRings![0].coordinates.count, 5)
    }

    func testPolygonEncoding() throws {
        let polygon = try WKBCoder.decode(wkb: polygonData, projection: .epsg4326) as! Polygon
        let encodedPolygon = WKBCoder.encode(geometry: polygon, projection: nil)
        XCTAssertEqual(encodedPolygon, polygonData)

        let polygonZ = try WKBCoder.decode(wkb: polygonZData, projection: .epsg4326) as! Polygon
        let encodedPolygonZ = WKBCoder.encode(geometry: polygonZ, projection: nil)
        XCTAssertEqual(encodedPolygonZ, polygonZData)

        let polygonM = try WKBCoder.decode(wkb: polygonMData, projection: .epsg4326) as! Polygon
        let encodedPolygonM = WKBCoder.encode(geometry: polygonM, projection: nil)
        XCTAssertEqual(encodedPolygonM, polygonMData)

        let polygonZM = try WKBCoder.decode(wkb: polygonZMData, projection: .epsg4326) as! Polygon
        let encodedPolygonZM = WKBCoder.encode(geometry: polygonZM, projection: nil)
        XCTAssertEqual(encodedPolygonZM, polygonZMData)

        let polygonWithHole = try WKBCoder.decode(wkb: polygonWithHoleData, projection: .epsg4326) as! Polygon
        let encodedPolygonWithHole = WKBCoder.encode(geometry: polygonWithHole, projection: nil)
        XCTAssertEqual(encodedPolygonWithHole, polygonWithHoleData)
    }

    // MARK: - MultiPolygon

    // SELECT 'MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))'::geometry;
    private let multiPolygonData = Data(hex: "01060000000200000001030000000200000005000000000000000000000000000000000000000000000000001040000000000000000000000000000010400000000000001040000000000000000000000000000010400000000000000000000000000000000005000000000000000000F03F000000000000F03F0000000000000040000000000000F03F00000000000000400000000000000040000000000000F03F0000000000000040000000000000F03F000000000000F03F01030000000100000005000000000000000000F0BF000000000000F0BF000000000000F0BF00000000000000C000000000000000C000000000000000C000000000000000C0000000000000F0BF000000000000F0BF000000000000F0BF")!

    func testMultiPolygonDecoding() throws {
        let multiPolygon = try WKBCoder.decode(wkb: multiPolygonData, projection: .epsg4326) as! MultiPolygon
        XCTAssertEqual(multiPolygon.polygons.count, 2)
    }

    func testMultiPolygonEncoding() throws {
        let multiPolygon = try WKBCoder.decode(wkb: multiPolygonData, projection: .epsg4326) as! MultiPolygon
        let encodedMultiPolygon = WKBCoder.encode(geometry: multiPolygon, projection: nil)
        XCTAssertEqual(encodedMultiPolygon, multiPolygonData)
    }

    // MARK: - GeometryCollection

    // SELECT 'GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))'::geometry;
    private let geometryCollectionData = Data(hex: "0107000000020000000101000000000000000000004000000000000000000103000000010000000500000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000000000000000000000")!

    func testGeometryCollectionDecoding() throws {
        let geometryCollection = try WKBCoder.decode(wkb: geometryCollectionData, projection: .epsg4326) as! GeometryCollection
        XCTAssertEqual(geometryCollection.geometries.count, 2)
        XCTAssertEqual(geometryCollection.geometries[0].type, .point)
        XCTAssertEqual(geometryCollection.geometries[1].type, .polygon)
    }

    func testGeometryCollectionEncoding() throws {
        let geometryCollection = try WKBCoder.decode(wkb: geometryCollectionData, projection: .epsg4326) as! GeometryCollection
        let encodedGeometryCollection = WKBCoder.encode(geometry: geometryCollection, projection: nil)
        XCTAssertEqual(encodedGeometryCollection, geometryCollectionData)
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

    func testTriangleDecoding() throws {
        let triangle = try WKBCoder.decode(wkb: triangleData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(triangle.rings.count, 1)
        XCTAssertEqual(triangle.outerRing!.coordinates.count, 4)

        let triangleZ = try WKBCoder.decode(wkb: triangleZData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(triangleZ.rings.count, 1)
        XCTAssertEqual(triangleZ.outerRing!.coordinates.count, 4)

        let triangleM = try WKBCoder.decode(wkb: triangleMData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(triangleM.rings.count, 1)
        XCTAssertEqual(triangleM.outerRing!.coordinates.count, 4)

        let triangleZM = try WKBCoder.decode(wkb: triangleZMData, projection: .epsg4326) as! Polygon
        XCTAssertEqual(triangleZM.rings.count, 1)
        XCTAssertEqual(triangleZM.outerRing!.coordinates.count, 4)
    }

}

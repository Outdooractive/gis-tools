@testable import GISTools
@testable import struct GISTools.Polygon
import XCTest

final class WKTTests: XCTestCase {

    // MARK: - Point

    private let pointData = "POINT(1 2)"
    private let pointZData = "POINT Z (1 2 3)"
    private let pointMData = "POINT M (1 2 4)"
    private let pointZMData = "POINTZM(1 2 3 4)"

    func testPointDecoding() throws {
        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as! Point
        XCTAssertEqual(point.coordinate.longitude, 1)
        XCTAssertEqual(point.coordinate.latitude, 2)
        XCTAssertNil(point.coordinate.altitude)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326) as! Point
        XCTAssertEqual(pointZ.coordinate.longitude, 1)
        XCTAssertEqual(pointZ.coordinate.latitude, 2)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326) as! Point
        XCTAssertEqual(pointM.coordinate.longitude, 1)
        XCTAssertEqual(pointM.coordinate.latitude, 2)
        XCTAssertEqual(pointM.coordinate.m, 4)
        XCTAssertNil(pointM.coordinate.altitude)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326) as! Point
        XCTAssertEqual(pointZM.coordinate.longitude, 1)
        XCTAssertEqual(pointZM.coordinate.latitude, 2)
        XCTAssertEqual(pointZM.coordinate.altitude, 3)
        XCTAssertEqual(pointZM.coordinate.m, 4)
    }

    func testPointDecoding4326To3857() throws {
        let expected = Coordinate3D(latitude: 2, longitude: 1).projected(to: .epsg3857)

        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        XCTAssertEqual(point.coordinate.x, expected.x)
        XCTAssertEqual(point.coordinate.y, expected.y)
        XCTAssertNil(point.coordinate.altitude)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        XCTAssertEqual(pointZ.coordinate.x, expected.x)
        XCTAssertEqual(pointZ.coordinate.y, expected.y)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        XCTAssertEqual(pointM.coordinate.x, expected.x)
        XCTAssertEqual(pointM.coordinate.y, expected.y)
        XCTAssertEqual(pointM.coordinate.m, 4)
        XCTAssertNil(pointM.coordinate.altitude)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        XCTAssertEqual(pointZM.coordinate.x, expected.x)
        XCTAssertEqual(pointZM.coordinate.y, expected.y)
        XCTAssertEqual(pointZM.coordinate.altitude, 3)
        XCTAssertEqual(pointZM.coordinate.m, 4)
    }

    func testPointDecoding3857To4326() throws {
        let expected = Coordinate3D(x: 1, y: 2).projected(to: .epsg4326)

        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        XCTAssertEqual(point.coordinate.longitude, expected.longitude)
        XCTAssertEqual(point.coordinate.latitude, expected.latitude)
        XCTAssertNil(point.coordinate.altitude)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        XCTAssertEqual(pointZ.coordinate.x, expected.x)
        XCTAssertEqual(pointZ.coordinate.y, expected.y)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        XCTAssertEqual(pointM.coordinate.x, expected.x)
        XCTAssertEqual(pointM.coordinate.y, expected.y)
        XCTAssertEqual(pointM.coordinate.m, 4)
        XCTAssertNil(pointM.coordinate.altitude)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        XCTAssertEqual(pointZM.coordinate.x, expected.x)
        XCTAssertEqual(pointZM.coordinate.y, expected.y)
        XCTAssertEqual(pointZM.coordinate.altitude, 3)
        XCTAssertEqual(pointZM.coordinate.m, 4)
    }

    func testPointDecodingNoSRID() throws {
        let expected = Coordinate3D(x: 1, y: 2, projection: .noSRID)

        XCTAssertThrowsError(try WKTCoder.decode(wkt: pointData, sourceProjection: .noSRID) as! Point)

        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        XCTAssertEqual(point.coordinate.x, expected.x)
        XCTAssertEqual(point.coordinate.y, expected.y)
        XCTAssertNil(point.coordinate.altitude)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        XCTAssertEqual(pointZ.coordinate.x, expected.x)
        XCTAssertEqual(pointZ.coordinate.y, expected.y)
        XCTAssertEqual(pointZ.coordinate.altitude, 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        XCTAssertEqual(pointM.coordinate.x, expected.x)
        XCTAssertEqual(pointM.coordinate.y, expected.y)
        XCTAssertEqual(pointM.coordinate.m, 4)
        XCTAssertNil(pointM.coordinate.altitude)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        XCTAssertEqual(pointZM.coordinate.x, expected.x)
        XCTAssertEqual(pointZM.coordinate.y, expected.y)
        XCTAssertEqual(pointZM.coordinate.altitude, 3)
        XCTAssertEqual(pointZM.coordinate.m, 4)
    }

    func testPointEncoding() throws {
        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as! Point
        let encodedPoint = WKTCoder.encode(geometry: point, targetProjection: nil)
        XCTAssertEqual(encodedPoint, "POINT(1.0 2.0)")

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326) as! Point
        let encodedPointZ = WKTCoder.encode(geometry: pointZ, targetProjection: nil)
        XCTAssertEqual(encodedPointZ, "POINTZ(1.0 2.0 3.0)")

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326) as! Point
        let encodedPointM = WKTCoder.encode(geometry: pointM, targetProjection: nil)
        XCTAssertEqual(encodedPointM, "POINTM(1.0 2.0 4.0)")

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326) as! Point
        let encodedPointZM = WKTCoder.encode(geometry: pointZM, targetProjection: nil)
        XCTAssertEqual(encodedPointZM, "POINTZM(1.0 2.0 3.0 4.0)")
    }

    func testPointEncodingWithProjections() throws {
        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as! Point
        let encodedPoint = WKTCoder.encode(geometry: point, targetProjection: .epsg4326)
        XCTAssertEqual(encodedPoint, "SRID=4326;POINT(\(point.coordinate.x) \(point.coordinate.y))")

        let expected = Coordinate3D(latitude: 2, longitude: 1).projected(to: .epsg3857)
        let encodedPoint3857 = WKTCoder.encode(geometry: point, targetProjection: .epsg3857)
        XCTAssertEqual(encodedPoint3857, "SRID=3857;POINT(\(expected.x) \(expected.y))")

        let encodedPointNoSRID = WKTCoder.encode(geometry: point, targetProjection: .noSRID)
        XCTAssertEqual(encodedPointNoSRID, "SRID=0;POINT(\(point.coordinate.x) \(point.coordinate.y))")
    }

    // MARK: - MultiPoint

    private let multiPointData = "MULTIPOINT((0 0),(1 2))"

    func testMultiPointDecoding() throws {
        let multiPoint = try WKTCoder.decode(wkt: multiPointData, sourceProjection: .epsg4326) as! MultiPoint
        XCTAssertEqual(multiPoint.coordinates.count, 2)
        XCTAssertEqual(multiPoint.coordinates[0], Coordinate3D(latitude: 0, longitude: 0))
        XCTAssertEqual(multiPoint.coordinates[1], Coordinate3D(latitude: 2, longitude: 1))
    }

    func testMultiPointEncoding() throws {
        let multiPoint = try WKTCoder.decode(wkt: multiPointData, sourceProjection: .epsg4326) as! MultiPoint
        let encodedMultiPoint = WKTCoder.encode(geometry: multiPoint, targetProjection: nil)
        XCTAssertEqual(encodedMultiPoint, "MULTIPOINT(0.0 0.0,1.0 2.0)")
    }

    // MARK: - MultiPoint with SRID

    private let multiPointZSRIDData = "SRID=4326;MULTIPOINTZ(0 0 0,1 2 1)"

    func testMultiPointSRIDDecoding() throws {
        let multiPointZSRID = try WKTCoder.decode(wkt: multiPointZSRIDData, sourceSrid: nil) as! MultiPoint
        XCTAssertEqual(multiPointZSRID.coordinates.count, 2)
        XCTAssertEqual(multiPointZSRID.coordinates[0], Coordinate3D(latitude: 0, longitude: 0, altitude: 0))
        XCTAssertEqual(multiPointZSRID.coordinates[1], Coordinate3D(latitude: 2, longitude: 1, altitude: 1))
    }

    func testMultiPointSRIDEncoding() throws {
        let multiPointZSRID = try WKTCoder.decode(wkt: multiPointZSRIDData, sourceSrid: nil) as! MultiPoint
        let encodedMultiPointZSRID = WKTCoder.encode(geometry: multiPointZSRID, targetProjection: .epsg4326)
        XCTAssertEqual(encodedMultiPointZSRID, "SRID=4326;MULTIPOINTZ(0.0 0.0 0.0,1.0 2.0 1.0)")
    }

    // MARK: - LineString

    private let lineStringData = "LINESTRING (1 1, 1 2, 1 3, 2 2)"
    private let lineStringZData = "LINESTRING Z (1 1 5, 1 2 5, 1 3 5, 2 2 5)"
    private let lineStringMData = "LINESTRING M (1 1 0, 1 2 0, 1 3 1, 2 2 0)"
    private let lineStringZMData = "LINESTRING ZM (1 1 5 0, 1 2 5 0, 1 3 5 1, 2 2 5 0)"
    private let linearRingZData = "LINEARRING (0 0 0, 4 0 0, 4 4 0, 0 4 0, 0 0 0)"

    func testLineStringDecoding() throws {
        let lineString = try WKTCoder.decode(wkt: lineStringData, sourceProjection: .epsg4326) as! LineString
        XCTAssertEqual(lineString.coordinates.count, 4)

        let lineStringZ = try WKTCoder.decode(wkt: lineStringZData, sourceProjection: .epsg4326) as! LineString
        XCTAssertEqual(lineStringZ.coordinates.count, 4)

        let lineStringM = try WKTCoder.decode(wkt: lineStringMData, sourceProjection: .epsg4326) as! LineString
        XCTAssertEqual(lineStringM.coordinates.count, 4)

        let lineStringZM = try WKTCoder.decode(wkt: lineStringZMData, sourceProjection: .epsg4326) as! LineString
        XCTAssertEqual(lineStringZM.coordinates.count, 4)

        let linearRingZ = try WKTCoder.decode(wkt: linearRingZData, sourceProjection: .epsg4326) as! LineString
        XCTAssertEqual(linearRingZ.coordinates.count, 5)
    }

    func testLineStringEncoding() throws {
        let lineString = try WKTCoder.decode(wkt: lineStringData, sourceProjection: .epsg4326) as! LineString
        let encodedLineString = WKTCoder.encode(geometry: lineString, targetProjection: nil)
        XCTAssertEqual(encodedLineString, "LINESTRING(1.0 1.0,1.0 2.0,1.0 3.0,2.0 2.0)")

        let lineStringZ = try WKTCoder.decode(wkt: lineStringZData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringZ = WKTCoder.encode(geometry: lineStringZ, targetProjection: nil)
        XCTAssertEqual(encodedLineStringZ, "LINESTRINGZ(1.0 1.0 5.0,1.0 2.0 5.0,1.0 3.0 5.0,2.0 2.0 5.0)")

        let lineStringM = try WKTCoder.decode(wkt: lineStringMData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringM = WKTCoder.encode(geometry: lineStringM, targetProjection: nil)
        XCTAssertEqual(encodedLineStringM, "LINESTRINGM(1.0 1.0 0.0,1.0 2.0 0.0,1.0 3.0 1.0,2.0 2.0 0.0)")

        let lineStringZM = try WKTCoder.decode(wkt: lineStringZMData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringZM = WKTCoder.encode(geometry: lineStringZM, targetProjection: nil)
        XCTAssertEqual(encodedLineStringZM, "LINESTRINGZM(1.0 1.0 5.0 0.0,1.0 2.0 5.0 0.0,1.0 3.0 5.0 1.0,2.0 2.0 5.0 0.0)")
    }

    // MARK: - MultiLineString

    private let multiLineStringData = "MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))"

    func testMultiLineStringDecoding() throws {
        let multiLineString = try WKTCoder.decode(wkt: multiLineStringData, sourceProjection: .epsg4326) as! MultiLineString
        XCTAssertEqual(multiLineString.lineStrings.count, 2)
    }

    func testMultiLineStringEncoding() throws {
        let multiLineString = try WKTCoder.decode(wkt: multiLineStringData, sourceProjection: .epsg4326) as! MultiLineString
        let encodedMultiLineString = WKTCoder.encode(geometry: multiLineString, targetProjection: nil)
        XCTAssertEqual(encodedMultiLineString, "MULTILINESTRING((0.0 0.0,1.0 1.0,1.0 2.0),(2.0 3.0,3.0 2.0,5.0 4.0))")
    }

    // MARK: - Polygon

    private let polygonData = "POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))"
    private let polygonZData = "POLYGON Z ((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))"
    private let polygonMData = "POLYGON M ((0 0 2, 0 1 2, 1 1 2, 1 0 2, 0 0 2))"
    private let polygonZMData = "POLYGON ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 1 0 0 2, 0 0 0 2))"
    private let polygonWithHoleData = "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 1 2, 2 2, 2 1, 1 1))"

    func testPolygonDecoding() throws {
        let polygon = try WKTCoder.decode(wkt: polygonData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(polygon.rings.count, 1)
        XCTAssertEqual(polygon.outerRing!.coordinates.count, 5)

        let polygonZ = try WKTCoder.decode(wkt: polygonZData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonZ.rings.count, 1)
        XCTAssertEqual(polygonZ.outerRing!.coordinates.count, 5)

        let polygonM = try WKTCoder.decode(wkt: polygonMData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonM.rings.count, 1)
        XCTAssertEqual(polygonM.outerRing!.coordinates.count, 5)

        let polygonZM = try WKTCoder.decode(wkt: polygonZMData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonZM.rings.count, 1)
        XCTAssertEqual(polygonZM.outerRing!.coordinates.count, 5)

        let polygonWithHole = try WKTCoder.decode(wkt: polygonWithHoleData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(polygonWithHole.rings.count, 2)
        XCTAssertEqual(polygonWithHole.outerRing!.coordinates.count, 5)
        XCTAssertEqual(polygonWithHole.innerRings![0].coordinates.count, 5)
    }

    func testPolygonEncoding() throws {
        let polygon = try WKTCoder.decode(wkt: polygonData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygon = WKTCoder.encode(geometry: polygon, targetProjection: nil)
        XCTAssertEqual(encodedPolygon, "POLYGON((0.0 0.0,0.0 1.0,1.0 1.0,1.0 0.0,0.0 0.0))")

        let polygonZ = try WKTCoder.decode(wkt: polygonZData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonZ = WKTCoder.encode(geometry: polygonZ, targetProjection: nil)
        XCTAssertEqual(encodedPolygonZ, "POLYGONZ((0.0 0.0 0.0,0.0 1.0 0.0,1.0 1.0 0.0,1.0 0.0 0.0,0.0 0.0 0.0))")

        let polygonM = try WKTCoder.decode(wkt: polygonMData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonM = WKTCoder.encode(geometry: polygonM, targetProjection: nil)
        XCTAssertEqual(encodedPolygonM, "POLYGONM((0.0 0.0 2.0,0.0 1.0 2.0,1.0 1.0 2.0,1.0 0.0 2.0,0.0 0.0 2.0))")

        let polygonZM = try WKTCoder.decode(wkt: polygonZMData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonZM = WKTCoder.encode(geometry: polygonZM, targetProjection: nil)
        XCTAssertEqual(encodedPolygonZM, "POLYGONZM((0.0 0.0 0.0 2.0,0.0 1.0 0.0 2.0,1.0 1.0 0.0 2.0,1.0 0.0 0.0 2.0,0.0 0.0 0.0 2.0))")

        let polygonWithHole = try WKTCoder.decode(wkt: polygonWithHoleData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonWithHole = WKTCoder.encode(geometry: polygonWithHole, targetProjection: nil)
        XCTAssertEqual(encodedPolygonWithHole, "POLYGON((0.0 0.0,10.0 0.0,10.0 10.0,0.0 10.0,0.0 0.0),(1.0 1.0,1.0 2.0,2.0 2.0,2.0 1.0,1.0 1.0))")
    }

    // MARK: - MultiPolygon

    private let multiPolygonData = "MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))"

    func testMultiPolygonDecoding() throws {
        let multiPolygon = try WKTCoder.decode(wkt: multiPolygonData, sourceProjection: .epsg4326) as! MultiPolygon
        XCTAssertEqual(multiPolygon.polygons.count, 2)
    }

    func testMultiPolygonEncoding() throws {
        let multiPolygon = try WKTCoder.decode(wkt: multiPolygonData, sourceProjection: .epsg4326) as! MultiPolygon
        let encodedMultiPolygon = WKTCoder.encode(geometry: multiPolygon, targetProjection: nil)
        XCTAssertEqual(encodedMultiPolygon, "MULTIPOLYGON(((0.0 0.0,4.0 0.0,4.0 4.0,0.0 4.0,0.0 0.0),(1.0 1.0,2.0 1.0,2.0 2.0,1.0 2.0,1.0 1.0)),((-1.0 -1.0,-1.0 -2.0,-2.0 -2.0,-2.0 -1.0,-1.0 -1.0)))")
    }

    // MARK: - GeometryCollection

    private let geometryCollectionData = "GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))"

    func testGeometryCollectionDecoding() throws {
        let geometryCollection = try WKTCoder.decode(wkt: geometryCollectionData, sourceProjection: .epsg4326) as! GeometryCollection
        XCTAssertEqual(geometryCollection.geometries.count, 2)
        XCTAssertEqual(geometryCollection.geometries[0].type, .point)
        XCTAssertEqual(geometryCollection.geometries[1].type, .polygon)
    }

    func testGeometryCollectionEncoding() throws {
        let geometryCollection = try WKTCoder.decode(wkt: geometryCollectionData, sourceProjection: .epsg4326) as! GeometryCollection
        let encodedGeometryCollection = WKTCoder.encode(geometry: geometryCollection, targetProjection: nil)
        XCTAssertEqual(encodedGeometryCollection, "GEOMETRYCOLLECTION(POINT(2.0 0.0),POLYGON((0.0 0.0,1.0 0.0,1.0 1.0,0.0 1.0,0.0 0.0)))")
    }

    // MARK: - Triangle

    private let triangleData = "TRIANGLE((0 0, 0 1, 1 1, 0 0))"
    private let triangleZData = "TRIANGLE Z ((0 0 0, 0 1 0, 1 1 0, 0 0 0))"
    private let triangleMData = "TRIANGLE M ((0 0 2, 0 1 2, 1 1 2, 0 0 2))"
    private let triangleZMData = "TRIANGLE ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 0 0 0 2))"

    func testTriangleDecoding() throws {
        let triangle = try WKTCoder.decode(wkt: triangleData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(triangle.rings.count, 1)
        XCTAssertEqual(triangle.outerRing!.coordinates.count, 4)

        let triangleZ = try WKTCoder.decode(wkt: triangleZData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(triangleZ.rings.count, 1)
        XCTAssertEqual(triangleZ.outerRing!.coordinates.count, 4)

        let triangleM = try WKTCoder.decode(wkt: triangleMData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(triangleM.rings.count, 1)
        XCTAssertEqual(triangleM.outerRing!.coordinates.count, 4)

        let triangleZM = try WKTCoder.decode(wkt: triangleZMData, sourceProjection: .epsg4326) as! Polygon
        XCTAssertEqual(triangleZM.rings.count, 1)
        XCTAssertEqual(triangleZM.outerRing!.coordinates.count, 4)
    }

}

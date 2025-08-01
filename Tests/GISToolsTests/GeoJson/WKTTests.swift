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

    @Test
    func pointDecoding() async throws {
        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as! Point
        #expect(point.coordinate.longitude == 1)
        #expect(point.coordinate.latitude == 2)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326) as! Point
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326) as! Point
        #expect(pointM.coordinate.longitude == 1)
        #expect(pointM.coordinate.latitude == 2)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326) as! Point
        #expect(pointZM.coordinate.longitude == 1)
        #expect(pointZM.coordinate.latitude == 2)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointDecoding4326To3857() async throws {
        let expected = Coordinate3D(latitude: 2, longitude: 1).projected(to: .epsg3857)

        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(point.coordinate.x == expected.x)
        #expect(point.coordinate.y == expected.y)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as! Point
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointDecoding3857To4326() async throws {
        let expected = Coordinate3D(x: 1, y: 2).projected(to: .epsg4326)

        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(point.coordinate.longitude == expected.longitude)
        #expect(point.coordinate.latitude == expected.latitude)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as! Point
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointDecodingNoSRID() async throws {
        let expected = Coordinate3D(x: 1, y: 2, projection: .noSRID)

        #expect(throws: WKTCoder.WKTCoderError.self) {
            try WKTCoder.decode(wkt: pointData, sourceProjection: .noSRID) as! Point
        }

        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(point.coordinate.x == expected.x)
        #expect(point.coordinate.y == expected.y)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .noSRID, targetProjection: .noSRID) as! Point
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    @Test
    func pointEncoding() async throws {
        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as! Point
        let encodedPoint = WKTCoder.encode(geometry: point, targetProjection: nil)
        #expect(encodedPoint == "POINT(1.0 2.0)")

        let pointZ = try WKTCoder.decode(wkt: pointZData, sourceProjection: .epsg4326) as! Point
        let encodedPointZ = WKTCoder.encode(geometry: pointZ, targetProjection: nil)
        #expect(encodedPointZ == "POINTZ(1.0 2.0 3.0)")

        let pointM = try WKTCoder.decode(wkt: pointMData, sourceProjection: .epsg4326) as! Point
        let encodedPointM = WKTCoder.encode(geometry: pointM, targetProjection: nil)
        #expect(encodedPointM == "POINTM(1.0 2.0 4.0)")

        let pointZM = try WKTCoder.decode(wkt: pointZMData, sourceProjection: .epsg4326) as! Point
        let encodedPointZM = WKTCoder.encode(geometry: pointZM, targetProjection: nil)
        #expect(encodedPointZM == "POINTZM(1.0 2.0 3.0 4.0)")
    }

    @Test
    func pointEncodingWithProjections() async throws {
        let point = try WKTCoder.decode(wkt: pointData, sourceProjection: .epsg4326) as! Point
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

    @Test
    func multiPointDecoding() async throws {
        let multiPoint = try WKTCoder.decode(wkt: multiPointData, sourceProjection: .epsg4326) as! MultiPoint
        #expect(multiPoint.coordinates.count == 2)
        #expect(multiPoint.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0))
        #expect(multiPoint.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1))
    }

    @Test
    func multiPointEncoding() async throws {
        let multiPoint = try WKTCoder.decode(wkt: multiPointData, sourceProjection: .epsg4326) as! MultiPoint
        let encodedMultiPoint = WKTCoder.encode(geometry: multiPoint, targetProjection: nil)
        #expect(encodedMultiPoint == "MULTIPOINT(0.0 0.0,1.0 2.0)")
    }

    // MARK: - MultiPoint with SRID

    private let multiPointZSRIDData = "SRID=4326;MULTIPOINTZ(0 0 0,1 2 1)"

    @Test
    func multiPointSRIDDecoding() async throws {
        let multiPointZSRID = try WKTCoder.decode(wkt: multiPointZSRIDData, sourceSrid: nil) as! MultiPoint
        #expect(multiPointZSRID.coordinates.count == 2)
        #expect(multiPointZSRID.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0, altitude: 0))
        #expect(multiPointZSRID.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1, altitude: 1))
    }

    @Test
    func multiPointSRIDEncoding() async throws {
        let multiPointZSRID = try WKTCoder.decode(wkt: multiPointZSRIDData, sourceSrid: nil) as! MultiPoint
        let encodedMultiPointZSRID = WKTCoder.encode(geometry: multiPointZSRID, targetProjection: .epsg4326)
        #expect(encodedMultiPointZSRID == "SRID=4326;MULTIPOINTZ(0.0 0.0 0.0,1.0 2.0 1.0)")
    }

    // MARK: - LineString

    private let lineStringData = "LINESTRING (1 1, 1 2, 1 3, 2 2)"
    private let lineStringZData = "LINESTRING Z (1 1 5, 1 2 5, 1 3 5, 2 2 5)"
    private let lineStringMData = "LINESTRING M (1 1 0, 1 2 0, 1 3 1, 2 2 0)"
    private let lineStringZMData = "LINESTRING ZM (1 1 5 0, 1 2 5 0, 1 3 5 1, 2 2 5 0)"
    private let linearRingZData = "LINEARRING (0 0 0, 4 0 0, 4 4 0, 0 4 0, 0 0 0)"

    @Test
    func lineStringDecoding() async throws {
        let lineString = try WKTCoder.decode(wkt: lineStringData, sourceProjection: .epsg4326) as! LineString
        #expect(lineString.coordinates.count == 4)

        let lineStringZ = try WKTCoder.decode(wkt: lineStringZData, sourceProjection: .epsg4326) as! LineString
        #expect(lineStringZ.coordinates.count == 4)

        let lineStringM = try WKTCoder.decode(wkt: lineStringMData, sourceProjection: .epsg4326) as! LineString
        #expect(lineStringM.coordinates.count == 4)

        let lineStringZM = try WKTCoder.decode(wkt: lineStringZMData, sourceProjection: .epsg4326) as! LineString
        #expect(lineStringZM.coordinates.count == 4)

        let linearRingZ = try WKTCoder.decode(wkt: linearRingZData, sourceProjection: .epsg4326) as! LineString
        #expect(linearRingZ.coordinates.count == 5)
    }

    @Test
    func lineStringEncoding() async throws {
        let lineString = try WKTCoder.decode(wkt: lineStringData, sourceProjection: .epsg4326) as! LineString
        let encodedLineString = WKTCoder.encode(geometry: lineString, targetProjection: nil)
        #expect(encodedLineString == "LINESTRING(1.0 1.0,1.0 2.0,1.0 3.0,2.0 2.0)")

        let lineStringZ = try WKTCoder.decode(wkt: lineStringZData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringZ = WKTCoder.encode(geometry: lineStringZ, targetProjection: nil)
        #expect(encodedLineStringZ == "LINESTRINGZ(1.0 1.0 5.0,1.0 2.0 5.0,1.0 3.0 5.0,2.0 2.0 5.0)")

        let lineStringM = try WKTCoder.decode(wkt: lineStringMData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringM = WKTCoder.encode(geometry: lineStringM, targetProjection: nil)
        #expect(encodedLineStringM == "LINESTRINGM(1.0 1.0 0.0,1.0 2.0 0.0,1.0 3.0 1.0,2.0 2.0 0.0)")

        let lineStringZM = try WKTCoder.decode(wkt: lineStringZMData, sourceProjection: .epsg4326) as! LineString
        let encodedLineStringZM = WKTCoder.encode(geometry: lineStringZM, targetProjection: nil)
        #expect(encodedLineStringZM == "LINESTRINGZM(1.0 1.0 5.0 0.0,1.0 2.0 5.0 0.0,1.0 3.0 5.0 1.0,2.0 2.0 5.0 0.0)")
    }

    // MARK: - MultiLineString

    private let multiLineStringData = "MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))"

    @Test
    func multiLineStringDecoding() async throws {
        let multiLineString = try WKTCoder.decode(wkt: multiLineStringData, sourceProjection: .epsg4326) as! MultiLineString
        #expect(multiLineString.lineStrings.count == 2)
    }

    @Test
    func multiLineStringEncoding() async throws {
        let multiLineString = try WKTCoder.decode(wkt: multiLineStringData, sourceProjection: .epsg4326) as! MultiLineString
        let encodedMultiLineString = WKTCoder.encode(geometry: multiLineString, targetProjection: nil)
        #expect(encodedMultiLineString == "MULTILINESTRING((0.0 0.0,1.0 1.0,1.0 2.0),(2.0 3.0,3.0 2.0,5.0 4.0))")
    }

    // MARK: - Polygon

    private let polygonData = "POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))"
    private let polygonZData = "POLYGON Z ((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))"
    private let polygonMData = "POLYGON M ((0 0 2, 0 1 2, 1 1 2, 1 0 2, 0 0 2))"
    private let polygonZMData = "POLYGON ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 1 0 0 2, 0 0 0 2))"
    private let polygonWithHoleData = "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 1 2, 2 2, 2 1, 1 1))"

    @Test
    func polygonDecoding() async throws {
        let polygon = try WKTCoder.decode(wkt: polygonData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygon.rings.count == 1)
        #expect(polygon.outerRing!.coordinates.count == 5)

        let polygonZ = try WKTCoder.decode(wkt: polygonZData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonZ.rings.count == 1)
        #expect(polygonZ.outerRing!.coordinates.count == 5)

        let polygonM = try WKTCoder.decode(wkt: polygonMData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonM.rings.count == 1)
        #expect(polygonM.outerRing!.coordinates.count == 5)

        let polygonZM = try WKTCoder.decode(wkt: polygonZMData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonZM.rings.count == 1)
        #expect(polygonZM.outerRing!.coordinates.count == 5)

        let polygonWithHole = try WKTCoder.decode(wkt: polygonWithHoleData, sourceProjection: .epsg4326) as! Polygon
        #expect(polygonWithHole.rings.count == 2)
        #expect(polygonWithHole.outerRing!.coordinates.count == 5)
        #expect(polygonWithHole.innerRings![0].coordinates.count == 5)
    }

    @Test
    func polygonEncoding() async throws {
        let polygon = try WKTCoder.decode(wkt: polygonData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygon = WKTCoder.encode(geometry: polygon, targetProjection: nil)
        #expect(encodedPolygon == "POLYGON((0.0 0.0,0.0 1.0,1.0 1.0,1.0 0.0,0.0 0.0))")

        let polygonZ = try WKTCoder.decode(wkt: polygonZData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonZ = WKTCoder.encode(geometry: polygonZ, targetProjection: nil)
        #expect(encodedPolygonZ == "POLYGONZ((0.0 0.0 0.0,0.0 1.0 0.0,1.0 1.0 0.0,1.0 0.0 0.0,0.0 0.0 0.0))")

        let polygonM = try WKTCoder.decode(wkt: polygonMData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonM = WKTCoder.encode(geometry: polygonM, targetProjection: nil)
        #expect(encodedPolygonM == "POLYGONM((0.0 0.0 2.0,0.0 1.0 2.0,1.0 1.0 2.0,1.0 0.0 2.0,0.0 0.0 2.0))")

        let polygonZM = try WKTCoder.decode(wkt: polygonZMData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonZM = WKTCoder.encode(geometry: polygonZM, targetProjection: nil)
        #expect(encodedPolygonZM == "POLYGONZM((0.0 0.0 0.0 2.0,0.0 1.0 0.0 2.0,1.0 1.0 0.0 2.0,1.0 0.0 0.0 2.0,0.0 0.0 0.0 2.0))")

        let polygonWithHole = try WKTCoder.decode(wkt: polygonWithHoleData, sourceProjection: .epsg4326) as! Polygon
        let encodedPolygonWithHole = WKTCoder.encode(geometry: polygonWithHole, targetProjection: nil)
        #expect(encodedPolygonWithHole == "POLYGON((0.0 0.0,10.0 0.0,10.0 10.0,0.0 10.0,0.0 0.0),(1.0 1.0,1.0 2.0,2.0 2.0,2.0 1.0,1.0 1.0))")
    }

    // MARK: - MultiPolygon

    private let multiPolygonData = "MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))"

    @Test
    func multiPolygonDecoding() async throws {
        let multiPolygon = try WKTCoder.decode(wkt: multiPolygonData, sourceProjection: .epsg4326) as! MultiPolygon
        #expect(multiPolygon.polygons.count == 2)
    }

    @Test
    func multiPolygonEncoding() async throws {
        let multiPolygon = try WKTCoder.decode(wkt: multiPolygonData, sourceProjection: .epsg4326) as! MultiPolygon
        let encodedMultiPolygon = WKTCoder.encode(geometry: multiPolygon, targetProjection: nil)
        #expect(encodedMultiPolygon == "MULTIPOLYGON(((0.0 0.0,4.0 0.0,4.0 4.0,0.0 4.0,0.0 0.0),(1.0 1.0,2.0 1.0,2.0 2.0,1.0 2.0,1.0 1.0)),((-1.0 -1.0,-1.0 -2.0,-2.0 -2.0,-2.0 -1.0,-1.0 -1.0)))")
    }

    // MARK: - GeometryCollection

    private let geometryCollectionData = "GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))"

    @Test
    func geometryCollectionDecoding() async throws {
        let geometryCollection = try WKTCoder.decode(wkt: geometryCollectionData, sourceProjection: .epsg4326) as! GeometryCollection
        #expect(geometryCollection.geometries.count == 2)
        #expect(geometryCollection.geometries[0].type == .point)
        #expect(geometryCollection.geometries[1].type == .polygon)
    }

    @Test
    func geometryCollectionEncoding() async throws {
        let geometryCollection = try WKTCoder.decode(wkt: geometryCollectionData, sourceProjection: .epsg4326) as! GeometryCollection
        let encodedGeometryCollection = WKTCoder.encode(geometry: geometryCollection, targetProjection: nil)
        #expect(encodedGeometryCollection == "GEOMETRYCOLLECTION(POINT(2.0 0.0),POLYGON((0.0 0.0,1.0 0.0,1.0 1.0,0.0 1.0,0.0 0.0)))")
    }

    // MARK: - Triangle

    private let triangleData = "TRIANGLE((0 0, 0 1, 1 1, 0 0))"
    private let triangleZData = "TRIANGLE Z ((0 0 0, 0 1 0, 1 1 0, 0 0 0))"
    private let triangleMData = "TRIANGLE M ((0 0 2, 0 1 2, 1 1 2, 0 0 2))"
    private let triangleZMData = "TRIANGLE ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 0 0 0 2))"

    @Test
    func triangleDecoding() async throws {
        let triangle = try WKTCoder.decode(wkt: triangleData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangle.rings.count == 1)
        #expect(triangle.outerRing!.coordinates.count == 4)

        let triangleZ = try WKTCoder.decode(wkt: triangleZData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangleZ.rings.count == 1)
        #expect(triangleZ.outerRing!.coordinates.count == 4)

        let triangleM = try WKTCoder.decode(wkt: triangleMData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangleM.rings.count == 1)
        #expect(triangleM.outerRing!.coordinates.count == 4)

        let triangleZM = try WKTCoder.decode(wkt: triangleZMData, sourceProjection: .epsg4326) as! Polygon
        #expect(triangleZM.rings.count == 1)
        #expect(triangleZM.outerRing!.coordinates.count == 4)
    }

}

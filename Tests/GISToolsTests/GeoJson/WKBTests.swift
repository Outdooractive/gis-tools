import Foundation
@testable import GISTools
@testable import struct GISTools.Polygon
import Testing

struct WKBTests {

    // MARK: - Point

    /// SELECT 'POINT(1 2)'::geometry;
    private let pointData = Data(hex: "0101000000000000000000F03F0000000000000040")!
    /// SELECT 'POINT Z (1 2 3)'::geometry;
    private let pointZData = Data(hex: "0101000080000000000000F03F00000000000000400000000000000840")!
    /// SELECT 'POINT M (1 2 4)'::geometry;
    private let pointMData = Data(hex: "0101000040000000000000F03F00000000000000400000000000001040")!
    /// SELECT 'POINT ZM (1 2 3 4)'::geometry;
    private let pointZMData = Data(hex: "01010000C0000000000000F03F000000000000004000000000000008400000000000001040")!

    /// Validates decoding WKB Point types (XY, XYZ, XYM, XYZM).
    @Test
    func pointDecoding() throws {
        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as? Point)
        #expect(point.coordinate.longitude == 1)
        #expect(point.coordinate.latitude == 2)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg4326) as? Point)
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg4326) as? Point)
        #expect(pointM.coordinate.longitude == 1)
        #expect(pointM.coordinate.latitude == 2)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg4326) as? Point)
        #expect(pointZM.coordinate.longitude == 1)
        #expect(pointZM.coordinate.latitude == 2)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates decoding WKB Point with reprojection from EPSG:4326 to EPSG:3857.
    @Test
    func pointDecoding4326To3857() throws {
        let expectedX = 111_319.49079327357
        let expectedY = 222_684.20850554455

        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(point.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(point.coordinate.y - expectedY) < 0.00000001)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(pointZ.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(pointZ.coordinate.y - expectedY) < 0.00000001)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(pointM.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(pointM.coordinate.y - expectedY) < 0.00000001)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg4326, targetProjection: .epsg3857) as? Point)
        #expect(abs(pointZM.coordinate.x - expectedX) < 0.00000001)
        #expect(abs(pointZM.coordinate.y - expectedY) < 0.00000001)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates decoding WKB Point with reprojection from EPSG:3857 to EPSG:4326.
    @Test
    func pointDecoding3857To4326() throws {
        let expectedLongitude = 0.000008983152841195214
        let expectedLatitude = 0.000017966305681987637

        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(point.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(point.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(pointZ.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(pointZ.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(pointM.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(pointM.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg3857, targetProjection: .epsg4326) as? Point)
        #expect(abs(pointZM.coordinate.longitude - expectedLongitude) < 0.000000000001)
        #expect(abs(pointZM.coordinate.latitude - expectedLatitude) < 0.000000000001)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates decoding WKB Point with no SRID (noSRID).
    @Test
    func pointDecodingNoSRID() throws {
        let expected = Coordinate3D(x: 1, y: 2, projection: .noSRID)

        #expect(throws: WKBCoder.WKBCoderError.self) {
            try WKBCoder.decode(wkb: pointData, sourceProjection: .noSRID) as? Point
        }

        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(point.coordinate.x == expected.x)
        #expect(point.coordinate.y == expected.y)
        #expect(point.coordinate.altitude == nil)

        let pointZ = try #require(try WKBCoder.decode(wkb: pointZData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(pointZ.coordinate.x == expected.x)
        #expect(pointZ.coordinate.y == expected.y)
        #expect(pointZ.coordinate.altitude == 3)

        let pointM = try #require(try WKBCoder.decode(wkb: pointMData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(pointM.coordinate.x == expected.x)
        #expect(pointM.coordinate.y == expected.y)
        #expect(pointM.coordinate.m == 4)
        #expect(pointM.coordinate.altitude == nil)

        let pointZM = try #require(try WKBCoder.decode(wkb: pointZMData, sourceProjection: .noSRID, targetProjection: .noSRID) as? Point)
        #expect(pointZM.coordinate.x == expected.x)
        #expect(pointZM.coordinate.y == expected.y)
        #expect(pointZM.coordinate.altitude == 3)
        #expect(pointZM.coordinate.m == 4)
    }

    /// Validates encoding a Point back to WKB round-trips correctly.
    @Test
    func pointEncoding() throws {
        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as? Point)
        let encodedPoint = WKBCoder.encode(geometry: point, targetProjection: nil)
        #expect(encodedPoint == pointData)

        let pointZ = try #require(try WKBCoder.decode(wkb: pointZData, sourceProjection: .epsg4326) as? Point)
        let encodedPointZ = WKBCoder.encode(geometry: pointZ, targetProjection: nil)
        #expect(encodedPointZ == pointZData)

        let pointM = try #require(try WKBCoder.decode(wkb: pointMData, sourceProjection: .epsg4326) as? Point)
        let encodedPointM = WKBCoder.encode(geometry: pointM, targetProjection: nil)
        #expect(encodedPointM == pointMData)

        let pointZM = try #require(try WKBCoder.decode(wkb: pointZMData, sourceProjection: .epsg4326) as? Point)
        let encodedPointZM = WKBCoder.encode(geometry: pointZM, targetProjection: nil)
        #expect(encodedPointZM == pointZMData)
    }

    /// Validates the convenience initializer for decoding a Point from WKB data.
    @Test
    func pointConvenienceDecoding() throws {
        let pointZ = try #require(Point(wkb: pointZData, sourceProjection: .epsg4326))
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)
    }

    /// Validates Data convenience methods for decoding a geometry and Feature from WKB.
    @Test
    func pointDataConvenienceDecoding() throws {
        let pointZ = try #require(pointZData.asGeoJsonGeometry(sourceProjection: .epsg4326) as? Point)
        #expect(pointZ.coordinate.longitude == 1)
        #expect(pointZ.coordinate.latitude == 2)
        #expect(pointZ.coordinate.altitude == 3)

        let feature = pointZData.asFeature(sourceProjection: .epsg4326)
        #expect(feature?.geometry?.allCoordinates.first?.longitude == 1)
        #expect(feature?.geometry?.allCoordinates.first?.latitude == 2)
        #expect(feature?.geometry?.allCoordinates.first?.altitude == 3)
    }

    /// SELECT ST_ClipByBox2D(ToPoint('POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))'::geometry), ST_MakeEnvelope(0,0,0.2,0.2));
    private let invalidPointData = Data(hex: "0101000000000000000000F87F000000000000F87F")!

    /// Validates that a WKB Point with NaN coordinates decodes as an empty
    /// MultiPoint, matching `POINT EMPTY`.
    @Test
    func invalidPointDecoding() throws {
        let multiPoint = try #require(
            try WKBCoder.decode(
                wkb: invalidPointData,
                sourceProjection: .epsg4326) as? MultiPoint,
        )

        #expect(multiPoint.points.isEmpty)
    }

    // MARK: - MultiPoint

    /// SELECT 'MULTIPOINT((0 0),(1 2))'::geometry;
    private let multiPointData = Data(hex: "0104000000020000000101000000000000000000000000000000000000000101000000000000000000F03F0000000000000040")!

    /// Validates decoding a WKB MultiPoint.
    @Test
    func multiPointDecoding() throws {
        let multiPoint = try #require(try WKBCoder.decode(wkb: multiPointData, sourceProjection: .epsg4326) as? MultiPoint)
        #expect(multiPoint.coordinates.count == 2)
        #expect(multiPoint.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0))
        #expect(multiPoint.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1))
    }

    /// Validates encoding a MultiPoint back to WKB round-trips correctly.
    @Test
    func multiPointEncoding() throws {
        let multiPoint = try #require(try WKBCoder.decode(wkb: multiPointData, sourceProjection: .epsg4326) as? MultiPoint)
        let encodedMultiPoint = WKBCoder.encode(geometry: multiPoint, targetProjection: nil)
        #expect(encodedMultiPoint == multiPointData)
    }

    // MARK: - MultiPoint with SRID

    /// SELECT 'SRID=4326;MULTIPOINTZ(0 0 0,1 2 1)'::geometry;
    private let multiPointZSRIDData = Data(hex: "01040000A0E61000000200000001010000800000000000000000000000000000000000000000000000000101000080000000000000F03F0000000000000040000000000000F03F")!

    /// Validates decoding a WKB MultiPoint with embedded SRID.
    @Test
    func multiPointSRIDDecoding() throws {
        let multiPointZSRID = try #require(try WKBCoder.decode(wkb: multiPointZSRIDData, sourceSrid: nil) as? MultiPoint)
        #expect(multiPointZSRID.coordinates.count == 2)
        #expect(multiPointZSRID.coordinates[0] == Coordinate3D(latitude: 0, longitude: 0, altitude: 0))
        #expect(multiPointZSRID.coordinates[1] == Coordinate3D(latitude: 2, longitude: 1, altitude: 1))
    }

    /// Validates encoding a MultiPoint with SRID back to WKB round-trips correctly.
    @Test
    func multiPointSRIDEncoding() throws {
        let multiPointZSRID = try #require(try WKBCoder.decode(wkb: multiPointZSRIDData, sourceSrid: nil) as? MultiPoint)
        let encodedMultiPointZSRID = WKBCoder.encode(geometry: multiPointZSRID, targetProjection: .epsg4326)
        #expect(encodedMultiPointZSRID == multiPointZSRIDData)
    }

    /// A PostGIS EWKB LINESTRING with embedded SRID 3857 (Web Mercator).
    private let lineStringSRID3857Data = Data(hex: "0102000020110F00000F000000B1AB426CB24C3141FF9A56141D015741AC6335BCD04C31414C475DB321015741ED12DD37F14C3141A108733D240157410B3F0D08104D3141930997E929015741B6607F03364D3141EF0AD7643A0157415F3425CA4C4D31411CA75DBE43015741EE7275C6624D3141BB7F3DBC4A01574143F574298B4D314127F08B8E550157412E207A6FB24D314172BC8B0E59015741DEEDD74ECD4D31412A5F69605801574149F56264EE4D3141B4213FDD540157417E97E4BB044E31414813A5AB54015741383AAE891E4E3141201F4C71580157413CF330C6434E3141D260EB125E015741CEAD8B65734E3141034DA5EF63015741")!

    /// Validates auto-detecting the embedded SRID from a PostGIS EWKB LINESTRING.
    @Test
    func lineStringSRIDAutoDetection() throws {
        let lineString = try #require(try WKBCoder.decode(wkb: lineStringSRID3857Data, sourceProjection: nil) as? LineString)
        #expect(lineString.coordinates.count == 15)
        #expect(abs(lineString.coordinates[0].longitude - 10.184617401417709) < 0.0000001)
        #expect(abs(lineString.coordinates[0].latitude - 47.53870670004494) < 0.0000001)
    }

    /// Validates that a plain WKB (no SRID flag) with no explicit projection fails cleanly
    /// instead of misreading the point count as an SRID.
    @Test
    func plainWKBNoSRIDAutoDetection() throws {
        #expect(throws: WKBCoder.WKBCoderError.unknownSRID) {
            _ = try WKBCoder.decode(wkb: lineStringData, sourceProjection: nil)
        }
    }

    // MARK: - LineString

    /// SELECT 'LINESTRING (1 1, 1 2, 1 3, 2 2)'::geometry;
    private let lineStringData = Data(hex: "010200000004000000000000000000F03F000000000000F03F000000000000F03F0000000000000040000000000000F03F000000000000084000000000000000400000000000000040")!
    /// SELECT 'LINESTRING Z (1 1 5, 1 2 5, 1 3 5, 2 2 5)'::geometry;
    private let lineStringZData = Data(hex: "010200008004000000000000000000F03F000000000000F03F0000000000001440000000000000F03F00000000000000400000000000001440000000000000F03F00000000000008400000000000001440000000000000004000000000000000400000000000001440")!
    /// SELECT 'LINESTRING M (1 1 0, 1 2 0, 1 3 1, 2 2 0)'::geometry;
    private let lineStringMData = Data(hex: "010200004004000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000400000000000000000000000000000F03F0000000000000840000000000000F03F000000000000004000000000000000400000000000000000")!
    /// SELECT 'LINESTRING ZM (1 1 5 0, 1 2 5 0, 1 3 5 1, 2 2 5 0)'::geometry;
    private let lineStringZMData = Data(hex: "01020000C004000000000000000000F03F000000000000F03F00000000000014400000000000000000000000000000F03F000000000000004000000000000014400000000000000000000000000000F03F00000000000008400000000000001440000000000000F03F0000000000000040000000000000004000000000000014400000000000000000")!

    /// Validates decoding WKB LineString types (XY, XYZ, XYM, XYZM).
    @Test
    func lineStringDecoding() throws {
        let lineString = try #require(try WKBCoder.decode(wkb: lineStringData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineString.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ])

        let lineStringZ = try #require(try WKBCoder.decode(wkb: lineStringZData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineStringZ.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0, altitude: 5.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0, altitude: 5.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0, altitude: 5.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0, altitude: 5.0),
        ])

        let lineStringM = try #require(try WKBCoder.decode(wkb: lineStringMData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineStringM.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0, m: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0, m: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0, m: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0, m: 0.0),
        ])

        let lineStringZM = try #require(try WKBCoder.decode(wkb: lineStringZMData, sourceProjection: .epsg4326) as? LineString)
        #expect(lineStringZM.coordinates == [
            Coordinate3D(latitude: 1.0, longitude: 1.0, altitude: 5.0, m: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0, altitude: 5.0, m: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0, altitude: 5.0, m: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0, altitude: 5.0, m: 0.0),
        ])
    }

    /// Validates encoding a LineString back to WKB round-trips correctly.
    @Test
    func lineStringEncoding() throws {
        let lineString = try #require(try WKBCoder.decode(wkb: lineStringData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineString = WKBCoder.encode(geometry: lineString, targetProjection: nil)
        #expect(encodedLineString == lineStringData)

        let lineStringZ = try #require(try WKBCoder.decode(wkb: lineStringZData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineStringZ = WKBCoder.encode(geometry: lineStringZ, targetProjection: nil)
        #expect(encodedLineStringZ == lineStringZData)

        let lineStringM = try #require(try WKBCoder.decode(wkb: lineStringMData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineStringM = WKBCoder.encode(geometry: lineStringM, targetProjection: nil)
        #expect(encodedLineStringM == lineStringMData)

        let lineStringZM = try #require(try WKBCoder.decode(wkb: lineStringZMData, sourceProjection: .epsg4326) as? LineString)
        let encodedLineStringZM = WKBCoder.encode(geometry: lineStringZM, targetProjection: nil)
        #expect(encodedLineStringZM == lineStringZMData)
    }

    // MARK: - MultiLineString

    /// SELECT 'MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))'::geometry;
    private let multiLineStringData = Data(hex: "01050000000200000001020000000300000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F0000000000000040010200000003000000000000000000004000000000000008400000000000000840000000000000004000000000000014400000000000001040")!

    /// Validates decoding a WKB MultiLineString.
    @Test
    func multiLineStringDecoding() throws {
        let multiLineString = try #require(try WKBCoder.decode(wkb: multiLineStringData, sourceProjection: .epsg4326) as? MultiLineString)
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

    /// Validates encoding a MultiLineString back to WKB round-trips correctly.
    @Test
    func multiLineStringEncoding() throws {
        let multiLineString = try #require(try WKBCoder.decode(wkb: multiLineStringData, sourceProjection: .epsg4326) as? MultiLineString)
        let encodedMultiLineString = WKBCoder.encode(geometry: multiLineString, targetProjection: nil)
        #expect(encodedMultiLineString == multiLineStringData)
    }

    // MARK: - Polygon

    /// SELECT 'POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))'::geometry;
    private let polygonData = Data(hex: "01030000000100000005000000000000000000000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F000000000000F03F000000000000000000000000000000000000000000000000")!
    /// SELECT 'POLYGON Z ((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))'::geometry;
    private let polygonZData = Data(hex: "010300008001000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000000000000000000000000000000000000000000000000000000000000000000000")!
    /// SELECT 'POLYGON M ((0 0 2, 0 1 2, 1 1 2, 1 0 2, 0 0 2))'::geometry;
    private let polygonMData = Data(hex: "010300004001000000050000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F0000000000000040000000000000F03F000000000000F03F0000000000000040000000000000F03F00000000000000000000000000000040000000000000000000000000000000000000000000000040")!
    /// SELECT 'POLYGON ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 1 0 0 2, 0 0 0 2))'::geometry;
    private let polygonZMData = Data(hex: "01030000C0010000000500000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F00000000000000000000000000000040000000000000F03F000000000000F03F00000000000000000000000000000040000000000000F03F0000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000040")!
    /// SELECT 'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 1 2, 2 2, 2 1, 1 1))'::geometry;
    private let polygonWithHoleData = Data(hex: "01030000000200000005000000000000000000000000000000000000000000000000002440000000000000000000000000000024400000000000002440000000000000000000000000000024400000000000000000000000000000000005000000000000000000F03F000000000000F03F000000000000F03F0000000000000040000000000000004000000000000000400000000000000040000000000000F03F000000000000F03F000000000000F03F")!

    /// Validates decoding WKB Polygon types (XY, XYZ, XYM, XYZM, with hole).
    @Test
    func polygonDecoding() throws {
        let expectedOuter = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try #require(try WKBCoder.decode(wkb: polygonData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygon.coordinates == [expectedOuter])

        let polygonZ = try #require(try WKBCoder.decode(wkb: polygonZData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonZ.coordinates == [expectedOuter.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0)
        }])

        let polygonM = try #require(try WKBCoder.decode(wkb: polygonMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonM.coordinates == [expectedOuter.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, m: 2.0)
        }])

        let polygonZM = try #require(try WKBCoder.decode(wkb: polygonZMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(polygonZM.coordinates == [expectedOuter.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0, m: 2.0)
        }])

        let polygonWithHole = try #require(try WKBCoder.decode(wkb: polygonWithHoleData, sourceProjection: .epsg4326) as? Polygon)
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

    /// Validates encoding a Polygon back to WKB round-trips correctly.
    @Test
    func polygonEncoding() throws {
        let polygon = try #require(try WKBCoder.decode(wkb: polygonData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygon = WKBCoder.encode(geometry: polygon, targetProjection: nil)
        #expect(encodedPolygon == polygonData)

        let polygonZ = try #require(try WKBCoder.decode(wkb: polygonZData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonZ = WKBCoder.encode(geometry: polygonZ, targetProjection: nil)
        #expect(encodedPolygonZ == polygonZData)

        let polygonM = try #require(try WKBCoder.decode(wkb: polygonMData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonM = WKBCoder.encode(geometry: polygonM, targetProjection: nil)
        #expect(encodedPolygonM == polygonMData)

        let polygonZM = try #require(try WKBCoder.decode(wkb: polygonZMData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonZM = WKBCoder.encode(geometry: polygonZM, targetProjection: nil)
        #expect(encodedPolygonZM == polygonZMData)

        let polygonWithHole = try #require(try WKBCoder.decode(wkb: polygonWithHoleData, sourceProjection: .epsg4326) as? Polygon)
        let encodedPolygonWithHole = WKBCoder.encode(geometry: polygonWithHole, targetProjection: nil)
        #expect(encodedPolygonWithHole == polygonWithHoleData)
    }

    // MARK: - MultiPolygon

    /// SELECT 'MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))'::geometry;
    private let multiPolygonData = Data(hex: "01060000000200000001030000000200000005000000000000000000000000000000000000000000000000001040000000000000000000000000000010400000000000001040000000000000000000000000000010400000000000000000000000000000000005000000000000000000F03F000000000000F03F0000000000000040000000000000F03F00000000000000400000000000000040000000000000F03F0000000000000040000000000000F03F000000000000F03F01030000000100000005000000000000000000F0BF000000000000F0BF000000000000F0BF00000000000000C000000000000000C000000000000000C000000000000000C0000000000000F0BF000000000000F0BF000000000000F0BF")!

    /// Validates decoding a WKB MultiPolygon.
    @Test
    func multiPolygonDecoding() throws {
        let multiPolygon = try #require(try WKBCoder.decode(wkb: multiPolygonData, sourceProjection: .epsg4326) as? MultiPolygon)
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

    /// Validates encoding a MultiPolygon back to WKB round-trips correctly.
    @Test
    func multiPolygonEncoding() throws {
        let multiPolygon = try #require(try WKBCoder.decode(wkb: multiPolygonData, sourceProjection: .epsg4326) as? MultiPolygon)
        let encodedMultiPolygon = WKBCoder.encode(geometry: multiPolygon, targetProjection: nil)
        #expect(encodedMultiPolygon == multiPolygonData)
    }

    // MARK: - GeometryCollection

    /// SELECT 'GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))'::geometry;
    private let geometryCollectionData = Data(hex: "0107000000020000000101000000000000000000004000000000000000000103000000010000000500000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F00000000000000000000000000000000")!

    /// Validates decoding a WKB GeometryCollection.
    @Test
    func geometryCollectionDecoding() throws {
        let geometryCollection = try #require(try WKBCoder.decode(wkb: geometryCollectionData, sourceProjection: .epsg4326) as? GeometryCollection)
        #expect(geometryCollection.geometries.count == 2)
        #expect(geometryCollection.geometries[0].type == .point)
        #expect(geometryCollection.geometries[1].type == .polygon)
    }

    /// Validates encoding a GeometryCollection back to WKB round-trips correctly.
    @Test
    func geometryCollectionEncoding() throws {
        let geometryCollection = try #require(try WKBCoder.decode(wkb: geometryCollectionData, sourceProjection: .epsg4326) as? GeometryCollection)
        let encodedGeometryCollection = WKBCoder.encode(geometry: geometryCollection, targetProjection: nil)
        #expect(encodedGeometryCollection == geometryCollectionData)
    }

    // MARK: - Triangle

    /// SELECT 'TRIANGLE((0 0, 0 1, 1 1, 0 0))'::geometry;
    private let triangleData = Data(hex: "01110000000100000004000000000000000000000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F00000000000000000000000000000000")!
    /// SELECT 'TRIANGLE Z ((0 0 0, 0 1 0, 1 1 0, 0 0 0))'::geometry;
    private let triangleZData = Data(hex: "011100008001000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F0000000000000000000000000000000000000000000000000000000000000000")!
    /// SELECT 'TRIANGLE M ((0 0 2, 0 1 2, 1 1 2, 0 0 2))'::geometry;
    private let triangleMData = Data(hex: "011100004001000000040000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F0000000000000040000000000000F03F000000000000F03F0000000000000040000000000000000000000000000000000000000000000040")!
    /// SELECT 'TRIANGLE ZM ((0 0 0 2, 0 1 0 2, 1 1 0 2, 0 0 0 2))'::geometry;
    private let triangleZMData = Data(hex: "01110000C0010000000400000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000F03F00000000000000000000000000000040000000000000F03F000000000000F03F000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000040")!

    /// Validates decoding WKB Triangle types (XY, XYZ, XYM, XYZM) as Polygon.
    @Test
    func triangleDecoding() throws {
        let expected = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]

        let triangle = try #require(try WKBCoder.decode(wkb: triangleData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangle.coordinates == [expected])

        let triangleZ = try #require(try WKBCoder.decode(wkb: triangleZData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangleZ.coordinates == [expected.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0)
        }])

        let triangleM = try #require(try WKBCoder.decode(wkb: triangleMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangleM.coordinates == [expected.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, m: 2.0)
        }])

        let triangleZM = try #require(try WKBCoder.decode(wkb: triangleZMData, sourceProjection: .epsg4326) as? Polygon)
        #expect(triangleZM.coordinates == [expected.map {
            Coordinate3D(latitude: $0.latitude, longitude: $0.longitude, altitude: 0.0, m: 2.0)
        }])
    }

    // MARK: - GeoJsonGeometry convenience

    /// Validates parsing a geometry from WKB data with a source SRID.
    @Test
    func geoJsonGeometryParseSourceSrid() {
        let geometry = GeometryCollection.parse(wkb: pointData, sourceSrid: 4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.longitude == 1)
    }

    /// Validates parsing a geometry from WKB data with a source projection.
    @Test
    func geoJsonGeometryParseSourceProjection() {
        let geometry = GeometryCollection.parse(wkb: pointData, sourceProjection: .epsg4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.longitude == 1)
    }

    /// Validates encoding a geometry to WKB and decoding it back round-trips correctly.
    @Test
    func geoJsonGeometryAsWKB() throws {
        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as? Point)
        let encoded = try #require(point.asWKB)
        let decoded = try #require(try WKBCoder.decode(wkb: encoded, sourceSrid: nil) as? Point)
        #expect(decoded.coordinate.longitude == point.coordinate.longitude)
        #expect(decoded.coordinate.latitude == point.coordinate.latitude)
    }

    // MARK: - Feature convenience

    /// Validates creating a Feature from WKB data with a source SRID.
    @Test
    func featureInitSourceSrid() {
        let feature = Feature(
            wkb: pointZData,
            sourceSrid: 4326,
            id: .string("f1"),
            properties: ["key": "value"])
        #expect(feature?.id == .string("f1"))
        #expect(feature?.geometry is Point)
        #expect(feature?.properties["key"] as? String == "value")
    }

    /// Validates creating a Feature from WKB data with a source projection.
    @Test
    func featureInitSourceProjection() {
        let feature = Feature(
            wkb: pointZData,
            sourceProjection: .epsg4326,
            id: .string("f2"))
        #expect(feature?.id == .string("f2"))
        #expect(feature?.geometry is Point)
    }

    /// Validates encoding a Feature to WKB and decoding it back round-trips correctly.
    @Test
    func featureAsWKB() throws {
        let point = try #require(try WKBCoder.decode(wkb: pointData, sourceProjection: .epsg4326) as? Point)
        let feature = Feature(point)
        let encoded = try #require(feature.asWKB)
        let decoded = try #require(try WKBCoder.decode(wkb: encoded, sourceSrid: nil) as? Point)
        #expect(decoded.coordinate.longitude == point.coordinate.longitude)
        #expect(decoded.coordinate.latitude == point.coordinate.latitude)
    }

    // MARK: - FeatureCollection convenience

    /// Validates creating a FeatureCollection from WKB data with a source SRID.
    @Test
    func featureCollectionInitSourceSrid() {
        let fc = FeatureCollection(wkb: pointData, sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    /// Validates creating a FeatureCollection from WKB data with a source projection.
    @Test
    func featureCollectionInitSourceProjection() {
        let fc = FeatureCollection(wkb: pointData, sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    // MARK: - Data convenience

    /// Validates decoding WKB Data to a geometry using a source SRID.
    @Test
    func dataAsGeoJsonGeometrySourceSrid() {
        let geometry = pointZData.asGeoJsonGeometry(sourceSrid: 4326)
        #expect(geometry is Point)
        #expect((geometry as? Point)?.coordinate.altitude == 3)
    }

    /// Validates decoding WKB Data to a Feature using a source SRID.
    @Test
    func dataAsFeatureSourceSrid() {
        let feature = pointZData.asFeature(sourceSrid: 4326, id: .string("d1"))
        #expect(feature?.id == .string("d1"))
        #expect(feature?.geometry is Point)
    }

    /// Validates decoding WKB Data to a FeatureCollection using a source SRID.
    @Test
    func dataAsFeatureCollectionSourceSrid() {
        let fc = pointData.asFeatureCollection(sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    /// Validates decoding WKB Data to a FeatureCollection using a source projection.
    @Test
    func dataAsFeatureCollectionSourceProjection() {
        let fc = pointData.asFeatureCollection(sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

}

// MARK: - GeoJSON audit regressions

extension WKBTests {

    /// Explicit source projections must still consume an embedded EWKB SRID.
    @Test
    func ewkbExplicitSourceProjectionSkipsEmbeddedSRID() throws {
        // SELECT 'SRID=4326;POINT(1 2)'::geometry;
        let data = try #require(Data(hex: "0101000020E6100000000000000000F03F0000000000000040"))

        let point = try #require(try WKBCoder.decode(
            wkb: data,
            sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate.longitude == 1.0)
        #expect(point.coordinate.latitude == 2.0)
    }

    /// Truncated WKB counts must fail instead of producing empty geometries.
    @Test(arguments: [
        "0102000000", // LineString
        "0104000000", // MultiPoint
        "0105000000", // MultiLineString
        "0106000000", // MultiPolygon
        "0107000000", // GeometryCollection
    ])
    func truncatedWKBGeometryCountFails(hex: String) throws {
        let data = try #require(Data(hex: hex))

        #expect(throws: WKBCoder.WKBCoderError.self) {
            try WKBCoder.decode(wkb: data, sourceProjection: .epsg4326)
        }
    }

    /// WKB payloads with trailing bytes are malformed.
    @Test
    func wkbTrailingBytesFail() throws {
        let data = try #require(Data(hex: "0101000000000000000000F03F000000000000004000"))

        #expect(throws: WKBCoder.WKBCoderError.self) {
            try WKBCoder.decode(wkb: data, sourceProjection: .epsg4326)
        }
    }

    /// WKB polygons must reject rings that cannot form a linear ring.
    @Test
    func wkbPolygonWithTooShortRingFails() throws {
        // Polygon, one ring, two positions (0 0, 1 1).
        let data = try #require(Data(hex: """
        01030000000100000001000000020000000000000000000000000000000000000000000000000000000000F03F000000000000F03F
        """.trimmingCharacters(in: .whitespacesAndNewlines)))

        #expect(throws: WKBCoder.WKBCoderError.self) {
            try WKBCoder.decode(wkb: data, sourceProjection: .epsg4326)
        }
    }

    /// Nested WKB components must be encoded in the requested projection.
    @Test
    func wkbNestedGeometryUsesTargetProjection() throws {
        let coordinates = [
            Coordinate3D(x: 1_000_000.0, y: 2_000_000.0, projection: .epsg3857),
            Coordinate3D(x: 1_000_100.0, y: 2_000_100.0, projection: .epsg3857),
        ]
        let multiPoint = try #require(MultiPoint(coordinates))
        let data = try #require(WKBCoder.encode(
            geometry: multiPoint,
            targetProjection: .epsg3857))
        let decoded = try #require(try WKBCoder.decode(
            wkb: data,
            sourceSrid: nil,
            targetProjection: .epsg3857) as? MultiPoint)

        #expect(decoded.coordinates == coordinates)
    }

    // MARK: - Curves and surfaces

    /// PostGIS: ST_AsBinary('CIRCULARSTRING(0 0, 1 1, 2 0)'::geometry)
    private static let circularStringData = Data(hex: "01080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000")!

    /// PostGIS: ST_AsBinary('COMPOUNDCURVE(CIRCULARSTRING(0 0, 1 1, 2 0), (2 0, 3 1))'::geometry)
    private static let compoundCurveData = Data(hex: "01090000000200000001080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000010200000002000000000000000000004000000000000000000000000000000840000000000000F03F")!

    /// PostGIS: ST_AsBinary('CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0))'::geometry)
    private static let curvePolygonData = Data(hex: "010A0000000100000001080000000500000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000000000000000F03F000000000000F0BF00000000000000000000000000000000")!

    /// PostGIS: ST_AsBinary('MULTICURVE(CIRCULARSTRING(0 0, 1 1, 2 0), (2 0, 3 1))'::geometry)
    private static let multiCurveData = Data(hex: "010B0000000200000001080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000010200000002000000000000000000004000000000000000000000000000000840000000000000F03F")!

    /// PostGIS: ST_AsBinary('MULTISURFACE(CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0)))'::geometry)
    private static let multiSurfaceData = Data(hex: "010C00000001000000010A0000000100000001080000000500000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000000000000000F03F000000000000F0BF00000000000000000000000000000000")!

    /// PostGIS: ST_AsBinary('TIN(((0 0, 1 0, 0 1, 0 0)))'::geometry)
    private static let tinData = Data(hex: "0110000000010000000111000000010000000400000000000000000000000000000000000000000000000000F03F00000000000000000000000000000000000000000000F03F00000000000000000000000000000000")!

    /// PostGIS: ST_AsBinary('POLYHEDRALSURFACE(((0 0, 1 0, 0 1, 0 0)))'::geometry)
    private static let polyhedralSurfaceData = Data(hex: "010F000000010000000103000000010000000400000000000000000000000000000000000000000000000000F03F00000000000000000000000000000000000000000000F03F00000000000000000000000000000000")!

    /// PostGIS: ST_AsBinary('TIN(((0 0 0, 1 0 0, 0 1 0, 0 0 0)))'::geometry)
    private static let tinZData = Data(hex: "01F80300000100000001F90300000100000004000000000000000000000000000000000000000000000000000000000000000000F03F000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000000000000000000000000000000000000000")!

    /// PostGIS: ST_AsBinary('POINT EMPTY'::geometry)
    private static let emptyPointData = Data(hex: "0101000000000000000000F87F000000000000F87F")!

    /// PostGIS: ST_AsBinary('POINT Z (1 2 3)'::geometry), ISO type code 1001.
    private static let isoPointZData = Data(hex: "01E9030000000000000000F03F00000000000000400000000000000840")!

    /// Validates that a CircularString is linearized into a LineString.
    @Test
    func circularStringDecoding() throws {
        let lineString = try #require(try WKBCoder.decode(wkb: Self.circularStringData, sourceProjection: .epsg4326) as? LineString)

        #expect(lineString.coordinates.count > 3)
        #expect(abs(lineString.coordinates[0].longitude - 0.0) < 1e-9)
        #expect(abs(lineString.coordinates[0].latitude - 0.0) < 1e-9)
        #expect(try abs(#require(lineString.coordinates.last?.longitude) - 2.0) < 1e-9)
        #expect(try abs(#require(lineString.coordinates.last?.latitude) - 0.0) < 1e-9)
        #expect(lineString.coordinates.contains { coordinate in
            abs(coordinate.longitude - 1.0) < 1e-6 && abs(coordinate.latitude - 1.0) < 1e-6
        })
    }

    /// Validates that a CompoundCurve is linearized into a LineString.
    @Test
    func compoundCurveDecoding() throws {
        let lineString = try #require(try WKBCoder.decode(wkb: Self.compoundCurveData, sourceProjection: .epsg4326) as? LineString)

        #expect(try abs(#require(lineString.coordinates.first?.longitude) - 0.0) < 1e-9)
        #expect(try abs(#require(lineString.coordinates.last?.longitude) - 3.0) < 1e-9)
        #expect(try abs(#require(lineString.coordinates.last?.latitude) - 1.0) < 1e-9)
        #expect(lineString.coordinates.contains { coordinate in
            abs(coordinate.longitude - 2.0) < 1e-9 && abs(coordinate.latitude - 0.0) < 1e-9
        })
    }

    /// Validates that a CurvePolygon is linearized into a Polygon.
    @Test
    func curvePolygonDecoding() throws {
        let polygon = try #require(try WKBCoder.decode(wkb: Self.curvePolygonData, sourceProjection: .epsg4326) as? Polygon)

        #expect(polygon.coordinates.count == 1)
        #expect(polygon.coordinates[0].count > 4)
        #expect(polygon.coordinates[0].first == polygon.coordinates[0].last)
    }

    /// Validates that a MultiCurve is linearized into a MultiLineString.
    @Test
    func multiCurveDecoding() throws {
        let multiLineString = try #require(try WKBCoder.decode(wkb: Self.multiCurveData, sourceProjection: .epsg4326) as? MultiLineString)

        #expect(multiLineString.coordinates.count == 2)
        #expect(multiLineString.coordinates[0].count > 3)
        #expect(try abs(#require(multiLineString.coordinates[1].last?.longitude) - 3.0) < 1e-9)
    }

    /// Validates that a MultiSurface is linearized into a MultiPolygon.
    @Test
    func multiSurfaceDecoding() throws {
        let multiPolygon = try #require(try WKBCoder.decode(wkb: Self.multiSurfaceData, sourceProjection: .epsg4326) as? MultiPolygon)

        #expect(multiPolygon.polygons.count == 1)
        #expect(multiPolygon.polygons[0].coordinates[0].count > 4)
    }

    /// Validates that TIN and PolyhedralSurface decode to a MultiPolygon.
    @Test
    func tinAndPolyhedralSurfaceDecoding() throws {
        let tin = try #require(try WKBCoder.decode(wkb: Self.tinData, sourceProjection: .epsg4326) as? MultiPolygon)
        #expect(tin.polygons.count == 1)
        #expect(tin.polygons[0].coordinates[0].count == 4)

        let polyhedralSurface = try #require(try WKBCoder.decode(wkb: Self.polyhedralSurfaceData, sourceProjection: .epsg4326) as? MultiPolygon)
        #expect(polyhedralSurface.polygons.count == 1)
        #expect(polyhedralSurface.polygons[0].coordinates[0].count == 4)
    }

    /// Validates ISO SQL/MM dimension codes as used by PostGIS for TIN.
    @Test
    func tinZDecoding() throws {
        let tin = try #require(try WKBCoder.decode(wkb: Self.tinZData, sourceProjection: .epsg4326) as? MultiPolygon)

        #expect(tin.polygons.count == 1)
        #expect(tin.polygons[0].coordinates[0][0].altitude == 0)
        #expect(tin.polygons[0].coordinates[0][1].altitude == 0)
        #expect(tin.polygons[0].coordinates[0][2].altitude == 0)
    }

    /// Validates ISO SQL/MM dimension codes for a Point.
    @Test
    func isoPointZDecoding() throws {
        let point = try #require(try WKBCoder.decode(wkb: Self.isoPointZData, sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate.longitude == 1)
        #expect(point.coordinate.latitude == 2)
        #expect(point.coordinate.altitude == 3)
    }

    /// Validates that POINT EMPTY becomes an empty MultiPoint.
    @Test
    func emptyPointDecoding() throws {
        let multiPoint = try #require(try WKBCoder.decode(wkb: Self.emptyPointData, sourceProjection: .epsg4326) as? MultiPoint)

        #expect(multiPoint.points.isEmpty)
        #expect(multiPoint.allCoordinates.isEmpty)
    }

}

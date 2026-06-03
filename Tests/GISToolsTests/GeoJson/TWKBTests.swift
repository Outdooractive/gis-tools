import Foundation
@testable import GISTools
import Testing

struct TWKBTests {

    @Test
    func decodePoint() async throws {
        // TWKB Point at (0, 0) with precision 6:
        // Header: type=1, precision=6 → 0x61
        // Metadata: empty varint → 0x00
        // x=0, y=0 as zigzag varints → 0x00, 0x00
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data)
        #expect(result is Point)

        let point = result as! Point
        #expect(point.coordinate.latitude == 0.0)
        #expect(point.coordinate.longitude == 0.0)
    }

    @Test
    func decodePointNonzero() async throws {
        // Point at (12, 34), precision 0 (raw degrees, scale=1):
        // Header: type=1, precision=0 → 0x01
        // Metadata: 0x00
        // x=12: zigzag(12*1)=24, varint of 24 = 0x18
        // y=34: zigzag(34*1)=68, varint of 68 = 0x44
        let bytes: [UInt8] = [0x01, 0x00, 0x18, 0x44]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data)
        let point = result as! Point
        #expect(abs(point.coordinate.latitude - 34.0) < 0.0001)
        #expect(abs(point.coordinate.longitude - 12.0) < 0.0001)
    }

    @Test
    func decodeLineString() async throws {
        // LineString with 2 points: (0,0) → (1,2), precision 0
        // Header: type=2, precision=0 → 0x02
        // Metadata: 0x00
        // Point count: varint(2) = 0x02
        // x0=0 → 0x00, y0=0 → 0x00
        // x1=1 (delta from 0) → zigzag(1)=2 → varint(2)=0x02
        // y1=2 (delta from 0) → zigzag(2)=4 → varint(4)=0x04
        let bytes: [UInt8] = [0x02, 0x00, 0x02, 0x00, 0x00, 0x02, 0x04]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data)
        #expect(result is LineString)

        let ls = result as! LineString
        #expect(ls.coordinates.count == 2)
        #expect(ls.coordinates[0].latitude == 0.0)
        #expect(ls.coordinates[0].longitude == 0.0)
        #expect(abs(ls.coordinates[1].latitude - 2.0) < 0.0001)
        #expect(abs(ls.coordinates[1].longitude - 1.0) < 0.0001)
    }

    @Test
    func decodePolygon() async throws {
        // Polygon with 1 ring, 4 points: (0,0)→(10,0)→(10,10)→(0,0), precision 1
        // Header: type=3, precision=1 → 0x13
        // Metadata: 0x00
        // Ring count: 1 → 0x01
        // Point count: 4 → 0x04
        // x0=0 → 0x00, y0=0 → 0x00
        // x1=100 (delta, scale 10): zigzag(100)=200 → varint(200) = 0xC8, 0x01
        // y1=0 (delta): zigzag(0)=0 → 0x00
        // x2=0 (delta from 100): zigzag(0)=0 → 0x00
        // y2=100 (delta from 0): zigzag(100)=200 → varint(200) = 0xC8, 0x01
        // x3=-100 (delta from 100): zigzag(-100)=199 → varint(199) = 0xC7, 0x01
        // y3=0 (delta from 100): zigzag(0)=0 → 0x00
        let bytes: [UInt8] = [
            0x13, 0x00,    // header + metadata
            0x01,          // ring count
            0x04,          // point count
            0x00, 0x00,    // x0, y0
            0xC8, 0x01,    // x1 = 100
            0x00,          // y1 = 0
            0x00,          // x2 = 0
            0xC8, 0x01,    // y2 = 100
            0xC7, 0x01,    // x3 = -100
            0xC7, 0x01,    // y3 = -100
        ]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data)
        #expect(result is Polygon)

        let poly = result as! Polygon
        #expect(poly.outerRing?.coordinates.count == 5) // 4 points + closing
    }

    @Test
    func decodeMultiPoint() async throws {
        // MultiPoint with 2 points: (0,0) and (1,2), precision 0
        // Header: type=4, precision=0 → 0x04
        // Metadata: 0x00
        // Point count: 2 → 0x02
        // x0=0 → 0x00, y0=0 → 0x00
        // x1=1 → 0x02, y1=2 → 0x04
        let bytes: [UInt8] = [0x04, 0x00, 0x02, 0x00, 0x00, 0x02, 0x04]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data)
        #expect(result is MultiPoint)
    }

    @Test
    func decodeEmptyFails() async throws {
        #expect(throws: TWKBCoder.TWKBError.self) {
            try _ = TWKBCoder.decode(twkb: Data())
        }
    }

    // MARK: - sourceSrid decode

    @Test
    func decodeSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data, sourceSrid: 4326)
        #expect(result is Point)
    }

    @Test
    func decodeSourceSridUnknown() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        #expect(throws: TWKBCoder.TWKBError.self) {
            try _ = TWKBCoder.decode(twkb: data, sourceSrid: 9999)
        }
    }

    // MARK: - GeoJsonGeometry convenience

    @Test
    func geoJsonGeometryInitSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let point = Point(twkb: data, sourceSrid: 4326)
        #expect(point?.coordinate.latitude == 0.0)
    }

    @Test
    func geoJsonGeometryInitSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let point = Point(twkb: data, sourceProjection: .epsg4326)
        #expect(point?.coordinate.latitude == 0.0)
    }

    @Test
    func geoJsonGeometryInitDefaultProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let point = Point(twkb: data)
        #expect(point?.coordinate.latitude == 0.0)
    }

    @Test
    func geoJsonGeometryInitBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(Point(twkb: data) == nil)
    }

    @Test
    func geoJsonGeometryParseSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = GeometryCollection.parse(twkb: data, sourceSrid: 4326)
        #expect(geometry is Point)
    }

    @Test
    func geoJsonGeometryParseSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = GeometryCollection.parse(twkb: data, sourceProjection: .epsg4326)
        #expect(geometry is Point)
    }

    @Test
    func geoJsonGeometryParseBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(GeometryCollection.parse(twkb: data) == nil)
    }

    // MARK: - Feature convenience

    @Test
    func featureInitSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let feature = Feature(
            twkb: data,
            sourceSrid: 4326,
            id: .string("test"),
            properties: ["key": "value"])
        #expect(feature?.id == .string("test"))
        #expect(feature?.geometry is Point)
        #expect(feature?.properties["key"] as? String == "value")
    }

    @Test
    func featureInitSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let feature = Feature(
            twkb: data,
            sourceProjection: .epsg4326,
            id: .string("test"))
        #expect(feature?.id == .string("test"))
        #expect(feature?.geometry is Point)
    }

    @Test
    func featureInitBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(Feature(twkb: data) == nil)
    }

    // MARK: - FeatureCollection convenience

    @Test
    func featureCollectionInitSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = FeatureCollection(twkb: data, sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    @Test
    func featureCollectionInitSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = FeatureCollection(twkb: data, sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    @Test
    func featureCollectionInitBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(FeatureCollection(twkb: data) == nil)
    }

    // MARK: - Data convenience

    @Test
    func dataAsGeoJsonGeometryFromTWKBSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = data.asGeoJsonGeometryFromTWKB(sourceSrid: 4326)
        #expect(geometry is Point)
    }

    @Test
    func dataAsGeoJsonGeometryFromTWKBSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = data.asGeoJsonGeometryFromTWKB(sourceProjection: .epsg4326)
        #expect(geometry is Point)
    }

    @Test
    func dataAsGeoJsonGeometryFromTWKBBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(data.asGeoJsonGeometryFromTWKB(sourceProjection: .epsg4326) == nil)
    }

    @Test
    func dataAsFeatureFromTWKBSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let feature = data.asFeatureFromTWKB(
            sourceSrid: 4326,
            id: .string("f1"),
            properties: ["a": 1 as Sendable])
        #expect(feature?.id == .string("f1"))
        #expect(feature?.geometry is Point)
        #expect(feature?.properties["a"] as? Int == 1)
    }

    @Test
    func dataAsFeatureFromTWKBSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let feature = data.asFeatureFromTWKB(sourceProjection: .epsg4326)
        #expect(feature?.geometry is Point)
    }

    @Test
    func dataAsFeatureFromTWKBBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(data.asFeatureFromTWKB(sourceProjection: .epsg4326) == nil)
    }

    @Test
    func dataAsFeatureCollectionFromTWKBSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = data.asFeatureCollectionFromTWKB(sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    @Test
    func dataAsFeatureCollectionFromTWKBSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = data.asFeatureCollectionFromTWKB(sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    @Test
    func dataAsFeatureCollectionFromTWKBBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(data.asFeatureCollectionFromTWKB(sourceProjection: .epsg4326) == nil)
    }

}

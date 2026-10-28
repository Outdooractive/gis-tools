import Foundation
@testable import GISTools
import Testing

struct TWKBTests {

    // Validates decoding a TWKB Point at the origin (0, 0).
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

        let point = try #require(result as? Point)
        #expect(point.coordinate.latitude == 0.0)
        #expect(point.coordinate.longitude == 0.0)
    }

    // Validates decoding a TWKB Point at non-zero coordinates.
    @Test
    func decodePointNonzero() async throws {
        // Point at (12, 34), precision 0 (raw degrees, scale=1):
        // Header: type=1, precision=0 → 0x01
        // Metadata: 0x00
        // x=12: zigzag(12*1)=24, varint of 24 = 0x18
        // y=34: zigzag(34*1)=68, varint of 68 = 0x44
        let bytes: [UInt8] = [0x01, 0x00, 0x18, 0x44]
        let data = Data(bytes)

        let point = try #require(try TWKBCoder.decode(twkb: data) as? Point)
        #expect(point.coordinate == Coordinate3D(latitude: 34.0, longitude: 12.0))
    }

    // Validates decoding a TWKB LineString with two points.
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

        let lineString = try #require(try TWKBCoder.decode(twkb: data) as? LineString)

        #expect(lineString.coordinates == [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
        ])
    }

    // Validates decoding a TWKB Polygon with one implicitly closed ring.
    @Test
    func decodePolygon() async throws {
        // Polygon with 1 ring, 3 points: (0,0)→(10,0)→(10,10), precision 1.
        // TWKB rings are implicitly closed, so the decoded ring has 4 positions.
        // Header: type=3, precision=1 → 0x13
        // Metadata: 0x00
        // Ring count: 1 → 0x01
        // Point count: 3 → 0x03
        // x0=0 → 0x00, y0=0 → 0x00
        // x1=100 (delta, scale 10): zigzag(100)=200 → varint(200) = 0xC8, 0x01
        // y1=0 (delta): zigzag(0)=0 → 0x00
        // x2=0 (delta from 100): zigzag(0)=0 → 0x00
        // y2=100 (delta from 0): zigzag(100)=200 → varint(200) = 0xC8, 0x01
        let bytes: [UInt8] = [
            0x13, 0x00,    // header + metadata
            0x01,          // ring count
            0x03,          // point count
            0x00, 0x00,    // x0, y0
            0xC8, 0x01,    // x1 = 100
            0x00,          // y1 = 0
            0x00,          // x2 = 0
            0xC8, 0x01,    // y2 = 100
        ]
        let data = Data(bytes)

        let polygon = try #require(try TWKBCoder.decode(twkb: data) as? Polygon)

        #expect(polygon.coordinates == [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
    }

    // Validates decoding a TWKB MultiPoint with two points.
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

        let multiPoint = try #require(try TWKBCoder.decode(twkb: data) as? MultiPoint)

        #expect(multiPoint.coordinates == [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
        ])
    }

    // Validates that decoding an empty TWKB data throws an error.
    @Test
    func decodeEmptyFails() async throws {
        #expect(throws: TWKBCoder.TWKBError.self) {
            try _ = TWKBCoder.decode(twkb: Data())
        }
    }

    // MARK: - sourceSrid decode

    // Validates decoding TWKB data with a known source SRID.
    @Test
    func decodeSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let result = try TWKBCoder.decode(twkb: data, sourceSrid: 4326)
        #expect(result is Point)
    }

    // Validates that an unknown source SRID causes a TWKB decoding error.
    @Test
    func decodeSourceSridUnknown() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        #expect(throws: TWKBCoder.TWKBError.self) {
            try _ = TWKBCoder.decode(twkb: data, sourceSrid: 9999)
        }
    }

    // MARK: - GeoJsonGeometry convenience

    // Validates creating a Point from TWKB data with a source SRID.
    @Test
    func geoJsonGeometryInitSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let point = Point(twkb: data, sourceSrid: 4326)
        #expect(point?.coordinate.latitude == 0.0)
    }

    // Validates creating a Point from TWKB data with a source projection.
    @Test
    func geoJsonGeometryInitSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let point = Point(twkb: data, sourceProjection: .epsg4326)
        #expect(point?.coordinate.latitude == 0.0)
    }

    // Validates creating a Point from TWKB data using the default projection.
    @Test
    func geoJsonGeometryInitDefaultProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let point = Point(twkb: data)
        #expect(point?.coordinate.latitude == 0.0)
    }

    // Validates that initializing a Point from bad TWKB data returns nil.
    @Test
    func geoJsonGeometryInitBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(Point(twkb: data) == nil)
    }

    // Validates parsing a geometry from TWKB data with a source SRID.
    @Test
    func geoJsonGeometryParseSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = GeometryCollection.parse(twkb: data, sourceSrid: 4326)
        #expect(geometry is Point)
    }

    // Validates parsing a geometry from TWKB data with a source projection.
    @Test
    func geoJsonGeometryParseSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = GeometryCollection.parse(twkb: data, sourceProjection: .epsg4326)
        #expect(geometry is Point)
    }

    // Validates that parsing bad TWKB data returns nil.
    @Test
    func geoJsonGeometryParseBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(GeometryCollection.parse(twkb: data) == nil)
    }

    // MARK: - Feature convenience

    // Validates creating a Feature from TWKB data with a source SRID.
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

    // Validates creating a Feature from TWKB data with a source projection.
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

    // Validates that creating a Feature from bad TWKB data returns nil.
    @Test
    func featureInitBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(Feature(twkb: data) == nil)
    }

    // MARK: - FeatureCollection convenience

    // Validates creating a FeatureCollection from TWKB data with a source SRID.
    @Test
    func featureCollectionInitSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = FeatureCollection(twkb: data, sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    // Validates creating a FeatureCollection from TWKB data with a source projection.
    @Test
    func featureCollectionInitSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = FeatureCollection(twkb: data, sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    // Validates that creating a FeatureCollection from bad TWKB data returns nil.
    @Test
    func featureCollectionInitBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(FeatureCollection(twkb: data) == nil)
    }

    // MARK: - Data convenience

    // Validates decoding TWKB Data to a geometry using a source SRID.
    @Test
    func dataAsGeoJsonGeometryFromTWKBSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = data.asGeoJsonGeometryFromTWKB(sourceSrid: 4326)
        #expect(geometry is Point)
    }

    // Validates decoding TWKB Data to a geometry using a source projection.
    @Test
    func dataAsGeoJsonGeometryFromTWKBSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let geometry = data.asGeoJsonGeometryFromTWKB(sourceProjection: .epsg4326)
        #expect(geometry is Point)
    }

    // Validates that decoding bad TWKB Data to a geometry returns nil.
    @Test
    func dataAsGeoJsonGeometryFromTWKBBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(data.asGeoJsonGeometryFromTWKB(sourceProjection: .epsg4326) == nil)
    }

    // Validates decoding TWKB Data to a Feature using a source SRID.
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

    // Validates decoding TWKB Data to a Feature using a source projection.
    @Test
    func dataAsFeatureFromTWKBSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let feature = data.asFeatureFromTWKB(sourceProjection: .epsg4326)
        #expect(feature?.geometry is Point)
    }

    // Validates that decoding bad TWKB Data to a Feature returns nil.
    @Test
    func dataAsFeatureFromTWKBBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(data.asFeatureFromTWKB(sourceProjection: .epsg4326) == nil)
    }

    // Validates decoding TWKB Data to a FeatureCollection using a source SRID.
    @Test
    func dataAsFeatureCollectionFromTWKBSourceSrid() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = data.asFeatureCollectionFromTWKB(sourceSrid: 4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    // Validates decoding TWKB Data to a FeatureCollection using a source projection.
    @Test
    func dataAsFeatureCollectionFromTWKBSourceProjection() async throws {
        let bytes: [UInt8] = [0x61, 0x00, 0x00, 0x00]
        let data = Data(bytes)

        let fc = data.asFeatureCollectionFromTWKB(sourceProjection: .epsg4326)
        #expect(fc?.features.isNotEmpty == true)
        #expect(fc?.features.first?.geometry is Point)
    }

    // Validates that decoding bad TWKB Data to a FeatureCollection returns nil.
    @Test
    func dataAsFeatureCollectionFromTWKBBadData() async throws {
        let data = Data([0xFF, 0xFF])
        #expect(data.asFeatureCollectionFromTWKB(sourceProjection: .epsg4326) == nil)
    }

}

// MARK: - GeoJSON audit regressions

extension TWKBTests {

    /// Extended Z dimensions use the extended precision byte.
    @Test
    func twkbPointWithZ() throws {
        let data = Data([0x01, 0x08, 0x01, 0x02, 0x04, 0x06])
        let point = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate == Coordinate3D(
            latitude: 2.0,
            longitude: 1.0,
            altitude: 3.0))
    }

    /// Extended M dimensions use the extended precision byte.
    @Test
    func twkbPointWithM() throws {
        let data = Data([0x01, 0x08, 0x02, 0x02, 0x04, 0x08])
        let point = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate == Coordinate3D(
            latitude: 2.0,
            longitude: 1.0,
            m: 4.0))
    }

    /// Bounding boxes in the TWKB metadata are skipped before the geometry data.
    @Test
    func twkbPointWithBoundingBox() throws {
        let data = Data([0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x02, 0x04])
        let point = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate == Coordinate3D(latitude: 2.0, longitude: 1.0))
    }

    /// Size metadata is skipped before the geometry data.
    @Test
    func twkbPointWithSize() throws {
        let data = Data([0x01, 0x02, 0x02, 0x02, 0x04])
        let point = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate == Coordinate3D(latitude: 2.0, longitude: 1.0))
    }

    /// ID lists in collections are skipped before the coordinate data.
    @Test
    func twkbMultiPointWithIDList() throws {
        let data = Data([0x04, 0x04, 0x02, 0x00, 0x00, 0x00, 0x00, 0x02, 0x04])
        let multiPoint = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? MultiPoint)

        #expect(multiPoint.coordinates == [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
        ])
    }

    /// Empty geometry metadata decodes as an empty geometry.
    @Test
    func twkbEmptyMetadataDecoding() throws {
        let data = Data([0x02, 0x10])

        let lineString = try #require(
            try TWKBCoder.decode(
                twkb: data,
                sourceProjection: .epsg4326) as? LineString,
        )

        #expect(lineString.coordinates.isEmpty)
    }

    /// Negative precision is stored with zigzag encoding in the type byte.
    @Test
    func twkbNegativePrecision() throws {
        let data = Data([0xF1, 0x00, 0x14, 0x00])
        let point = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? Point)

        #expect(point.coordinate == Coordinate3D(latitude: 0.0, longitude: 100.0))
    }

    /// Overlong TWKB varints fail instead of overflowing the decoder.
    @Test
    func twkbOverlongVarIntFails() {
        let data = Data([0x01, 0x00] + Array(repeating: 0x80, count: 11) + [0x00])

        #expect(throws: TWKBCoder.TWKBError.self) {
            try TWKBCoder.decode(twkb: data, sourceProjection: .epsg4326)
        }
    }

    /// Trailing bytes are not silently ignored.
    @Test
    func twkbTrailingBytesFail() {
        let data = Data([0x61, 0x00, 0x00, 0x00, 0x00])

        #expect(throws: TWKBCoder.TWKBError.self) {
            try TWKBCoder.decode(twkb: data, sourceProjection: .epsg4326)
        }
    }

    // MARK: - Empty geometries and surfaces

    /// PostGIS: ST_AsTWKB('POINT EMPTY'::geometry)
    @Test
    func twkbEmptyPointDecoding() throws {
        let multiPoint = try #require(try TWKBCoder.decode(
            twkb: Data([0xA1, 0x10]),
            sourceProjection: .epsg4326) as? MultiPoint)

        #expect(multiPoint.points.isEmpty)
    }

    /// PostGIS emits a metadata-only TWKB for empty geometries.
    @Test
    func twkbEmptyGeometryDecoding() throws {
        let cases: [(Data, GeoJsonType)] = [
            (Data([0xA2, 0x10]), .lineString),
            (Data([0xA3, 0x10]), .polygon),
            (Data([0xA4, 0x10]), .multiPoint),
            (Data([0xA5, 0x10]), .multiLineString),
            (Data([0xA6, 0x10]), .multiPolygon),
            (Data([0xA7, 0x10]), .geometryCollection),
        ]

        for (data, expectedType) in cases {
            let geometry = try TWKBCoder.decode(
                twkb: data,
                sourceProjection: .epsg4326)
            #expect(geometry.type == expectedType)
            #expect(geometry.allCoordinates.isEmpty)
        }
    }

    /// PostGIS encodes TIN as a TWKB GeometryCollection of Polygons.
    @Test
    func twkbTinDecoding() throws {
        // PostGIS: ST_AsTWKB('TIN(((0 0 0, 1 0 0, 0 1 0, 0 0 0)))'::geometry)
        let data = try #require(Data(hex: "A7080101A308010104000000C09A0C0000BF9A0CC09A0C0000BF9A0C00"))

        let collection = try #require(try TWKBCoder.decode(
            twkb: data,
            sourceProjection: .epsg4326) as? GeometryCollection)

        #expect(collection.geometries.count == 1)
        #expect(collection.geometries[0] is Polygon)
    }

    /// TWKB has no curve or PolyhedralSurface type codes.
    @Test
    func twkbUnsupportedTypeFails() {
        for typeCode: UInt8 in [0x08, 0x0F, 0x10] {
            let data = Data([typeCode, 0x00])

            #expect(throws: TWKBCoder.TWKBError.self) {
                try TWKBCoder.decode(twkb: data, sourceProjection: .epsg4326)
            }
        }
    }

}

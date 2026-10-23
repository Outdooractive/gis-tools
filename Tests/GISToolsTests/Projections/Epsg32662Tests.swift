#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

// Algorithm smoke tests in EPSG:32662 (WGS 84 / Plate Carree).
//
// EPSG:32662 is equirectangular in metres (`x = a·λ`, `y = a·φ`), not
// degrees. The fixtures below use its real coordinate range: the horizontal
// wraparound axis is at ±`GISTool.originShift` (20,037,508.34 m) and the
// vertical extent is ±`GISTool.originShift / 2` (10,018,754.17 m).
struct Epsg32662AlgorithmTests {

    // Validates that EPSG:32662 is treated as planar (Euclidean) by
    // distance, consistent with its kind.
    @Test
    func distance() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662)
        let point = Coordinate3D(x: 3.0, y: 4.0, projection: .epsg32662)

        #expect(abs(origin.distance(from: point) - 5.0) < 0.000001)
    }

    // Validates bounding box calculation and containment in EPSG:32662.
    @Test
    func boundingBoxAndContains() async throws {
        let coordinates: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662),
            Coordinate3D(x: 10.0, y: 0.0, projection: .epsg32662),
            Coordinate3D(x: 10.0, y: 10.0, projection: .epsg32662),
            Coordinate3D(x: 0.0, y: 10.0, projection: .epsg32662),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662),
        ]]
        let polygon = try #require(Polygon(coordinates, calculateBoundingBox: true))

        #expect(polygon.projection == .epsg32662)

        let boundingBox = try #require(polygon.boundingBox)
        #expect(boundingBox.projection == .epsg32662)
        #expect(boundingBox.southWest.x == 0.0)
        #expect(boundingBox.northEast.y == 10.0)

        #expect(polygon.contains(Coordinate3D(x: 5.0, y: 5.0, projection: .epsg32662)))
        #expect(!polygon.contains(Coordinate3D(x: 15.0, y: 5.0, projection: .epsg32662)))
    }

    // Validates antimeridian detection and cutting in EPSG:32662, where the
    // wraparound axis is at ±`GISTool.originShift` metres.
    @Test
    func antimeridian() async throws {
        let extent = GISTool.originShift
        let lineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: extent - 1_000_000.0, y: 5_009_377.085697311, projection: .epsg32662),
            Coordinate3D(x: -extent + 1_000_000.0, y: 5_009_377.085697311, projection: .epsg32662),
        ]
        let line = LineString(unchecked: lineCoordinates)

        #expect(line.crossesAntimeridian)

        let cut = line.cutAtAntimeridian()
        #expect(cut.features.count == 2)

        // Cut points are at ±extent.
        let first = try #require((cut.features[0].geometry as? LineString)?.coordinates.last)
        let second = try #require((cut.features[1].geometry as? LineString)?.coordinates.first)
        #expect(abs(first.longitude) == extent)
        #expect(abs(second.longitude) == extent)

        // A line not crossing the axis stays untouched.
        let plainLineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662),
            Coordinate3D(x: 10.0, y: 10.0, projection: .epsg32662),
        ]
        let plainLine = LineString(unchecked: plainLineCoordinates)
        #expect(!plainLine.crossesAntimeridian)
        #expect(plainLine.cutAtAntimeridian().features.count == 1)
    }

    // Validates normalize/clamp behavior in EPSG:32662.
    @Test
    func normalizeAndClamp() async throws {
        let extent = GISTool.originShift
        let normalized = Coordinate3D(x: extent + 1_000_000.0, y: 0.0, projection: .epsg32662).normalized()
        #expect(abs(normalized.longitude - (-extent + 1_000_000.0)) < 0.000001)

        let clamped = Coordinate3D(x: extent + 1_000_000.0, y: extent, projection: .epsg32662).clamped()
        #expect(clamped.longitude == extent)
        #expect(clamped.latitude == extent / 2.0)
    }

    // Validates WKB round trips in the new projections (the SRID is embedded
    // in the WKB data).
    @Test
    func wkbRoundTrip() async throws {
        for projection: Projection in [.epsg3395, .epsg32662] {
            let point = Point(Coordinate3D(x: 123.0, y: 456.0, projection: projection))

            let wkb = try #require(WKBCoder.encode(geometry: point, targetProjection: projection))
            let decoded = try #require(WKBCoder.decode(
                wkb: wkb,
                sourceSrid: nil,
                targetProjection: projection) as? Point)
            #expect(decoded.projection == projection)
            #expect(abs(decoded.coordinate.x - 123.0) < 0.0000000001)
            #expect(abs(decoded.coordinate.y - 456.0) < 0.0000000001)
        }
    }

    // MARK: - WKT

    // Validates WKT round trips in the new projections, with the SRID
    // embedded in the WKT string.
    @Test
    func wktRoundTrip() async throws {
        for projection: Projection in [.epsg3395, .epsg32662] {
            let point = Point(Coordinate3D(x: 123.0, y: 456.0, projection: projection))

            let wkt = try #require(WKTCoder.encode(geometry: point, targetProjection: projection))
            let decoded = try #require(WKTCoder.decode(
                wkt: wkt,
                sourceSrid: nil,
                targetProjection: projection) as? Point)
            #expect(decoded.projection == projection)
            #expect(abs(decoded.coordinate.x - 123.0) < 0.0000000001)
            #expect(abs(decoded.coordinate.y - 456.0) < 0.0000000001)
        }
    }

    // MARK: - TWKB

    // Validates TWKB decoding with the new source projections.
    //
    // Fixture: POINT, precision 0, x=100, y=200 as zigzag varints
    // (zigzag(100) = 200 = 0xC8 0x01, zigzag(200) = 400 = 0x90 0x03).
    @Test
    func twkbDecode() async throws {
        let bytes: [UInt8] = [0x01, 0x00, 0xC8, 0x01, 0x90, 0x03]

        for projection: Projection in [.epsg3395, .epsg32662] {
            let result = try #require(TWKBCoder.decode(
                twkb: Data(bytes),
                sourceSrid: projection.srid,
                targetProjection: projection) as? Point)
            #expect(result.projection == projection)
            #expect(result.coordinate.x == 100.0)
            #expect(result.coordinate.y == 200.0)
        }
    }

}

/// WKT matcher tests for the registry-driven `Projection.init?(wkt:)`.

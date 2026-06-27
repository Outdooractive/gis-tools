import Testing
import Foundation
@testable import GISTools

struct DensifyTests {

    // Validates that a short segment (shorter than maxSegmentLength) is unchanged.
    @Test
    func shortSegmentUnchanged() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 600_000.0)
        #expect(densified.coordinates.count == 2)
    }

    // Validates that a long segment is split into multiple vertices.
    @Test
    func longSegmentSplit() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 340_000.0)
        #expect(densified.coordinates.count == 5)
    }

    // Validates that endpoints remain unchanged after densification.
    @Test
    func endpointsUnchanged() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 220_000.0)
        #expect(densified.coordinates.first?.latitude == 0.0)
        #expect(densified.coordinates.first?.longitude == 0.0)
        #expect(densified.coordinates.last?.latitude == 10.0)
        #expect(densified.coordinates.last?.longitude == 10.0)
    }

    // Validates that a MultiLineString is densified correctly.
    @Test
    func multiLineString() async throws {
        let mls = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
            ],
        ]))
        let densified = mls.densified(maxSegmentLength: 340_000.0)
        #expect(densified.lineStrings.count == 2)
        for ls in densified.lineStrings {
            #expect(ls.coordinates.count > 2)
        }
    }

    // Validates that a Polygon is densified.
    @Test
    func polygon() async throws {
        let poly = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let densified = poly.densified(maxSegmentLength: 340_000.0)
        let coords = densified.coordinates[0]
        #expect(coords.count > 5)
    }

    // Validates that a MultiPolygon is densified.
    @Test
    func multiPolygon() async throws {
        let mpPoly = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let mp = try #require(MultiPolygon([
            mpPoly,
        ]))
        let densified = mp.densified(maxSegmentLength: 220_000.0)
        #expect(densified.polygons.count == 1)
    }

    // Validates that a Point is unchanged by densification.
    @Test
    func pointUnchanged() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let densified = point.densified(maxSegmentLength: 1.0)
        #expect(densified.coordinate.latitude == 0.0)
        #expect(densified.coordinate.longitude == 0.0)
    }

    // MARK: - Altitude / Z

    // Validates altitude is linearly interpolated between endpoints.
    @Test
    func altitudePreserved() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 600_000.0)
        #expect(densified.coordinates.count == 3)
        #expect(densified.coordinates[0].altitude == 100.0)
        #expect(densified.coordinates[1].altitude == 150.0)
        #expect(densified.coordinates[2].altitude == 200.0)
    }

    // MARK: - Projections

    // Validates densify in EPSG:3857 projection.
    @Test
    func densify3857() async throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 200_000.0)
        #expect(densified.coordinates.count > 2)
    }

    // Validates densify in EPSG:4978.
    @Test
    func densify4978() async throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, z: 0.0, projection: .epsg4978),
        ]))
        let densified = ls.densified(maxSegmentLength: 200_000.0)
        #expect(densified.coordinates.count > 2)
    }

    // Validates densify in noSRID.
    @Test
    func densifyNoSRID() async throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .noSRID),
        ]))
        let densified = ls.densified(maxSegmentLength: 200_000.0)
        #expect(densified.coordinates.count > 2)
    }

    // MARK: - Antimeridian

    // Validates densify across the antimeridian for a LineString.
    @Test
    func antimeridianLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 1_113_250.0)
        #expect(densified.coordinates.count > 2)
        #expect(densified.coordinates.first?.latitude == 0.0)
        #expect(densified.coordinates.first?.longitude == 170.0)
        #expect(densified.coordinates.last?.latitude == 10.0)
        #expect(densified.coordinates.last?.longitude == -170.0)
    }

    // Validates densify on a Polygon crossing the antimeridian.
    @Test
    func antimeridianPolygon() async throws {
        let poly = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        let densified = poly.densified(maxSegmentLength: 600_000.0)
        let ring = densified.coordinates[0]
        #expect(ring.count > 5)
        #expect(ring.first?.latitude == 0.0)
        #expect(ring.first?.longitude == 170.0)
    }

    // MARK: - Edge cases

    // Validates densify handles a single-vertex LineString.
    @Test
    func singleVertexLine() async throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0)
        ])
        let densified = ls.densified(maxSegmentLength: 1.0)
        #expect(densified.coordinates.count == 1)
    }

    // Validates that zero maxSegmentLength returns the original.
    @Test
    func zeroInterval() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 0.0)
        #expect(densified.coordinates.count == 2)
    }

}

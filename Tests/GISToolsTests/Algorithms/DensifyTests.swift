import Testing
import Foundation
@testable import GISTools

struct DensifyTests {

    // Validates that a short segment (shorter than maxSegmentLength) is unchanged.
    @Test
    func shortSegmentUnchanged() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ])!
        let densified = ls.densified(maxSegmentLength: 600_000.0)
        #expect(densified.coordinates.count == 2)
    }

    // Validates that a long segment is split into multiple vertices.
    @Test
    func longSegmentSplit() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
        let densified = ls.densified(maxSegmentLength: 340_000.0)
        // 10°≈1.1M meters / 340K ≈ 3.33 → ceil = 4 steps → 5 vertices
        #expect(densified.coordinates.count == 5)
    }

    // Validates that the densified line still connects the same endpoints.
    @Test
    func endpointsUnchanged() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let densified = ls.densified(maxSegmentLength: 220_000.0)
        #expect(densified.coordinates.first?.latitude == 0.0)
        #expect(densified.coordinates.first?.longitude == 0.0)
        #expect(densified.coordinates.last?.latitude == 10.0)
        #expect(densified.coordinates.last?.longitude == 10.0)
    }

    // Validates that a MultiLineString is densified correctly.
    @Test
    func multiLineString() async throws {
        let mls = MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
            ],
        ])!
        let densified = mls.densified(maxSegmentLength: 340_000.0)
        #expect(densified.lineStrings.count == 2)
        for ls in densified.lineStrings {
            #expect(ls.coordinates.count > 2)
        }
    }

    // Validates that a Polygon is densified (each ring).
    @Test
    func polygon() async throws {
        let poly = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let densified = poly.densified(maxSegmentLength: 340_000.0)
        // Each edge is 10°≈1.1M meters, split by 340K → 4 segments
        // But vertices are shared at corners, so total is 4 edges × 4 segments = 16 + 1 close
        let coords = densified.coordinates[0]
        #expect(coords.count > 5)
    }

    // Validates that a MultiPolygon is densified.
    @Test
    func multiPolygon() async throws {
        let mp = MultiPolygon([
            Polygon([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 0.0, longitude: 5.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                    Coordinate3D(latitude: 5.0, longitude: 0.0),
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                ],
            ])!,
        ])!
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

    // Validates that a single-vertex LineString is unchanged.
    @Test
    func singleVertexLine() async throws {
        let ls = LineString(unchecked: [Coordinate3D(latitude: 0.0, longitude: 0.0)])
        let densified = ls.densified(maxSegmentLength: 1.0)
        #expect(densified.coordinates.count == 1)
    }

    // Validates that densify with zero maxSegmentLength returns the original.
    @Test
    func zeroInterval() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
        let densified = ls.densified(maxSegmentLength: 0.0)
        #expect(densified.coordinates.count == 2)
    }

    // Validates that densify preserves altitude through interpolation.
    @Test
    func altitudePreserved() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
        ])!
        let densified = ls.densified(maxSegmentLength: 600_000.0)
        // 10°≈1.1M meters / 600K ≈ 1.86 → ceil = 2 steps → 3 vertices
        #expect(densified.coordinates.count == 3)
        #expect(densified.coordinates[0].altitude == 100.0)
        #expect(densified.coordinates[1].altitude == 150.0)
        #expect(densified.coordinates[2].altitude == 200.0)
    }

    // Validates that densify works on a LineString crossing the antimeridian (170°E to 170°W).
    @Test
    func antimeridianLineString() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
        ])!
        let densified = ls.densified(maxSegmentLength: 1_113_250.0)
        // Spans 340° of longitude, splits into segments of ≤10° (≈1.1M m)
        #expect(densified.coordinates.count > 2)
        #expect(densified.coordinates.first?.latitude == 0.0)
        #expect(densified.coordinates.first?.longitude == 170.0)
        #expect(densified.coordinates.last?.latitude == 10.0)
        #expect(densified.coordinates.last?.longitude == -170.0)
    }

    // Validates that densify works on a Polygon crossing the antimeridian.
    @Test
    func antimeridianPolygon() async throws {
        let poly = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!
        let densified = poly.densified(maxSegmentLength: 600_000.0)
        let ring = densified.coordinates[0]
        #expect(ring.count > 5)
        #expect(ring.first?.latitude == 0.0)
        #expect(ring.first?.longitude == 170.0)
    }

    // MARK: - EPSG:3857

    @Test
    func densify3857() async throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0),
        ]))
        let densified = ls.densified(maxSegmentLength: 200_000.0)
        #expect(densified.coordinates.count > 2)
    }

    // Validates that densify works on a MultiLineString crossing the antimeridian.
    @Test
    func antimeridianMultiLineString() async throws {
        let mls = MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: 175.0),
            ],
        ])!
        let densified = mls.densified(maxSegmentLength: 1_113_250.0)
        #expect(densified.lineStrings.count == 2)
        for ls in densified.lineStrings {
            #expect(ls.coordinates.count > 2)
        }
    }

}

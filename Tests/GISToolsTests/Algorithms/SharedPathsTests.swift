import Testing
import Foundation
@testable import GISTools

struct SharedPathsTests {

    // Validates that two identical LineStrings share all their segments.
    @Test
    func identicalLineStrings() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 2)
    }


    @Test
    func sharedPathsNoSRID() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 50.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 50.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 1)
        #expect(result?.lineStrings.first?.projection == .noSRID)
    }

    // MARK: - Projection preservation

    @Test
    func sharedPaths3857Projection() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 500_000.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]))
        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result?.lineStrings.first?.projection == .epsg3857)
    }

    @Test
    func sharedPaths4978Projection() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result?.lineStrings.first?.projection == .epsg4978)
    }
    // Validates that two LineStrings with one shared segment find that segment.
    @Test
    func partiallyShared() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        // Shared: (5,0)→(10,0)
        #expect(result!.lineStrings.count == 1)
    }

    // Validates that reversed segments also match.
    @Test
    func reversedSegment() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 1)
    }

    // Validates that non-overlapping geometries return nil.
    @Test
    func noSharedPaths() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result == nil)
    }

    // Validates that sharedPaths works with MultiLineString inputs.
    @Test
    func multiLineStrings() async throws {
        let a = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 15.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
            ],
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        // Shared: (0,0)→(5,0)
        #expect(result!.lineStrings.count == 1)
    }

    // Validates that sharedPaths deduplicates matching segments.
    @Test
    func duplicateSegments() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let b = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ],
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        // Should only report (0,0)→(5,0) once
        #expect(result!.lineStrings.count == 1)
    }

    // Validates that gridSize parameter snaps coordinates for matching.
    @Test
    func sharedWithGridSize() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.001),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))

        // Without gridSize, these don't match (0.001 diff)
        let without = a.sharedPaths(with: b)
        #expect(without == nil)

        // With gridSize=1.0, coordinates snap to integer grid
        let with = a.sharedPaths(with: b, gridSize: 1.0)
        #expect(with != nil)
        #expect(with!.lineStrings.count == 1)
    }

    // Validates shared paths between a LineString and a Polygon (extracts ring segments).
    @Test
    func lineAndPolygon() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 1)
    }

    // Validates that FeatureCollections extract their geometries' segments.
    @Test
    func featureCollections() async throws {
        let a = FeatureCollection([
            Feature(try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ]))),
        ])
        let b = FeatureCollection([
            Feature(try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ]))),
        ])

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
    }

    // Validates shared paths between two LineStrings crossing the antimeridian.
    @Test
    func antimeridianLineStrings() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 5.0, longitude: -170.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 5.0, longitude: -170.0),
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        // Two shared segments (170,0)→(-170,0) and (-170,0)→(-170,5)
        #expect(result!.lineStrings.count == 2)
    }

    // MARK: - Projections

    @Test
    func sharedPaths3857() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 500_000.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 1)
    }

    @Test
    func sharedPaths4978() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 1)
    }

    // Validates shared paths across the antimeridian with reversed segment.
    @Test
    func antimeridianReversed() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]))

        let result = a.sharedPaths(with: b)
        #expect(result != nil)
        #expect(result!.lineStrings.count == 1)
    }

}

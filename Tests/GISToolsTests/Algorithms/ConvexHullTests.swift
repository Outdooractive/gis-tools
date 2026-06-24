import Foundation
@testable import GISTools
import Testing

struct ConvexHullTests {

    // Validates the convex hull of a square produces 5 coordinates (4 corners + closing) and contains a center point.
    @Test
    func convexHullSquare() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5) // 4 corners + closing point
        #expect(hull.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
    }

    // Validates the convex hull of a triangle produces 4 coordinates (3 corners + closing).
    @Test
    func convexHullTriangle() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 4) // 3 corners + closing
    }

    // Validates interior points are excluded from the convex hull of a square.
    @Test
    func convexHullWithInteriorPoint() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),  // interior point
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5) // 4 corners + closing
    }

    // Validates the convex hull correctly handles collinear points along the top edge.
    @Test
    func convexHullCollinearTop() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 10.0),
            Coordinate3D(latitude: 7.0, longitude: 10.0),
        ]))

        let hull = try #require(mp.convexHull())
        // Should have 4 points: bottom-left, bottom-right, top-right, top-left
        #expect(hull.outerRing?.coordinates.count == 5)
    }

    // Validates that fewer than 3 distinct points returns nil for the convex hull.
    @Test
    func convexHullInsufficientPoints() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(mp.convexHull() == nil)
    }

    // Validates the convex hull computed from a LineString produces the expected result.
    @Test
    func convexHullLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))

        let hull = try #require(ls.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5)
    }

    // Validates the convex hull of points straddling the antimeridian produces a valid result.
    @Test
    func convexHullCrossingAntimeridian() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: -175.0),
            Coordinate3D(latitude: 5.0, longitude: 180.0),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count ?? 0 >= 4)
        #expect(hull.isValid)
    }

    // Validates the convex hull of a 1000×1000 m polygon in EPSG:3857.
    @Test
    func convexHull3857() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5)
        #expect(hull.area > 0.0)
    }

    // Validates the convex hull of points in EPSG:4978 (XY plane).
    @Test
    func convexHull4978() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1000.0, y: 1000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 1000.0, z: 0.0, projection: .epsg4978),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5)
    }

    // Validates the convex hull of points in noSRID.
    @Test
    func convexHullNoSRID() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5)
    }

    // Validates the convex hull computed from a Feature wrapping a MultiPoint produces the expected result.
    @Test
    func convexHullFeature() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let feature = Feature(mp)
        let hull = try #require(feature.convexHull())
        #expect(hull.outerRing?.coordinates.count == 4)
    }

}

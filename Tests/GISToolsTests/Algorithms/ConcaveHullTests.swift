import Foundation
@testable import GISTools
import Testing

struct ConcaveHullTests {

    // Validates basic concave hull of points forming a rough circle.
    @Test
    func concaveHullBasic() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.5),
        ]))

        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates that a large maxEdgeLength approximates the convex hull.
    @Test
    func concaveHullLargeMaxEdge() async throws {
        let maxEdge2000km = GISTool.convertToMeters(2000, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge2000km))
        let coords = try #require(hull.polygons.first?.outerRing?.coordinates)
        #expect(coords.count >= 4) // at least the 4 corners
    }

    // Validates that insufficient points returns nil.
    @Test
    func concaveHullInsufficientPoints() async throws {
        let maxEdge100km = GISTool.convertToMeters(100, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(mp.concaveHull(maxEdgeLength: maxEdge100km) == nil)
    }

    // Validates that a very small maxEdgeLength returns nil (no triangles pass the filter).
    @Test
    func concaveHullTooSmallMaxEdge() async throws {
        let maxEdge1m = GISTool.convertToMeters(1, .meters)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))

        let hull = mp.concaveHull(maxEdgeLength: maxEdge1m)
        #expect(hull == nil)
    }

    // Validates concave hull from a LineString works.
    @Test
    func concaveHullLineString() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))

        let hull = try #require(ls.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates concave hull from a Feature works.
    @Test
    func concaveHullFeature() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let feature = Feature(mp)
        let hull = try #require(feature.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates that the concave hull contains all input points.
    @Test
    func concaveHullContainsAllPoints() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let inputPoints = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]
        let mp = try #require(MultiPoint(inputPoints))

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge200km))
        let polygon = try #require(hull.polygons.first)

        for point in inputPoints {
            #expect(polygon.contains(point, ignoringBoundary: false))
        }
    }

}

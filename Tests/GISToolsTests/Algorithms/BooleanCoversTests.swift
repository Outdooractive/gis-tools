import Foundation
@testable import GISTools
import Testing

struct BooleanCoversTests {

    // Validates that a polygon covers a point inside it.
    @Test
    func polygonCoversInteriorPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(polygon.covers(point))
        #expect(polygon.contains(point))
    }

    // Validates that a polygon covers a point on its boundary.
    @Test
    func polygonCoversBoundaryPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let pointOnEdge = Point(Coordinate3D(latitude: 0.0, longitude: 5.0))
        #expect(polygon.covers(pointOnEdge))
    }

    // Validates that a polygon does not cover a point outside it.
    @Test
    func polygonDoesNotCoverExteriorPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(polygon.covers(point) == false)
    }

    // Validates that a polygon covers a line string on its boundary.
    @Test
    func polygonCoversLineOnBoundary() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0)]))
        #expect(polygon.covers(line))
    }

    // Validates that a polygon covers an identical polygon.
    @Test
    func polygonCoversIdentical() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        #expect(polygon.covers(polygon))
    }

    // Validates coveredBy is the inverse of covers.
    @Test
    func coveredByInverse() async throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        #expect(outer.covers(inner))
        #expect(inner.coveredBy(outer))
    }

    // Validates point covers identical point.
    @Test
    func pointCoversPoint() async throws {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(point1.covers(point2))
        #expect(point2.coveredBy(point1))
    }

    // Validates point does not cover a different point.
    @Test
    func pointDoesNotCoverDifferentPoint() async throws {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 6.0, longitude: 5.0))
        #expect(point1.covers(point2) == false)
    }

    // Validates covers near the antimeridian (east side of the dateline).
    @Test
    func antimeridianNear() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 178.0), Coordinate3D(latitude: 10.0, longitude: 178.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 170.0)]]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOutside = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(polygon.covers(pointInside))
        #expect(polygon.covers(pointOutside) == false)
    }

    // Validates that a polygon crossing the antimeridian covers a point on the opposite side.
    @Test
    func antimeridianCrossingPolygonCoversPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 170.0)]]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOutside = Point(Coordinate3D(latitude: 5.0, longitude: 0.0))
        #expect(polygon.covers(pointInside))
        #expect(polygon.covers(pointOutside) == false)
    }

    // Validates coveredBy across the antimeridian.
    @Test
    func antimeridianCrossingCoveredBy() async throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: -10.0, longitude: 170.0), Coordinate3D(latitude: -10.0, longitude: -170.0), Coordinate3D(latitude: 20.0, longitude: -170.0), Coordinate3D(latitude: 20.0, longitude: 170.0), Coordinate3D(latitude: -10.0, longitude: 170.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 175.0), Coordinate3D(latitude: 0.0, longitude: -175.0), Coordinate3D(latitude: 10.0, longitude: -175.0), Coordinate3D(latitude: 10.0, longitude: 175.0), Coordinate3D(latitude: 0.0, longitude: 175.0)]]))
        #expect(outer.covers(inner))
        #expect(inner.coveredBy(outer))
    }

    // Validates line covers a point on the line.
    @Test
    func lineCoversPointOnLine() async throws {
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0)]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(line.covers(point))
    }

    // MARK: - Projection tests

    @Test
    func polygonCoversPoint3857() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let point = Point(Coordinate3D(x: 500.0, y: 500.0))
        #expect(polygon.covers(point))
    }

}

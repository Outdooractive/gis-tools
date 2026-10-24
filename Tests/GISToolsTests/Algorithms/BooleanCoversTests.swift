import Foundation
@testable import GISTools
import Testing

struct BooleanCoversTests {

    /// Validates that a polygon covers a point inside it.
    @Test
    func polygonCoversInteriorPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(polygon.covers(point))
        #expect(polygon.contains(point))
    }

    /// Validates that a polygon covers a point on its boundary.
    @Test
    func polygonCoversBoundaryPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let pointOnEdge = Point(Coordinate3D(latitude: 0.0, longitude: 5.0))
        #expect(polygon.covers(pointOnEdge))
    }

    /// Validates that a polygon does not cover a point outside it.
    @Test
    func polygonDoesNotCoverExteriorPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(polygon.covers(point) == false)
    }

    /// Validates that a polygon covers a line string on its boundary.
    @Test
    func polygonCoversLineOnBoundary() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0)]))
        #expect(polygon.covers(line))
    }

    /// A concave polygon does not cover a line whose endpoints are inside but
    /// whose segment leaves the polygon through the notch.
    @Test
    func polygonDoesNotCoverLineLeavingConcaveShape() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 6.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 1.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))

        #expect(polygon.covers(line) == false)
    }

    /// Antimeridian-crossing container with an antimeridian-crossing hole.
    @Test
    func antimeridianPolygonWithHoleCoverage() throws {
        let container = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: 175.0),
            ],
        ]))
        let aboveHole = try #require(Polygon([[
            Coordinate3D(latitude: 16.0, longitude: 176.0),
            Coordinate3D(latitude: 16.0, longitude: -176.0),
            Coordinate3D(latitude: 19.0, longitude: -176.0),
            Coordinate3D(latitude: 19.0, longitude: 176.0),
            Coordinate3D(latitude: 16.0, longitude: 176.0),
        ]]))
        let aroundHole = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 173.0),
            Coordinate3D(latitude: 3.0, longitude: -173.0),
            Coordinate3D(latitude: 17.0, longitude: -173.0),
            Coordinate3D(latitude: 17.0, longitude: 173.0),
            Coordinate3D(latitude: 3.0, longitude: 173.0),
        ]]))

        #expect(container.covers(aboveHole))
        #expect(container.covers(aroundHole) == false)
    }

    /// Validates that a polygon covers an identical polygon.
    @Test
    func polygonCoversIdentical() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        #expect(polygon.covers(polygon))
    }

    /// Validates coveredBy is the inverse of covers.
    @Test
    func coveredByInverse() throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        #expect(outer.covers(inner))
        #expect(inner.coveredBy(outer))
    }

    /// Validates point covers identical point.
    @Test
    func pointCoversPoint() {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(point1.covers(point2))
        #expect(point2.coveredBy(point1))
    }

    /// Validates point does not cover a different point.
    @Test
    func pointDoesNotCoverDifferentPoint() {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 6.0, longitude: 5.0))
        #expect(point1.covers(point2) == false)
    }

    /// Validates covers near the antimeridian (east side of the dateline).
    @Test
    func antimeridianNear() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 178.0), Coordinate3D(latitude: 10.0, longitude: 178.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 170.0)]]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOutside = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(polygon.covers(pointInside))
        #expect(polygon.covers(pointOutside) == false)
    }

    /// Validates that a polygon crossing the antimeridian covers a point on the opposite side.
    @Test
    func antimeridianCrossingPolygonCoversPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 170.0)]]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOutside = Point(Coordinate3D(latitude: 5.0, longitude: 0.0))
        #expect(polygon.covers(pointInside))
        #expect(polygon.covers(pointOutside) == false)
    }

    /// Validates coveredBy across the antimeridian.
    @Test
    func antimeridianCrossingCoveredBy() throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: -10.0, longitude: 170.0), Coordinate3D(latitude: -10.0, longitude: -170.0), Coordinate3D(latitude: 20.0, longitude: -170.0), Coordinate3D(latitude: 20.0, longitude: 170.0), Coordinate3D(latitude: -10.0, longitude: 170.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 175.0), Coordinate3D(latitude: 0.0, longitude: -175.0), Coordinate3D(latitude: 10.0, longitude: -175.0), Coordinate3D(latitude: 10.0, longitude: 175.0), Coordinate3D(latitude: 0.0, longitude: 175.0)]]))
        #expect(outer.covers(inner))
        #expect(inner.coveredBy(outer))
    }

    /// Validates line covers a point on the line.
    @Test
    func lineCoversPointOnLine() throws {
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0)]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(line.covers(point))
    }

    // MARK: - Projections

    /// Polygon covers point in EPSG:3857.
    @Test
    func polygonCoversPoint3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let point = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))
        #expect(polygon.covers(point))
    }

    /// Polygon covers point in EPSG:4978.
    @Test
    func polygonCoversPoint4978() throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = polygon4326.projected(to: .epsg4978)
        let inside = Point(Coordinate3D(latitude: 0.5, longitude: 0.5)).projected(to: .epsg4978)
        #expect(polygon.covers(inside))
    }

}

// MARK: - Projection regressions

extension BooleanCoversTests {

    @Test
    func coversLineIn3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let line = try #require(LineString([
            Coordinate3D(x: 100.0, y: 100.0, projection: .epsg3857),
            Coordinate3D(x: 900.0, y: 900.0, projection: .epsg3857),
        ]))

        #expect(polygon.covers(line))
        #expect(polygon.contains(line))
    }

    @Test
    func coversLineIn4978() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.1),
            Coordinate3D(latitude: 0.1, longitude: 0.1),
            Coordinate3D(latitude: 0.1, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])).projected(to: .epsg4978)
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.02, longitude: 0.02).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.08, longitude: 0.08).projected(to: .epsg4978),
        ]))

        #expect(polygon.covers(line))
        #expect(polygon.contains(line))
    }

    // MARK: - Audit regressions

    @Test
    func featureCollectionReceiverActsAsUnion() throws {
        let left = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let right = try #require(Polygon([[
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
        ]]))
        let spanning = try #require(Polygon([[
            Coordinate3D(x: 2.0, y: 1.0, projection: .noSRID),
            Coordinate3D(x: 8.0, y: 1.0, projection: .noSRID),
            Coordinate3D(x: 8.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 1.0, projection: .noSRID),
        ]]))

        let collection = FeatureCollection([Feature(left), Feature(right)])
        #expect(collection.covers(spanning))
        #expect(collection.contains(spanning))
    }

    @Test
    func multipolygonReceiverActsAsUnion() throws {
        let left = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let right = try #require(Polygon([[
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
        ]]))
        let multiPolygon = try #require(MultiPolygon([left, right]))
        let spanning = try #require(Polygon([[
            Coordinate3D(x: 2.0, y: 1.0, projection: .noSRID),
            Coordinate3D(x: 8.0, y: 1.0, projection: .noSRID),
            Coordinate3D(x: 8.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 1.0, projection: .noSRID),
        ]]))

        #expect(multiPolygon.covers(spanning))
        #expect(multiPolygon.contains(spanning))
    }

    @Test
    func holeBoundaryIsCoveredButNotContained() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
                Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
                Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
                Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
                Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            ],
            [
                Coordinate3D(x: 4.0, y: 4.0, projection: .noSRID),
                Coordinate3D(x: 6.0, y: 4.0, projection: .noSRID),
                Coordinate3D(x: 6.0, y: 6.0, projection: .noSRID),
                Coordinate3D(x: 4.0, y: 6.0, projection: .noSRID),
                Coordinate3D(x: 4.0, y: 4.0, projection: .noSRID),
            ],
        ]))
        let boundaryPoint = Point(Coordinate3D(x: 4.0, y: 5.0, projection: .noSRID))
        let interiorPoint = Point(Coordinate3D(x: 2.0, y: 2.0, projection: .noSRID))

        #expect(polygon.covers(boundaryPoint))
        #expect(!polygon.contains(boundaryPoint))
        #expect(polygon.covers(interiorPoint))
        #expect(polygon.contains(interiorPoint))
    }

}

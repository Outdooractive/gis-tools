@testable import GISTools
import Testing

struct PolygonTangentsTests {

    /// Tests a square polygon with an external point to the right.
    /// Both tangents should touch the right edge (longitude ≈ 5).
    @Test
    func squareRight() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let point = Coordinate3D(latitude: 2.5, longitude: 10.0)
        let tangentPoints = try #require(polygon.tangentPoints(to: point))

        #expect(tangentPoints.coordinates.count == 2)
        for coord in tangentPoints.coordinates {
            #expect(abs(coord.longitude - 5.0) < 0.001)
        }
    }

    /// Tests a square polygon with an external point above.
    /// Both tangents should touch the top edge (latitude ≈ 5).
    @Test
    func squareAbove() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let point = Coordinate3D(latitude: 10.0, longitude: 2.5)
        let tangentPoints = try #require(polygon.tangentPoints(to: point))

        #expect(tangentPoints.coordinates.count == 2)
        for coord in tangentPoints.coordinates {
            #expect(abs(coord.latitude - 5.0) < 0.001)
        }
    }

    /// Returns nil when the point is inside the polygon.
    @Test
    func insideReturnsNil() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let point = Coordinate3D(latitude: 2.5, longitude: 2.5)
        #expect(polygon.tangentPoints(to: point) == nil)
    }

    /// Tests a convex pentagon with an external point to the upper-right.
    @Test
    func pentagon() async throws {
        let pentagon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 4.0, longitude: 2.0),
                Coordinate3D(latitude: 5.0, longitude: 6.0),
                Coordinate3D(latitude: 1.0, longitude: 8.0),
                Coordinate3D(latitude: -3.0, longitude: 4.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let point = Coordinate3D(latitude: -5.0, longitude: 15.0)
        let tangentPoints = try #require(pentagon.tangentPoints(to: point))

        #expect(tangentPoints.coordinates.count == 2)
        // Both tangents should be on the right side
        for coord in tangentPoints.coordinates {
            #expect(coord.longitude > 0.0)
        }
    }

    /// Tests a polygon that crosses the antimeridian (~180° longitude).
    /// The polygon spans from lon=179 to lon=-179 near the equator,
    /// and the external point is at lon=-170.
    @Test
    func antimeridian() async throws {
        let polygon = Polygon(unchecked: [
            [
                Coordinate3D(latitude: 0.0, longitude: 179.0),
                Coordinate3D(latitude: 5.0, longitude: 179.0),
                Coordinate3D(latitude: 5.0, longitude: -179.0),
                Coordinate3D(latitude: 0.0, longitude: -179.0),
                Coordinate3D(latitude: 0.0, longitude: 179.0),
            ],
        ])
        let point = Coordinate3D(latitude: 2.5, longitude: -170.0)
        let tangentPoints = try #require(polygon.tangentPoints(to: point))

        #expect(tangentPoints.coordinates.count == 2)
        for coord in tangentPoints.coordinates {
            #expect(abs(coord.longitude - -179.0) < 1.0)
        }
    }

    /// Tests a polygon crossing the date line (South Pacific) with the external
    /// point on the opposite side (east of the date line).
    /// The polygon spans lon=175 to -175 across the date line near Fiji,
    /// and the point is at lon=-140 (east of the date line).
    @Test
    func antimeridianPointOnOtherSide() async throws {
        let polygon = Polygon(unchecked: [
            [
                Coordinate3D(latitude: -15.0, longitude: 175.0),
                Coordinate3D(latitude: -15.0, longitude: -175.0),
                Coordinate3D(latitude: -20.0, longitude: -175.0),
                Coordinate3D(latitude: -20.0, longitude: 175.0),
                Coordinate3D(latitude: -15.0, longitude: 175.0),
            ],
        ])
        let point = Coordinate3D(latitude: -17.5, longitude: -140.0)
        let tangentPoints = try #require(polygon.tangentPoints(to: point))

        #expect(tangentPoints.coordinates.count == 2)
        for coord in tangentPoints.coordinates {
            #expect(abs(coord.longitude - -175.0) < 1.0)
        }
    }

    // MARK: - EPSG:3857

    @Test
    func polygonTangents3857() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(x: 0.0, y: 0.0),
                Coordinate3D(x: 50_000.0, y: 0.0),
                Coordinate3D(x: 50_000.0, y: 50_000.0),
                Coordinate3D(x: 0.0, y: 50_000.0),
                Coordinate3D(x: 0.0, y: 0.0),
            ],
        ]))
        let point = Coordinate3D(x: 100_000.0, y: 25_000.0)
        let tangentPoints = try #require(polygon.tangentPoints(to: point))
        #expect(tangentPoints.coordinates.count == 2)
    }

    /// Tests a polygon entirely east of the date line (near Guam) with the
    /// external point west of the date line. The shortest tangents cross the
    /// date line; the algorithm must shift the point's longitude so the
    /// Cartesian cross product reflects the short route.
    @Test
    func polygonEastPointWest() async throws {
        // Small square near Guam: ~144°E–145°E, ~13°N–14°N
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 13.0, longitude: 144.0),
                Coordinate3D(latitude: 14.0, longitude: 144.0),
                Coordinate3D(latitude: 14.0, longitude: 145.0),
                Coordinate3D(latitude: 13.0, longitude: 145.0),
                Coordinate3D(latitude: 13.0, longitude: 144.0),
            ],
        ]))
        // Point west of the date line, in the central Pacific
        let point = Coordinate3D(latitude: 13.5, longitude: -170.0)
        let tangentPoints = try #require(polygon.tangentPoints(to: point))

        #expect(tangentPoints.coordinates.count == 2)
        // Both tangents should be on the side facing the shifted point (lon ≈ 145)
        for coord in tangentPoints.coordinates {
            #expect(abs(coord.longitude - 145.0) < 1.0)
        }
    }

}

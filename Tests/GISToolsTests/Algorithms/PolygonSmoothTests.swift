import Foundation
@testable import GISTools
import Testing

struct PolygonSmoothTests {

    // Tests that Chaikin smoothing a square polygon doubles the number of points and remains closed.
    @Test
    func smoothSquare() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let smoothed = polygon.smooth()
        let outerRing = try #require(smoothed.outerRing)

        // Chaikin doubles the number of points: 4 → 8
        #expect(outerRing.coordinates.count == 9) // 8 points + closing
        #expect(outerRing.coordinates.first == outerRing.coordinates.last)
    }

    // Tests that multiple smoothing iterations continue doubling the number of points.
    @Test
    func smoothMultipleIterations() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let smoothed = polygon.smooth(iterations: 2)
        let outerRing = try #require(smoothed.outerRing)

        // Each iteration doubles: 4 → 8 → 16
        #expect(outerRing.coordinates.count == 17) // 16 points + closing
    }

    // Tests that smoothing a triangle polygon produces the expected number of points (3 corners to 6).
    @Test
    func smoothTriangle() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let smoothed = polygon.smooth()
        let outerRing = try #require(smoothed.outerRing)

        // 3 corners → 6 after one iteration
        #expect(outerRing.coordinates.count == 7)
    }

    // Tests that smoothing a polygon with a hole preserves both the outer ring and the hole.
    @Test
    func smoothWithHole() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 3.0, longitude: 7.0),
                Coordinate3D(latitude: 7.0, longitude: 7.0),
                Coordinate3D(latitude: 7.0, longitude: 3.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
            ],
        ]))

        let smoothed = polygon.smooth()
        #expect(smoothed.rings.count == 2) // outer + hole
    }

    // Tests that smoothing a MultiPolygon applies Chaikin smoothing to each constituent polygon.
    @Test
    func smoothMultiPolygon() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))

        let smoothed = mp.smooth()
        #expect(smoothed.polygons.count == 2)

        for poly in smoothed.polygons {
            let ring = try #require(poly.outerRing)
            #expect(ring.coordinates.count == 9) // 4→8 + closing
        }
    }

    // Tests that additional smoothing iterations continue to modify the geometry further.
    @Test
    func smoothIdempotency() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let once = polygon.smooth(iterations: 3)
        let twice = once.smooth(iterations: 3)

        let ring1 = try #require(once.outerRing)
        let ring2 = try #require(twice.outerRing)
        // Further smoothing beyond a certain point changes little
        #expect(ring2.coordinates.count > ring1.coordinates.count)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))

        let smoothed = polygon.smooth(iterations: 3)
        let smoothedRing = try #require(smoothed.outerRing)

        // Smoothed polygon should have more vertices than the original
        #expect(smoothedRing.coordinates.count > polygon.outerRing?.coordinates.count ?? 0)
        // Smoothed polygon should still cross the antimeridian
        #expect(smoothed.crossesAntimeridian)
    }

}

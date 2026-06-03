import Foundation
@testable import GISTools
import Testing

struct BooleanPointInPolygonTests {

    // MARK: - Ring.contains(_ coordinate)

    @Test
    func ringContainsCoordinateInside() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(ring.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
    }

    @Test
    func ringContainsCoordinateOutside() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(ring.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    @Test
    func ringContainsCoordinateOnBoundary() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        // Default: on boundary → true
        #expect(ring.contains(Coordinate3D(latitude: 0.0, longitude: 5.0)))
        // ignoringBoundary: on boundary → false
        #expect(ring.contains(Coordinate3D(latitude: 0.0, longitude: 5.0), ignoringBoundary: true) == false)
    }

    @Test
    func ringContainsPoint() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let pointOutside = Point(Coordinate3D(latitude: 20.0, longitude: 5.0))
        #expect(ring.contains(pointInside))
        #expect(ring.contains(pointOutside) == false)
    }

    // MARK: - Ring (convex)

    @Test
    func ringContainsConvexShape() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        // Center
        #expect(ring.contains(Coordinate3D(latitude: 2.0, longitude: 2.0)))
        // Near corner but inside
        #expect(ring.contains(Coordinate3D(latitude: 0.5, longitude: 0.5)))
        // Just outside
        #expect(ring.contains(Coordinate3D(latitude: -1.0, longitude: 2.0)) == false)
    }

    // MARK: - Ring (concave / L-shaped)

    @Test
    func ringContainsConcaveShape() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 6.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        // Inside the L-shaped area
        #expect(ring.contains(Coordinate3D(latitude: 1.0, longitude: 1.0)))
        #expect(ring.contains(Coordinate3D(latitude: 4.0, longitude: 1.0)))
        // Inside the "cutout" — not inside the ring
        #expect(ring.contains(Coordinate3D(latitude: 4.0, longitude: 3.0)) == false)
    }

    // MARK: - Polygon (with hole)

    @Test
    func polygonContainsWithHole() async throws {
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
        // Inside outer ring, outside hole
        #expect(polygon.contains(Coordinate3D(latitude: 1.0, longitude: 5.0)))
        // Inside the hole → not contained
        #expect(polygon.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
        // Outside outer ring
        #expect(polygon.contains(Coordinate3D(latitude: 15.0, longitude: 5.0)) == false)
    }

    @Test
    func polygonContainsPoint() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(polygon.contains(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))
        #expect(polygon.contains(Point(Coordinate3D(latitude: 20.0, longitude: 5.0))) == false)
    }

    // MARK: - MultiPolygon

    @Test
    func multiPolygonContains() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))

        #expect(mp.contains(Coordinate3D(latitude: 2.0, longitude: 2.0)))
        #expect(mp.contains(Coordinate3D(latitude: 12.0, longitude: 2.0)))
        #expect(mp.contains(Coordinate3D(latitude: 7.0, longitude: 2.0)) == false)
    }

    // MARK: - Feature

    @Test
    func featureContains() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(polygon)
        #expect(feature.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(feature.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    @Test
    func featureContainsNonPolygon() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let feature = Feature(point)
        // Feature wraps a Point — not a PolygonGeometry, so always false
        #expect(feature.contains(point.coordinate) == false)
    }

    // MARK: - FeatureCollection

    @Test
    func featureCollectionContains() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let fc = FeatureCollection([Feature(polygon)])
        #expect(fc.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(fc.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

}

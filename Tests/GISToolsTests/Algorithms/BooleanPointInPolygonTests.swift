import Foundation
@testable import GISTools
import Testing

struct BooleanPointInPolygonTests {

    // MARK: - Ring.contains(_ coordinate)

    // Validates that `Ring.contains` returns true for a coordinate inside the ring.
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

    // Validates that `Ring.contains` returns false for a coordinate outside the ring.
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

    // Validates that `Ring.contains` returns true for a coordinate on the boundary by default, and false when ignoring the boundary.
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

    // Validates that `Ring.contains` works correctly with `Point` instances.
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

    // Validates that `Ring.contains` correctly determines point inclusion in a convex shape.
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

    // Validates that `Ring.contains` correctly handles point inclusion in a concave (L-shaped) ring.
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

    // Validates that `Polygon.contains` correctly handles polygons with holes (points in the hole are excluded).
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

    // Validates that `Polygon.contains` works correctly with `Point` instances.
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

    // Validates that `MultiPolygon.contains` returns correct results for points inside any constituent polygon and false otherwise.
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

    // Validates that `Feature.contains` delegates correctly to its underlying polygon geometry.
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

    // Validates that `Feature.contains` returns false when the feature wraps a non-polygon geometry.
    @Test
    func featureContainsNonPolygon() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let feature = Feature(point)
        // Feature wraps a Point — not a PolygonGeometry, so always false
        #expect(feature.contains(point.coordinate) == false)
    }

    // MARK: - FeatureCollection

    // Validates that `FeatureCollection.contains` checks containment across all features in the collection.
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

    // MARK: - gridSize

    // Validates that `contains(gridSize:)` on Polygon matches manual pre-snapping.
    @Test
    func polygonContainsWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let coord = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParam = polygon.contains(coord, gridSize: gridSize)
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coord).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedPolygon.contains(snappedCoord)
        #expect(withParam == manual)
    }

    // Validates that `contains(gridSize:)` on Feature matches manual pre-snapping.
    @Test
    func featureContainsWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let feature = Feature(polygon)
        let coord = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParam = feature.contains(coord, gridSize: gridSize)
        let snappedFeature = feature.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coord).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedFeature.contains(snappedCoord)
        #expect(withParam == manual)
    }

    // Validates that `contains(gridSize:)` on FeatureCollection matches manual pre-snapping.
    @Test
    func featureCollectionContainsWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let fc = FeatureCollection([Feature(polygon)])
        let coord = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParam = fc.contains(coord, gridSize: gridSize)
        let snappedFc = fc.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coord).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedFc.contains(snappedCoord)
        #expect(withParam == manual)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        #expect(polygon.contains(Coordinate3D(latitude: 5.0, longitude: 175.0)))
        #expect(polygon.contains(Coordinate3D(latitude: 5.0, longitude: 165.0)) == false)
    }

}

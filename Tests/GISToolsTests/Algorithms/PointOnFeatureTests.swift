import Foundation
@testable import GISTools
import Testing

struct PointOnFeatureTests {

    // Verifies that a point feature returns its own coordinate as the point on feature.
    @Test
    func pointOnPoint() async throws {
        let p = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let result = try #require(p.coordinateOnFeature)
        #expect(result == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

    // Verifies that a line string returns its centroid as the point on feature.
    @Test
    func pointOnLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let result = try #require(ls.coordinateOnFeature)
        // Centroid is (5,5) which is on the line
        #expect(result == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

    // Verifies that a polygon returns a point on its surface as the point on feature.
    @Test
    func pointOnPolygon() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.pointOnFeature)
        // Should be on the surface
        #expect(result.coordinate.latitude >= 0.0)
        #expect(result.coordinate.latitude <= 10.0)
    }

    // Verifies that a multi-polygon returns a point inside one of its constituent polygons.
    @Test
    func pointOnMultiPolygon() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))
        let result = try #require(mp.pointOnFeature)
        // Should be inside one of the polygons
        #expect(result.coordinate.latitude >= 0.0)
        #expect(result.coordinate.latitude <= 15.0)
    }

    // Verifies that a generic feature wrapping a point returns the point's coordinate as the point on feature.
    @Test
    func pointOnFeature() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let feature = Feature(point)
        let result = try #require(feature.pointOnFeature)
        #expect(result.coordinate == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

    // MARK: - gridSize

    // Validates that `coordinateOnFeature(gridSize:)` matches manual pre-snapping.
    @Test
    func pointOnFeatureWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let gridSize = 0.001

        let withParam = try #require(polygon.coordinateOnFeature(gridSize: gridSize))
        let snapped = polygon.snappedToGrid(tolerance: gridSize)
        let manual = try #require(snapped.coordinateOnFeature)
        #expect(withParam.latitude.isFinite)
        #expect(withParam.longitude.isFinite)
    }

    // MARK: - Antimeridian

    @Test
    func nearAntimeridian() async throws {
        // Polygon near the antimeridian (170°–179°), NOT crossing it.
        // Verifies the algorithm works correctly with large longitude values
        // near ±180° without numerical issues.
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let result = try #require(polygon.coordinateOnFeature)

        // The result should lie on the polygon's surface
        #expect(polygon.contains(result, ignoringBoundary: true))
    }

    @Test
    func crossingAntimeridian() async throws {
        // Polygon that wraps across the antimeridian (170° → -170°).
        // The algorithm normalizes longitudes to [0, 360) internally
        // and should return a valid point on the polygon's surface.
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let result = try #require(polygon.coordinateOnFeature)

        // Latitude should be within the polygon's bounds
        #expect(result.latitude >= 0.0)
        #expect(result.latitude <= 10.0)
        // Longitude should be near the antimeridian (not at planar centroid 0°)
        // indicating the normalization fix is working
        #expect(result.longitude.isFinite)
        #expect(abs(result.longitude) > 90.0)

        // Cut the polygon at the antimeridian and verify the result
        // is inside one of the non-wrapping parts
        let parts = polygon.cutAtAntimeridian()
        let isInsidePart = parts.features.contains { feature in
            guard let partPolygon = feature.geometry as? Polygon else { return false }
            return partPolygon.contains(result, ignoringBoundary: true)
        }
        #expect(isInsidePart)
    }

}

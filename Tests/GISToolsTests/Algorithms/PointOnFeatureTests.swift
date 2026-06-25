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

    // MARK: - Grid size

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
        #expect(withParam == manual)
    }

    // MARK: - Projections

    @Test
    func pointOnFeature3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let point = try #require(polygon.pointOnFeature)
        #expect(point.coordinate.projection == .epsg3857)
    }

    // Verifies point on feature in EPSG:4978.
    @Test
    func pointOnFeature4978() async throws {
        let c00 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let c10 = Coordinate3D(latitude: 0.0, longitude: 0.00009).projected(to: .epsg4978)
        let c11 = Coordinate3D(latitude: 0.00009, longitude: 0.00009).projected(to: .epsg4978)
        let c01 = Coordinate3D(latitude: 0.00009, longitude: 0.0).projected(to: .epsg4978)
        let polygon = try #require(Polygon([[
            c00, c10, c11, c01, c00,
        ]]))
        let point = try #require(polygon.pointOnFeature)
        #expect(point.coordinate.projection == .epsg4978)
    }

    // Verifies point on feature in noSRID.
    @Test
    func pointOnFeatureNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let point = try #require(polygon.pointOnFeature)
        #expect(point.coordinate.projection == .noSRID)
    }

    // MARK: - Antimeridian

    @Test
    func nearAntimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let result = try #require(polygon.coordinateOnFeature)
        #expect(polygon.contains(result, ignoringBoundary: true))
    }

    // Tests point on feature for a polygon crossing the antimeridian.
    @Test
    func crossingAntimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -165.0),
            Coordinate3D(latitude: 0.0, longitude: 160.0),
        ]]))
        let result = try #require(polygon.coordinateOnFeature)

        #expect(result.latitude >= 0.0)
        #expect(result.latitude <= 10.0)
        #expect(result.longitude.isFinite)
        #expect(abs(result.longitude) > 90.0)

        let parts = polygon.cutAtAntimeridian()
        let isInsidePart = parts.features.contains { feature in
            guard let partPolygon = feature.geometry as? Polygon else { return false }
            return partPolygon.contains(result, ignoringBoundary: true)
        }
        #expect(isInsidePart)
    }

}

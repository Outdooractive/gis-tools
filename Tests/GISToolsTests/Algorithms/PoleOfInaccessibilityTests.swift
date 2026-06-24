import Foundation
@testable import GISTools
import Testing

struct PoleOfInaccessibilityTests {

    // Tests the pole of inaccessibility for a square polygon is near the center.
    @Test
    func squarePole() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole = try #require(polygon.poleOfInaccessibility())
        // Should be near the center
        #expect(abs(pole.coordinate.latitude - 5.0) < 1.0)
        #expect(abs(pole.coordinate.longitude - 5.0) < 1.0)
        #expect(polygon.contains(pole.coordinate))
    }

    // Tests the pole of inaccessibility for a triangle polygon lies within the triangle.
    @Test
    func trianglePole() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole = try #require(polygon.poleOfInaccessibility())
        #expect(polygon.contains(pole.coordinate))
    }

    // Tests the pole of inaccessibility is computed correctly at different precision levels.
    @Test
    func poleWithPrecision() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole1 = try #require(polygon.poleOfInaccessibility(precision: 1.0))
        let pole2 = try #require(polygon.poleOfInaccessibility(precision: 0.1))
        #expect(polygon.contains(pole1.coordinate))
        #expect(polygon.contains(pole2.coordinate))
    }

    // Tests the pole of inaccessibility for an L-shaped polygon lies within the polygon.
    @Test
    func poleLShaped() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole = try #require(polygon.poleOfInaccessibility())
        #expect(polygon.contains(pole.coordinate))
    }

    // Tests that an empty polygon returns nil for the pole of inaccessibility.
    @Test
    func poleNoOuterRing() async throws {
        let polygon = Polygon()
        #expect(polygon.poleOfInaccessibility() == nil)
    }

    // MARK: - gridSize

    // Validates that `poleOfInaccessibility(gridSize:)` matches manual pre-snapping.
    @Test
    func poleWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let gridSize = 0.001

        let withParam = try #require(polygon.poleOfInaccessibility(gridSize: gridSize))
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let manual = try #require(snappedPolygon.poleOfInaccessibility())
        #expect(abs(withParam.coordinate.latitude - manual.coordinate.latitude) < 0.0000000001)
        #expect(abs(withParam.coordinate.longitude - manual.coordinate.longitude) < 0.0000000001)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        // Asymmetric polygon crossing the antimeridian (partial wrap: 170° → -175°)
        // so the pole clearly falls on one side of the cut boundary.
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -175.0),
            Coordinate3D(latitude: 0.0, longitude: -175.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let pole = try #require(polygon.poleOfInaccessibility())

        // Latitude should be within the polygon's bounds
        #expect(pole.coordinate.latitude >= 0.0)
        #expect(pole.coordinate.latitude <= 10.0)
        // Longitude should be near the antimeridian (not at planar centroid -2.5°)
        #expect(pole.coordinate.longitude.isFinite)
        #expect(abs(pole.coordinate.longitude) > 90.0)

        // Cut the polygon at the antimeridian and verify the pole
        // is inside one of the non-wrapping parts
        let parts = polygon.cutAtAntimeridian()
        let isInsidePart = parts.features.contains { feature in
            guard let partPolygon = feature.geometry as? Polygon else { return false }
            return partPolygon.contains(pole.coordinate, ignoringBoundary: true)
        }
        #expect(isInsidePart)
    }

    // MARK: - Projection tests

    @Test
    func poleOfInaccessibility4978() async throws {
        // Pole of inaccessibility is computation-heavy; using a ~0.1° polygon
        // in projected EPSG:4978 to keep test runtime reasonable.
        let c00 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let c10 = Coordinate3D(latitude: 0.1, longitude: 0.0).projected(to: .epsg4978)
        let c11 = Coordinate3D(latitude: 0.1, longitude: 0.1).projected(to: .epsg4978)
        let c01 = Coordinate3D(latitude: 0.0, longitude: 0.1).projected(to: .epsg4978)
        let polygon = try #require(Polygon([
            [c00, c10, c11, c01, c00],
        ]))
        let pole = try #require(polygon.poleOfInaccessibility())
        #expect(pole.coordinate.longitude.isFinite)
        #expect(pole.coordinate.latitude.isFinite)
        #expect(pole.coordinate.projection == .epsg4978)
    }

    @Test
    func poleOfInaccessibility3857() async throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let pole = try #require(polygon.poleOfInaccessibility(precision: 1_000.0))
        #expect(pole.coordinate.longitude.isFinite)
        #expect(pole.coordinate.latitude.isFinite)
        #expect(pole.coordinate.projection == .epsg3857)
    }

    @Test
    func poleOfInaccessibilityNoSRID() async throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])
        let pole = try #require(polygon.poleOfInaccessibility(precision: 10.0))
        #expect(pole.coordinate.longitude.isFinite)
        #expect(pole.coordinate.latitude.isFinite)
        #expect(pole.coordinate.projection == .noSRID)
    }

}

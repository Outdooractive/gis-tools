import Foundation
@testable import GISTools
import Testing

struct TriangleGridTests {

    @Test
    func basicTriangleGrid() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.triangleGrid(cellSide: GISTool.convertToMeters(4.8, .degrees))
        // 10°×10° bbox ≈ 4.8° cells → 2 columns × 2 rows = 4 cells × 2 triangles each = 8
        #expect(grid.features.count == 8)

        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
            // Triangles have 3 unique vertices + closing vertex = 4 coordinates
            #expect(polygon.outerRing?.coordinates.count == 4)
        }
    }

    @Test
    func triangleGridSmallCells() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 1.0))

        let grid = bbox.triangleGrid(cellSide: GISTool.convertToMeters(100, .kilometers))
        #expect(grid.features.count > 0)
    }

    @Test
    func triangleGridWithMask() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let mask = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))

        let grid = bbox.triangleGrid(cellSide: GISTool.convertToMeters(4.8, .degrees), mask: mask)
        #expect(grid.features.count > 0)
        #expect(grid.features.count <= 8)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 179.0))

        let grid = bbox.triangleGrid(cellSide: GISTool.convertToMeters(3, .degrees))

        #expect(grid.features.count > 0)
        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            for coord in polygon.allCoordinates {
                #expect(coord.longitude >= 169.0)
                #expect(coord.longitude <= 180.0)
            }
        }
    }

}

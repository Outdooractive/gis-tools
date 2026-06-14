import Foundation
@testable import GISTools
import Testing

struct RectangleGridTests {

    @Test
    func basicRectangleGrid() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.rectangleGrid(
            cellWidth: GISTool.convertToMeters(5, .degrees),
            cellHeight: GISTool.convertToMeters(5, .degrees))
        // 10°×10° bbox with 5°×5° cells → 2 columns × 2 rows = 4 cells
        #expect(grid.features.count == 4)

        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
        }
    }

    @Test
    func rectangleGridCellSize() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.rectangleGrid(
            cellWidth: GISTool.convertToMeters(5, .degrees),
            cellHeight: GISTool.convertToMeters(5, .degrees))
        // 20°×20° bbox with 5°×5° cells → 4 columns × 4 rows = 16 cells
        #expect(grid.features.count == 16)
    }

    @Test
    func rectangleGridWithMask() async throws {
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

        let grid = bbox.rectangleGrid(
            cellWidth: GISTool.convertToMeters(5, .degrees),
            cellHeight: GISTool.convertToMeters(5, .degrees),
            mask: mask)
        #expect(grid.features.count > 0)
        #expect(grid.features.count <= 4)
    }

    @Test
    func rectangleGridEmpty() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 0.5, longitude: 0.5))

        let grid = bbox.rectangleGrid(
            cellWidth: GISTool.convertToMeters(100, .kilometers),
            cellHeight: GISTool.convertToMeters(100, .kilometers))
        #expect(grid.features.isEmpty)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 179.0))

        let grid = bbox.rectangleGrid(
            cellWidth: GISTool.convertToMeters(3, .degrees),
            cellHeight: GISTool.convertToMeters(3, .degrees))

        #expect(grid.features.count > 0)
        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
            for coord in polygon.allCoordinates {
                #expect(coord.longitude >= 169.0)
                #expect(coord.longitude <= 180.0)
                #expect(coord.latitude >= 0.0)
                #expect(coord.latitude <= 10.0)
            }
        }
    }

}

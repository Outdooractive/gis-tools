import Foundation
@testable import GISTools
import Testing

struct SquareGridTests {

    @Test
    func basicSquareGrid() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.squareGrid(cellSide: GISTool.convertToMeters(5, .degrees))
        #expect(grid.features.count == 4)

        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
        }
    }

    @Test
    func squareGridNonSquareBbox() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 15.0, longitude: 10.0))

        let grid = bbox.squareGrid(cellSide: GISTool.convertToMeters(5, .degrees))
        // 10°×15° bbox with 5° cells → 2 rows × 3 columns = 6 cells
        #expect(grid.features.count == 6)
    }

    @Test
    func squareGridWithMask() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let mask = try #require(Polygon([[
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 9.0, longitude: 1.0),
            Coordinate3D(latitude: 9.0, longitude: 9.0),
            Coordinate3D(latitude: 1.0, longitude: 9.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]]))

        let grid = bbox.squareGrid(cellSide: GISTool.convertToMeters(5, .degrees), mask: mask)
        #expect(grid.features.count > 0)
        #expect(grid.features.count <= 4)
    }

    // MARK: - EPSG:3857

    @Test
    func squareGrid3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0))
        let grid = bbox.squareGrid(cellSide: 500_000.0)
        #expect(grid.features.count > 0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 179.0))

        let grid = bbox.squareGrid(cellSide: GISTool.convertToMeters(3, .degrees))

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

import Foundation
@testable import GISTools
import Testing

struct HexGridTests {

    @Test
    func basicHexGrid() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.hexGrid(cellSide: GISTool.convertToMeters(4.8, .degrees))
        #expect(grid.features.count > 0)

        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
            // Hexagons have 6 unique vertices + closing vertex = 7 coordinates
            #expect(polygon.outerRing?.coordinates.count == 7)
        }
    }

    @Test
    func hexGridTriangles() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.hexGrid(cellSide: GISTool.convertToMeters(4.8, .degrees), triangles: true)
        #expect(grid.features.count > 0)

        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
            // Triangles have 3 unique vertices + closing vertex = 4 coordinates
            #expect(polygon.outerRing?.coordinates.count == 4)
        }
    }

    @Test
    func hexGridWithMask() async throws {
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

        let allGrid = bbox.hexGrid(cellSide: GISTool.convertToMeters(1, .degrees))
        let maskedGrid = bbox.hexGrid(cellSide: GISTool.convertToMeters(1, .degrees), mask: mask)

        #expect(maskedGrid.features.count < allGrid.features.count)
        #expect(maskedGrid.features.count > 0)
    }

    @Test
    func hexGridLargeCell() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 1.0))

        // Large cell relative to bbox — no hexagon fully fits
        let grid = bbox.hexGrid(cellSide: GISTool.convertToMeters(100, .kilometers))
        #expect(grid.features.isEmpty)
    }

    @Test
    func hexGridCustomUnits() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let gridKm = bbox.hexGrid(cellSide: GISTool.convertToMeters(100, .kilometers))
        let gridMiles = bbox.hexGrid(cellSide: GISTool.convertToMeters(100, .miles))

        // A mile is longer than a km, so fewer mile-based cells should fit
        #expect(gridMiles.features.count < gridKm.features.count)
        #expect(gridKm.features.count > 0)
    }
    // MARK: - EPSG:3857

    @Test
    func hexGrid3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0))
        let grid = bbox.hexGrid(cellSide: 500_000.0)
        #expect(grid.features.count > 0)
    }

    @Test
    func hexGrid3857CrossOrigin() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: -10_000.0, y: -10_000.0),
            northEast: Coordinate3D(x: 10_000.0, y: 10_000.0))
        let grid = bbox.hexGrid(cellSide: 1_000.0)
        #expect(grid.features.count > 0)
    }

    @Test
    func hexGrid4978() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 10_000.0, y: 10_000.0, z: 0.0, projection: .epsg4978))
        let grid = bbox.hexGrid(cellSide: 1_000.0)
        #expect(grid.features.count > 0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 179.0))

        let grid = bbox.hexGrid(cellSide: GISTool.convertToMeters(2, .degrees))

        #expect(grid.features.count > 0)
        for feature in grid.features {
            let polygon = try #require(feature.geometry as? Polygon)
            for coord in polygon.allCoordinates {
                #expect(coord.longitude >= 168.0)
                #expect(coord.longitude <= 181.0)
            }
        }
    }

}

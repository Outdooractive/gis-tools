import Foundation
@testable import GISTools
import Testing

struct PointGridTests {

    @Test
    func basicPointGrid() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let grid = bbox.pointGrid(cellSide: GISTool.convertToMeters(4.8, .degrees))
        // 10°×10° bbox ≈ 4.8° spacing → 2 columns × 2 rows = 4 points
        #expect(grid.features.count == 4)

        for feature in grid.features {
            let point = try #require(feature.geometry as? Point)
            #expect(point.isValid)
            let coord = point.coordinate
            #expect(coord.latitude >= 0.0)
            #expect(coord.latitude <= 10.0)
            #expect(coord.longitude >= 0.0)
            #expect(coord.longitude <= 10.0)
        }
    }

    @Test
    func pointGridSpacing() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        // Small spacing → many points
        let grid = bbox.pointGrid(cellSide: GISTool.convertToMeters(1, .degrees))
        #expect(grid.features.count > 10)
    }

    @Test
    func pointGridWithMask() async throws {
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

        let allGrid = bbox.pointGrid(cellSide: GISTool.convertToMeters(1, .degrees))
        let maskedGrid = bbox.pointGrid(cellSide: GISTool.convertToMeters(1, .degrees), mask: mask)

        // Masked grid should have fewer points than the full grid
        #expect(maskedGrid.features.count < allGrid.features.count)
        #expect(maskedGrid.features.count > 0)
    }

    // MARK: - Projections

    @Test
    func pointGrid3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0))
        let grid = bbox.pointGrid(cellSide: 500_000.0)
        #expect(grid.features.count > 0)
    }

    @Test
    func pointGrid3857CrossOrigin() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: -10_000.0, y: -10_000.0),
            northEast: Coordinate3D(x: 10_000.0, y: 10_000.0))
        let grid = bbox.pointGrid(cellSide: 1_000.0)
        #expect(grid.features.count > 0)
    }


    @Test
    func pointGrid4978() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 6_373_000.0, y: 0.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 6_383_000.0, y: 10_000.0, projection: .epsg4978))
        let grid = bbox.pointGrid(cellSide: 5_000.0)
        #expect(grid.features.count > 0)
    }


    @Test
    func pointGridNoSRID() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID))
        let grid = bbox.pointGrid(cellSide: 50.0)
        #expect(grid.features.count > 0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 179.0))

        let grid = bbox.pointGrid(cellSide: GISTool.convertToMeters(3, .degrees))

        #expect(grid.features.count > 0)
        for feature in grid.features {
            let point = try #require(feature.geometry as? Point)
            #expect(point.coordinate.longitude >= 170.0)
            #expect(point.coordinate.longitude <= 179.0)
        }
    }

}

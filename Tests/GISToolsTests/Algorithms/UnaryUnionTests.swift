@testable import GISTools
import Testing

struct UnaryUnionTests {

    // MARK: - unaryUnion

    // Validates unaryUnion merges overlapping rectangles.
    @Test
    func overlappingRectanglesUnaryUnion() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count >= 1)
        // Area should be less than sum (overlap subtracted once)
        let unionArea = result.polygons.reduce(0) { $0 + $1.area }
        let sumArea = p1.area + p2.area
        #expect(unionArea < sumArea)
    }

    // Validates unaryUnion keeps disjoint polygons separate.
    @Test
    func noOverlapUnaryUnion() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 30.0),
            Coordinate3D(latitude: 30.0, longitude: 30.0),
            Coordinate3D(latitude: 30.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count == 2)
    }

    // Validates unaryUnion returns nil for empty input.
    @Test
    func emptyMultiPolygonUnaryUnion() {
        let mp = MultiPolygon()
        #expect(mp.unaryUnion() == nil)
    }

    // MARK: - Projections

    // Validates unaryUnion in EPSG:3857.
    @Test
    func unaryUnion3857() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 500.0, y: 1_500.0),
            Coordinate3D(x: 1_500.0, y: 1_500.0),
            Coordinate3D(x: 1_500.0, y: 500.0),
            Coordinate3D(x: 500.0, y: 500.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count >= 1)
        #expect(result.projection == .epsg3857)
    }


    // Validates unaryUnion in EPSG:4978.
    @Test
    func unaryUnion4978() throws {
        let coords4326a: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let coords4326b: [Coordinate3D] = [
            Coordinate3D(latitude: 0.5, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 1.5),
            Coordinate3D(latitude: 1.5, longitude: 1.5),
            Coordinate3D(latitude: 1.5, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.0),
        ]
        let p1 = try #require(Polygon([coords4326a.map { $0.projected(to: .epsg4978) }]))
        let p2 = try #require(Polygon([coords4326b.map { $0.projected(to: .epsg4978) }]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count >= 1)
        #expect(result.projection == .epsg4978)
    }


    // Validates unaryUnion with noSRID.
    @Test
    func unaryUnionNoSRID() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 50.0, y: 50.0, projection: .noSRID),
            Coordinate3D(x: 50.0, y: 150.0, projection: .noSRID),
            Coordinate3D(x: 150.0, y: 150.0, projection: .noSRID),
            Coordinate3D(x: 150.0, y: 50.0, projection: .noSRID),
            Coordinate3D(x: 50.0, y: 50.0, projection: .noSRID),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count >= 1)
        #expect(result.projection == .noSRID)
    }

    // MARK: - coverageUnion

    // Validates coverageUnion of adjacent non-overlapping tiles.
    @Test
    func adjacentTilesCoverageUnion() throws {
        // Two tiles sharing an edge (non-overlapping)
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.coverageUnion())
        #expect(result.polygons.count == 1)
        // Area should match a 10×20 rectangle
        #expect(result.polygons[0].area > p1.area)
        #expect(abs(result.polygons[0].area - (p1.area + p2.area)) < 1.0)
    }

    // Validates coverageUnion in EPSG:3857.
    @Test
    func coverageUnion3857() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 2_000.0, y: 0.0),
            Coordinate3D(x: 2_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.coverageUnion())
        #expect(result.polygons.count == 1)
        #expect(result.projection == .epsg3857)
    }

    // Validates coverageUnion with a custom grid size.
    @Test
    func coverageUnionWithGridSize() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 20.0001),
            Coordinate3D(latitude: 10.0001, longitude: 20.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.coverageUnion(gridSize: 0.001))
        #expect(result.polygons.count == 1)
    }

    // MARK: - Grid size

    // MARK: - coverageIsValid

    // Validates adjacent tiles pass coverageIsValid.
    @Test
    func validCoverageAdjacentTiles() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        #expect(mp.coverageIsValid())
    }

    // Validates overlapping tiles fail coverageIsValid.
    @Test
    func invalidCoverageOverlapping() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        #expect(mp.coverageIsValid() == false)
    }

    // Validates tiles with a gap fail coverageIsValid.
    @Test
    func invalidCoverageGap() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 30.0),
            Coordinate3D(latitude: 10.0, longitude: 30.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        #expect(mp.coverageIsValid() == false)
    }

    // Validates a single polygon passes coverageIsValid.
    @Test
    func singlePolygonCoverageIsValid() throws {
        let p = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([p]))
        #expect(mp.coverageIsValid())
    }

    // MARK: - MapTile-based tests

    // Validates coverageUnion of two adjacent map tiles.
    @Test
    func adjacentMapTilesCoverageUnion() throws {
        // Two adjacent tiles at zoom 1: (0,0) and (1,0)
        let tile1 = MapTile(x: 0, y: 0, z: 1)
        let tile2 = MapTile(x: 1, y: 0, z: 1)

        let bbox1 = tile1.boundingBox()
        let bbox2 = tile2.boundingBox()
        let p1 = try #require(Polygon([[
            bbox1.southWest,
            Coordinate3D(latitude: bbox1.southWest.latitude, longitude: bbox1.northEast.longitude),
            bbox1.northEast,
            Coordinate3D(latitude: bbox1.northEast.latitude, longitude: bbox1.southWest.longitude),
            bbox1.southWest,
        ]]))
        let p2 = try #require(Polygon([[
            bbox2.southWest,
            Coordinate3D(latitude: bbox2.southWest.latitude, longitude: bbox2.northEast.longitude),
            bbox2.northEast,
            Coordinate3D(latitude: bbox2.northEast.latitude, longitude: bbox2.southWest.longitude),
            bbox2.southWest,
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let union = try #require(mp.coverageUnion())
        #expect(union.polygons.count == 1)
        #expect(union.polygons[0].isValid)
        #expect(mp.coverageIsValid())
    }

    // Validates coverageUnion of four map tiles in a 2x2 grid.
    @Test
    func fourMapTilesCoverageUnion() throws {
        // 2x2 grid at zoom 1
        let tiles: [MapTile] = [
            MapTile(x: 0, y: 0, z: 1),
            MapTile(x: 1, y: 0, z: 1),
            MapTile(x: 0, y: 1, z: 1),
            MapTile(x: 1, y: 1, z: 1),
        ]
        let polys: [Polygon] = try tiles.map { tile in
            let bbox = tile.boundingBox()
            return try #require(Polygon([[
                bbox.southWest,
                Coordinate3D(latitude: bbox.southWest.latitude, longitude: bbox.northEast.longitude),
                bbox.northEast,
                Coordinate3D(latitude: bbox.northEast.latitude, longitude: bbox.southWest.longitude),
                bbox.southWest,
            ]]))
        }
        let mp = try #require(MultiPolygon(polys))
        let union = try #require(mp.coverageUnion())
        #expect(union.polygons.count == 1)
        #expect(union.polygons[0].isValid)
        #expect(mp.coverageIsValid())
    }

    // Validates coverageIsValid fails for map tiles with a gap.
    @Test
    func mapTilesWithGap() throws {
        // Two tiles with a tile-sized gap between them
        let tile1 = MapTile(x: 0, y: 0, z: 1)
        let tile2 = MapTile(x: 3, y: 0, z: 1) // gap: tiles 1,2 are skipped

        for tile in [tile1, tile2] {
            let bbox = tile.boundingBox()
            _ = bbox
        }

        let bbox1 = tile1.boundingBox()
        let bbox2 = tile2.boundingBox()
        let p1 = try #require(Polygon([[
            bbox1.southWest,
            Coordinate3D(latitude: bbox1.southWest.latitude, longitude: bbox1.northEast.longitude),
            bbox1.northEast,
            Coordinate3D(latitude: bbox1.northEast.latitude, longitude: bbox1.southWest.longitude),
            bbox1.southWest,
        ]]))
        let p2 = try #require(Polygon([[
            bbox2.southWest,
            Coordinate3D(latitude: bbox2.southWest.latitude, longitude: bbox2.northEast.longitude),
            bbox2.northEast,
            Coordinate3D(latitude: bbox2.northEast.latitude, longitude: bbox2.southWest.longitude),
            bbox2.southWest,
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        #expect(mp.coverageIsValid() == false)
    }

    // MARK: - Antimeridian

    // Validates coverageUnion across the antimeridian.
    @Test
    func coverageUnionAntimeridian() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
            Coordinate3D(latitude: 10.0, longitude: 180.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: -180.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -180.0),
            Coordinate3D(latitude: 0.0, longitude: -180.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.coverageUnion())
        #expect(result.polygons.count >= 1)
        #expect(result.polygons[0].isValid)
    }

    // Validates coverageIsValid across the antimeridian.
    @Test
    func coverageIsValidAntimeridian() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]]))
        // Single polygon crossing the antimeridian — trivially valid coverage
        let mp = try #require(MultiPolygon([p1]))
        #expect(mp.coverageIsValid())
    }

    // Validates coverageUnion across antimeridian in EPSG:3857.
    @Test
    func coverageUnionAntimeridian3857() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
            Coordinate3D(latitude: 10.0, longitude: 180.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]
        let p1 = try #require(Polygon([coords4326.map { $0.projected(to: .epsg3857) }]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.coverageUnion())
        #expect(result.polygons.count >= 1)
    }

    // Validates coverageIsValid in EPSG:3857.
    @Test
    func coverageIsValid3857() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 2_000.0, y: 0.0),
            Coordinate3D(x: 2_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        #expect(mp.coverageIsValid())
    }

    // Validates unaryUnion with a custom grid size.
    @Test
    func unaryUnionWithGridSize() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 5.0001, longitude: 5.0001),
            Coordinate3D(latitude: 5.0001, longitude: 15.0001),
            Coordinate3D(latitude: 15.0001, longitude: 15.0001),
            Coordinate3D(latitude: 15.0001, longitude: 5.0001),
            Coordinate3D(latitude: 5.0001, longitude: 5.0001),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let withGrid = try #require(mp.unaryUnion(gridSize: 0.001))
        let snapped = mp.snappedToGrid(tolerance: 0.001)
        let manual = try #require(snapped.unaryUnion())
        #expect(withGrid.polygons.count == manual.polygons.count)
        #expect(abs(withGrid.area - manual.area) < 1.0)
    }

}

@testable import GISTools
import Testing

struct UnaryUnionTests {

    // MARK: - unaryUnion

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
        let mp = MultiPolygon([p1, p2])!
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count >= 1)
        // Area should be less than sum (overlap subtracted once)
        let unionArea = result.polygons.reduce(0) { $0 + $1.area }
        let sumArea = p1.area + p2.area
        #expect(unionArea < sumArea)
    }

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
        let mp = MultiPolygon([p1, p2])!
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count == 2)
    }

    @Test
    func emptyMultiPolygonUnaryUnion() {
        let mp = MultiPolygon()
        #expect(mp.unaryUnion() == nil)
    }

    @Test
    func unaryUnion3857() throws {
        let p1 = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let p2 = Polygon(unchecked: [[
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 500.0, y: 1_500.0),
            Coordinate3D(x: 1_500.0, y: 1_500.0),
            Coordinate3D(x: 1_500.0, y: 500.0),
            Coordinate3D(x: 500.0, y: 500.0),
        ]])
        let mp = MultiPolygon(unchecked: [p1, p2])
        let result = try #require(mp.unaryUnion())
        #expect(result.polygons.count >= 1)
    }

    // MARK: - coverageUnion

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
        let mp = MultiPolygon([p1, p2])!
        let result = try #require(mp.coverageUnion())
        #expect(result.polygons.count == 1)
        // Area should match a 10×20 rectangle
        #expect(result.polygons[0].area > p1.area)
        #expect(abs(result.polygons[0].area - (p1.area + p2.area)) < 1.0)
    }

    @Test
    func coverageUnion3857() throws {
        let p1 = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let p2 = Polygon(unchecked: [[
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 2_000.0, y: 0.0),
            Coordinate3D(x: 2_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
        ]])
        let mp = MultiPolygon(unchecked: [p1, p2])
        let result = try #require(mp.coverageUnion())
        #expect(result.polygons.count == 1)
    }

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
        let mp = MultiPolygon([p1, p2])!
        let result = try #require(mp.coverageUnion(gridSize: 0.001))
        #expect(result.polygons.count == 1)
    }

    // MARK: - gridSize

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
        let mp = MultiPolygon([p1, p2])!
        let withGrid = try #require(mp.unaryUnion(gridSize: 0.001))
        let snapped = mp.snappedToGrid(tolerance: 0.001)
        let manual = try #require(snapped.unaryUnion())
        #expect(withGrid.polygons.count == manual.polygons.count)
        #expect(abs(withGrid.area - manual.area) < 1.0)
    }

}

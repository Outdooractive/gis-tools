import Foundation
@testable import GISTools
import Testing

struct SimplifyTests {

    // TODO: More tests
    // https://github.com/Turfjs/turf/tree/master/packages/turf-simplify/test/in
    // https://github.com/Turfjs/turf/tree/master/packages/turf-simplify/test/out

    // Validates that invalid polygons return nil when simplified.
    @Test
    func invalidPolygons() async throws {
        // TODO: Improve the polygon validity check

//        let polygon1 = MultiPolygon([[[Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 2.0, longitude: 0.0), Coordinate3D(latitude: 3.0, longitude: 0.0), Coordinate3D(latitude: 2.5, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 0.0)]]])
//        let polygon2 = MultiPolygon([[[Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 2.0, longitude: 1.0), Coordinate3D(latitude: 1.0, longitude: 0.0)]]])
//
//        XCTAssertNil(polygon1?.simplified())
//        XCTAssertNil(polygon2?.simplified())
    }

    // Validates that simplification with degenerate rings does not enter an endless loop.
    @Test
    func ringValidationBackoff() async throws {
        let polygon = Polygon([[
            Coordinate3D(latitude: 47.602460344511684, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.639486027997926, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.639486027997926, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.602460344511684, longitude: 4.564821280446012),
        ]])

        // Check if we ran into an endless loop
        let startDate = Date()
        _ = polygon?.simplified(tolerance: 5.0, highQuality: false)
        #expect(abs(startDate.timeIntervalSinceNow) < 0.5)
    }

    // MARK: - gridSize

    // Validates that `simplified(tolerance:highQuality:gridSize:)` matches manual pre-snapping.
    @Test
    func simplifyWithGridSize() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 5.0001, longitude: 5.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let gridSize = 0.001

        let withParam = lineString.simplified(tolerance: 1.0, gridSize: gridSize)
        let snapped = lineString.snappedToGrid(tolerance: gridSize)
        let manual = snapped.simplified(tolerance: 1.0)
        #expect(withParam.coordinates == manual.coordinates)
    }

    // Validates simplification of a multi-segment line string in EPSG:3857.
    @Test
    func simplify3857() async {
        let lineString = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 250.0, y: 250.0),
            Coordinate3D(x: 500.0, y: 0.0),
            Coordinate3D(x: 750.0, y: 250.0),
            Coordinate3D(x: 1000.0, y: 0.0),
        ])
        let simplified = lineString.simplified(tolerance: 100.0)
        #expect(simplified.coordinates.count <= lineString.coordinates.count)
        #expect(simplified.coordinates.count >= 2)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]))
        let simplified = lineString.simplified(tolerance: 1.0)
        #expect(!simplified.coordinates.isEmpty)
        for coord in simplified.coordinates {
            #expect(coord.latitude >= 0.0 && coord.latitude <= 10.0)
            #expect(coord.longitude >= 170.0 && coord.longitude <= 179.0)
        }
    }

    // MARK: - topologyPreserveSimplify

    @Test
    func topologyPreserveSimpleLine() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.1, longitude: 0.1),
            Coordinate3D(latitude: 0.2, longitude: 0.0),
            Coordinate3D(latitude: 0.3, longitude: 0.1),
            Coordinate3D(latitude: 0.4, longitude: 0.0),
        ]))
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 50_000.0))
        #expect(result.coordinates.count < ls.coordinates.count)
    }

    @Test
    func topologyPreserveSelfIntersectingPolygon() throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let result = try #require(polygon.topologyPreservedSimplified(tolerance: 5_000.0))
        #expect(result.isValid)
    }

    @Test
    func topologyPreserveInvalidPolygon() throws {
        let noisy = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.001, longitude: 0.001),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.001, longitude: 10.001),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.001, longitude: 9.999),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 9.999, longitude: 0.001),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let result = try #require(noisy.topologyPreservedSimplified(tolerance: 100.0))
        #expect(result.isValid)
    }

    @Test
    func topologyPreserve3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 50.0),
            Coordinate3D(x: 200.0, y: 0.0),
            Coordinate3D(x: 300.0, y: 50.0),
            Coordinate3D(x: 400.0, y: 0.0),
        ])
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 50.0))
        #expect(result.coordinates.count < ls.coordinates.count)
    }

    // MARK: - polygonHullSimplify

    @Test
    func polygonHullSimpleSquare() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.polygonHullSimplified(tolerance: 1.0))
        #expect(result.isValid)
    }

    @Test
    func polygonHullSelfIntersecting() throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let result = try #require(polygon.polygonHullSimplified(tolerance: 5_000.0))
        #expect(result.isValid)
    }

    @Test
    func polygonHull3857() throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let result = try #require(polygon.polygonHullSimplified(tolerance: 10.0))
        #expect(result.isValid)
    }

    @Test
    func multiPolygonHullSimplified() throws {
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
        let result = try #require(mp.polygonHullSimplified(tolerance: 10.0))
        #expect(result.polygons.count == 2)
        for p in result.polygons {
            #expect(p.isValid)
        }
    }

    // MARK: - coverageSimplify

    @Test
    func coverageSimplifyAdjacentTiles() throws {
        let tile1 = MapTile(x: 0, y: 0, z: 1)
        let tile2 = MapTile(x: 1, y: 0, z: 1)

        func polygon(from bbox: BoundingBox) -> Polygon {
            Polygon(unchecked: [[
                bbox.southWest,
                Coordinate3D(latitude: bbox.southWest.latitude, longitude: bbox.northEast.longitude),
                bbox.northEast,
                Coordinate3D(latitude: bbox.northEast.latitude, longitude: bbox.southWest.longitude),
                bbox.southWest,
            ]])
        }

        let p1 = polygon(from: tile1.boundingBox())
        let p2 = polygon(from: tile2.boundingBox())
        let mp = MultiPolygon(unchecked: [p1, p2])
        let result = try #require(mp.coverageSimplified(tolerance: 10_000.0))
        #expect(result.polygons.count == 2)
        let rightEdge = result.polygons[0].coordinates[0][1]
        let leftEdge = result.polygons[1].coordinates[0][3]
        #expect(rightEdge == leftEdge)
    }

    @Test
    func coverageSimplify3857() throws {
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
        let result = try #require(mp.coverageSimplified(tolerance: 50.0))
        #expect(result.polygons.count == 2)
        let verts0 = result.polygons[0].coordinates[0]
        let verts1 = result.polygons[1].coordinates[0]
        let endpoints0 = Set(verts0.filter { $0.x == 1000 }.map { "\($0.x),\($0.y)" })
        let endpoints1 = Set(verts1.filter { $0.x == 1000 }.map { "\($0.x),\($0.y)" })
        #expect(endpoints0 == endpoints1)
    }

    @Test
    func coverageSimplifySinglePolygon() throws {
        let p = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let mp = MultiPolygon([p])!
        let result = try #require(mp.coverageSimplified(tolerance: 1.0))
        #expect(result.polygons.count == 1)
    }

    // MARK: - Antimeridian

    @Test
    func topologyPreserveAntimeridian() throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 1.0))
        #expect(result.isValid)
    }

}

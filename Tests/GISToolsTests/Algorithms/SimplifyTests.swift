import Foundation
@testable import GISTools
import Testing

struct SimplifyTests {

    // Validates that invalid polygons are returned unmodified when simplified.
    @Test
    func invalidPolygons() async throws {
        let polygon1 = MultiPolygon([[[
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 0.0),
            Coordinate3D(latitude: 2.5, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0)
        ]]])
        let polygon2 = MultiPolygon([[[
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0)
        ]]])
        #expect(polygon1?.simplified() == polygon1)
        #expect(polygon2?.simplified() == polygon2)
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

    // MARK: - Grid size

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

    // MARK: - Projections

    // Validates simplification of a multi-segment line string in EPSG:3857.
    @Test
    func simplify3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 250.0, y: 250.0),
            Coordinate3D(x: 500.0, y: 0.0),
            Coordinate3D(x: 750.0, y: 250.0),
            Coordinate3D(x: 1000.0, y: 0.0),
        ]))
        let simplified = lineString.simplified(tolerance: 100.0)
        #expect(simplified.coordinates.count <= lineString.coordinates.count)
        #expect(simplified.coordinates.count >= 2)
        #expect(simplified.projection == .epsg3857)
    }

    // Validates simplification of a multi-segment line string in EPSG:4978.
    @Test
    func simplify4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 250.0, y: 250.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 500.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 750.0, y: 250.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let simplified = lineString.simplified(tolerance: 100.0)
        #expect(simplified.coordinates.count <= lineString.coordinates.count)
        #expect(simplified.coordinates.count >= 2)
        #expect(simplified.projection == .epsg4978)
    }


    // Validates simplification in noSRID (Euclidean) projection.
    @Test
    func simplifyNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 25.0, y: 25.0, projection: .noSRID),
            Coordinate3D(x: 50.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 75.0, y: 25.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let simplified = lineString.simplified(tolerance: 10.0)
        #expect(simplified.coordinates.count <= lineString.coordinates.count)
        #expect(simplified.coordinates.count >= 2)
        #expect(simplified.projection == .noSRID)
    }

    // MARK: - Antimeridian

    // Tests simplification of a line crossing the antimeridian.
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

    // Tests topology-preserving simplify on a simple line.
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

    // Tests topology-preserving simplify on a self-intersecting polygon.
    @Test
    func topologyPreserveSelfIntersectingPolygon() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.topologyPreservedSimplified(tolerance: 5_000.0))
        #expect(result.isValid)
    }

    // Tests topology-preserving simplify on a noisy polygon.
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

    // Tests topology-preserving simplify in EPSG:3857.
    @Test
    func topologyPreserve3857() throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 50.0),
            Coordinate3D(x: 200.0, y: 0.0),
            Coordinate3D(x: 300.0, y: 50.0),
            Coordinate3D(x: 400.0, y: 0.0),
        ]))
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 50.0))
        #expect(result.coordinates.count < ls.coordinates.count)
        #expect(result.projection == .epsg3857)
    }

    // MARK: - polygonHullSimplify

    // Tests polygon hull simplification on a simple square.
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

    // Tests polygon hull simplification on a self-intersecting polygon.
    @Test
    func polygonHullSelfIntersecting() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.polygonHullSimplified(tolerance: 5_000.0))
        #expect(result.isValid)
    }

    // Tests polygon hull simplification in EPSG:3857.
    @Test
    func polygonHull3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let result = try #require(polygon.polygonHullSimplified(tolerance: 10.0))
        #expect(result.isValid)
    }

    // Tests polygon hull simplification on a MultiPolygon.
    @Test
    func multiPolygonHullSimplified() throws {
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
        let result = try #require(mp.polygonHullSimplified(tolerance: 10.0))
        #expect(result.polygons.count == 2)
        for p in result.polygons {
            #expect(p.isValid)
        }
    }

    // MARK: - coverageSimplify

    // Tests coverage simplify preserves shared edges between adjacent tiles.
    @Test
    func coverageSimplifyAdjacentTiles() throws {
        let tile1 = MapTile(x: 0, y: 0, z: 1)
        let tile2 = MapTile(x: 1, y: 0, z: 1)

        func polygon(from bbox: BoundingBox) throws -> Polygon {
            try #require(Polygon([[
                bbox.southWest,
                Coordinate3D(latitude: bbox.southWest.latitude, longitude: bbox.northEast.longitude),
                bbox.northEast,
                Coordinate3D(latitude: bbox.northEast.latitude, longitude: bbox.southWest.longitude),
                bbox.southWest,
            ]]))
        }

        let p1 = try polygon(from: tile1.boundingBox())
        let p2 = try polygon(from: tile2.boundingBox())
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.coverageSimplified(tolerance: 10_000.0))
        #expect(result.polygons.count == 2)
        let rightEdge = result.polygons[0].coordinates[0][1]
        let leftEdge = result.polygons[1].coordinates[0][3]
        #expect(rightEdge == leftEdge)
    }

    // Tests coverage simplify in EPSG:3857.
    @Test
    func coverageSimplify3857() throws {
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
        let result = try #require(mp.coverageSimplified(tolerance: 50.0))
        #expect(result.polygons.count == 2)
        let verts0 = result.polygons[0].coordinates[0]
        let verts1 = result.polygons[1].coordinates[0]
        let endpoints0 = Set(verts0.filter { $0.x == 1000 }.map { "\($0.x),\($0.y)" })
        let endpoints1 = Set(verts1.filter { $0.x == 1000 }.map { "\($0.x),\($0.y)" })
        #expect(endpoints0 == endpoints1)
    }

    // Tests coverage simplify with a single polygon.
    @Test
    func coverageSimplifySinglePolygon() throws {
        let p = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([p]))
        let result = try #require(mp.coverageSimplified(tolerance: 1.0))
        #expect(result.polygons.count == 1)
    }

    // MARK: - Antimeridian

    // Tests topology-preserving simplify on a line crossing the antimeridian.
    @Test
    func topologyPreserveAntimeridian() throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 1.0))
        #expect(result.isValid)
        #expect(result.projection == .epsg4326)
    }

}

import Foundation
@testable import GISTools
import Testing

struct SimplifyTests {

    /// Validates that invalid polygons are returned unmodified when simplified.
    @Test
    func invalidPolygons() {
        let polygon1 = MultiPolygon([[[
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 0.0),
            Coordinate3D(latitude: 2.5, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]])
        let polygon2 = MultiPolygon([[[
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]])
        #expect(polygon1?.simplified() == polygon1)
        #expect(polygon2?.simplified() == polygon2)
    }

    /// Validates that simplification with degenerate rings does not enter an endless loop.
    @Test
    func ringValidationBackoff() {
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

    /// Validates that `simplified(tolerance:highQuality:gridSize:)` matches manual pre-snapping.
    @Test
    func simplifyWithGridSize() throws {
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

    /// Validates simplification of a multi-segment line string in EPSG:3857.
    @Test
    func simplify3857() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 250.0, y: 250.0, projection: .epsg3857),
            Coordinate3D(x: 500.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 750.0, y: 250.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
        ]))
        let simplified = lineString.simplified(tolerance: 100.0)
        #expect(simplified.coordinates.count <= lineString.coordinates.count)
        #expect(simplified.coordinates.count >= 2)
        #expect(simplified.projection == .epsg3857)
    }

    /// Validates simplification of a multi-segment line string in EPSG:4978.
    @Test
    func simplify4978() throws {
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

    /// Validates simplification in noSRID (Euclidean) projection.
    @Test
    func simplifyNoSRID() throws {
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

    /// Tests simplification of a line crossing the antimeridian.
    @Test
    func antimeridian() throws {
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

    /// Tests topology-preserving simplify on a simple line.
    @Test
    func topologyPreserveSimpleLine() throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.1, longitude: 0.1),
            Coordinate3D(latitude: 0.2, longitude: 0.0),
            Coordinate3D(latitude: 0.3, longitude: 0.1),
            Coordinate3D(latitude: 0.4, longitude: 0.0),
        ]))
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 50000.0))
        #expect(result.coordinates.count < ls.coordinates.count)
    }

    /// Tests topology-preserving simplify on a self-intersecting polygon.
    @Test
    func topologyPreserveSelfIntersectingPolygon() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.topologyPreservedSimplified(tolerance: 5000.0))
        #expect(result.isValid)
    }

    /// Tests topology-preserving simplify on a noisy polygon.
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

    /// Tests topology-preserving simplify in EPSG:3857.
    @Test
    func topologyPreserve3857() throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 100.0, y: 50.0, projection: .epsg3857),
            Coordinate3D(x: 200.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 300.0, y: 50.0, projection: .epsg3857),
            Coordinate3D(x: 400.0, y: 0.0, projection: .epsg3857),
        ]))
        let result = try #require(ls.topologyPreservedSimplified(tolerance: 50.0))
        #expect(result.coordinates.count < ls.coordinates.count)
        #expect(result.projection == .epsg3857)
    }

    // MARK: - polygonHullSimplify

    /// Tests polygon hull simplification on a simple square.
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

    /// Tests polygon hull simplification on a self-intersecting polygon.
    @Test
    func polygonHullSelfIntersecting() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.polygonHullSimplified(tolerance: 5000.0))
        #expect(result.isValid)
    }

    /// Tests polygon hull simplification in EPSG:3857.
    @Test
    func polygonHull3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let result = try #require(polygon.polygonHullSimplified(tolerance: 10.0))
        #expect(result.isValid)
    }

    /// Tests polygon hull simplification on a MultiPolygon.
    @Test
    func multiPolygonHullSimplified() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857),
            Coordinate3D(x: 500.0, y: 1500.0, projection: .epsg3857),
            Coordinate3D(x: 1500.0, y: 1500.0, projection: .epsg3857),
            Coordinate3D(x: 1500.0, y: 500.0, projection: .epsg3857),
            Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let result = try #require(mp.polygonHullSimplified(tolerance: 10.0))
        #expect(result.polygons.count == 2)
        for p in result.polygons {
            #expect(p.isValid)
        }
    }

    // MARK: - coverageSimplify

    /// Tests coverage simplify preserves shared edges between adjacent tiles.
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
        let result = try #require(mp.coverageSimplified(tolerance: 10000.0))
        #expect(result.polygons.count == 2)
        // Shared chains may start at a different vertex after simplification;
        // compare the shared boundary coordinates as sets.
        let rightEdge = Set(result.polygons[0]
            .coordinates[0]
            .filter { $0.longitude == 0.0 }
            .map { "\($0.longitude),\($0.latitude)" })
        let leftEdge = Set(result.polygons[1]
            .coordinates[0]
            .filter { $0.longitude == 0.0 }
            .map { "\($0.longitude),\($0.latitude)" })
        #expect(rightEdge == leftEdge)
        #expect(rightEdge.count >= 2)
    }

    /// Tests coverage simplify in EPSG:3857.
    @Test
    func coverageSimplify3857() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 2000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 2000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
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

    /// Tests coverage simplify with a single polygon.
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

    /// Tests topology-preserving simplify on a line crossing the antimeridian.
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

    // MARK: - Tolerance conversion

    /// Validates that the metre-to-degree tolerance conversion depends on the
    /// latitude, not on the longitude, of the geometry (regression test).
    @Test
    func toleranceConversionIsIndependentOfLongitude() throws {
        /// A zigzag line with 100 points spread over a few kilometres.
        func zigzag(longitude: Double) throws -> LineString {
            let coordinates = (0 ..< 100).map { i in
                Coordinate3D(
                    latitude: 40.0 + (Double(i) * 0.0005),
                    longitude: longitude + (i.isMultiple(of: 2) ? 0.0 : 0.001))
            }
            return try #require(LineString(coordinates))
        }

        let atGreenwich = try zigzag(longitude: 0.0)
        let atMinus90 = try zigzag(longitude: -90.0)
        let atMinus111 = try zigzag(longitude: -111.0)

        let simplifiedAtGreenwich = atGreenwich.simplified(tolerance: 10.0)
        let simplifiedAtMinus90 = atMinus90.simplified(tolerance: 10.0)
        let simplifiedAtMinus111 = atMinus111.simplified(tolerance: 10.0)

        // The zigzag amplitude (~85m) is far above the tolerance, so most
        // vertices must survive regardless of the meridian.
        #expect(simplifiedAtGreenwich.coordinates.count > 50)
        #expect(simplifiedAtMinus90.coordinates.count == simplifiedAtGreenwich.coordinates.count)
        #expect(simplifiedAtMinus111.coordinates.count == simplifiedAtGreenwich.coordinates.count)

        // The degree conversion only applies to geographic projections;
        // planar projections (e.g. EPSG:3857) pass meters through directly.
        let planarLine = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 250.0, y: 250.0, projection: .epsg3857),
            Coordinate3D(x: 500.0, y: 0.0, projection: .epsg3857),
        ]))
        #expect(planarLine.simplified(tolerance: 100.0).projection == .epsg3857)
    }

}

// MARK: - Audit regressions

extension SimplifyTests {

    @Test
    func coverageSimplifiedSimplifiesSinglePolygon() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.00001, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 3.0),
            Coordinate3D(latitude: 1.0, longitude: 3.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([polygon]))
        let result = try #require(multiPolygon.coverageSimplified(tolerance: 100.0))
        let simplified = try #require(result.polygons.first)

        #expect(try #require(simplified.outerRing?.coordinates.count) < polygon.outerRing!.coordinates.count)
    }

    /// `polygonHullSimplified` keeps holes (and their winding) instead of
    /// returning only the outer ring.
    @Test
    func polygonHullKeepsHoles() throws {
        let outer: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10000.0, y: 10000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]
        let hole: [Coordinate3D] = [
            Coordinate3D(x: 3000.0, y: 3000.0, projection: .noSRID),
            Coordinate3D(x: 3000.0, y: 7000.0, projection: .noSRID),
            Coordinate3D(x: 7000.0, y: 7000.0, projection: .noSRID),
            Coordinate3D(x: 7000.0, y: 3000.0, projection: .noSRID),
            Coordinate3D(x: 3000.0, y: 3000.0, projection: .noSRID),
        ]
        let polygon = try #require(Polygon([outer, hole]))
        let result = try #require(polygon.polygonHullSimplified(tolerance: 100.0))

        #expect(result.innerRings?.count == 1)
        #expect(result.outerRing?.isCounterClockwise == true)
        #expect(result.innerRings?.first?.isClockwise == true)
        #expect(abs(result.area - 84_000_000.0) < 1.0)
    }

    /// Visvalingam-Whyatt threshold is a perpendicular-distance threshold:
    /// the same 5 m spike is removed from a 1000 m base and a 50 m base with
    /// a 10 m tolerance.
    @Test
    func visvalingamThresholdIsDimensionallyCorrect() throws {
        func spikedRing(base: Double) throws -> Polygon {
            try #require(Polygon([[
                Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
                Coordinate3D(x: base / 2.0, y: 5.0, projection: .noSRID),
                Coordinate3D(x: base, y: 0.0, projection: .noSRID),
                Coordinate3D(x: base, y: 1000.0, projection: .noSRID),
                Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
                Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            ]]))
        }

        for base in [1000.0, 50.0] {
            let polygon = try spikedRing(base: base)
            let simplified = try #require(
                polygon.polygonHullSimplified(tolerance: 10.0),
            )
            #expect(
                simplified.outerRing?.coordinates.count == 5,
                "base \(base): spike was not removed",
            )
        }

        // A 20 m spike exceeds the same tolerance and must survive.
        let tallSpike = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 500.0, y: 20.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let simplifiedTall = try #require(
            tallSpike.polygonHullSimplified(tolerance: 10.0),
        )
        #expect(simplifiedTall.outerRing?.coordinates.count == 6)
    }

    /// A multi-vertex shared edge must be simplified once and reused by both
    /// incident polygons, leaving no T-junction.
    @Test
    func coverageSimplifyMultiVertexSharedEdge() throws {
        func coordinate(_ x: Double, _ y: Double) -> Coordinate3D {
            Coordinate3D(x: x, y: y, projection: .noSRID)
        }

        let shared: [Coordinate3D] = [
            coordinate(1000.0, 0.0),
            coordinate(1000.0, 250.0),
            coordinate(1000.0, 500.0),
            coordinate(1000.0, 750.0),
            coordinate(1000.0, 1000.0),
        ]

        let left = try #require(Polygon([[
            coordinate(0.0, 0.0),
            shared[0],
            shared[1],
            shared[2],
            shared[3],
            shared[4],
            coordinate(0.0, 1000.0),
            coordinate(0.0, 0.0),
        ]]))
        let right = try #require(Polygon([[
            shared.reversed()[0],
            shared.reversed()[1],
            shared.reversed()[2],
            shared.reversed()[3],
            shared.reversed()[4],
            coordinate(2000.0, 0.0),
            coordinate(2000.0, 1000.0),
            shared.reversed()[0],
        ]]))

        let coverage = try #require(MultiPolygon([left, right]))
        let result = try #require(coverage.coverageSimplified(tolerance: 100.0))
        #expect(result.polygons.count == 2)

        let leftShared = result.polygons[0]
            .coordinates[0]
            .filter { $0.x == 1000.0 }
            .map { "\($0.x),\($0.y)" }
        let rightShared = result.polygons[1]
            .coordinates[0]
            .filter { $0.x == 1000.0 }
            .map { "\($0.x),\($0.y)" }

        #expect(Set(leftShared) == Set(rightShared))
        #expect(leftShared.count >= 2)
    }

    @Test
    func highQualitySimplifyPreservesEndpointsAndValidity() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.2, longitude: 0.1),
            Coordinate3D(latitude: 0.35, longitude: 0.25),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.3, longitude: 1.6),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let simplified = line.simplified(tolerance: 10000.0, highQuality: true)
        #expect(simplified.coordinates.count <= line.coordinates.count)
        #expect(simplified.firstCoordinate == line.firstCoordinate)
        #expect(simplified.lastCoordinate == line.lastCoordinate)
        #expect(simplified.isValid)
    }

    @Test
    func simplifyPreservesFeatureMetadata() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.5),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        let feature = Feature(
            line,
            id: .string("route"),
            properties: ["name": "Route"],
            calculateBoundingBox: true)
        let collection = FeatureCollection([feature])

        let simplifiedFeature = feature.simplified(tolerance: 10000.0)
        #expect(simplifiedFeature.id == .string("route"))
        #expect(simplifiedFeature.property(for: "name") as String? == "Route")
        #expect(simplifiedFeature.boundingBox != nil)

        let simplifiedCollection = collection.simplified(tolerance: 10000.0)
        #expect(simplifiedCollection.features.count == 1)
        #expect(simplifiedCollection.features[0].id == .string("route"))
        #expect(simplifiedCollection.features[0].property(for: "name") as String? == "Route")
    }

    @Test
    func coverageSimplifyPreservesSharedChainForTwoPolygons() throws {
        let first = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let second = try #require(Polygon([[
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 20.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 20.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]]))
        let coverage = try #require(MultiPolygon([first, second]))
        let simplified = try #require(coverage.coverageSimplified(tolerance: 1.0))

        #expect(simplified.polygons.count == 2)
        let sharedFirst = simplified.polygons[0]
            .coordinates
            .flatMap(\.self)
            .filter { abs($0.x - 10.0) < 0.000001 }
        let sharedSecond = simplified.polygons[1]
            .coordinates
            .flatMap(\.self)
            .filter { abs($0.x - 10.0) < 0.000001 }
        #expect(!sharedFirst.isEmpty)
        #expect(!sharedSecond.isEmpty)
        #expect(Set(sharedFirst.map { "\($0.x),\($0.y)" })
            == Set(sharedSecond.map { "\($0.x),\($0.y)" }))
    }

}

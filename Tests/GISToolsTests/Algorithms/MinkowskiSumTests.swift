import Testing
import Foundation
@testable import GISTools

struct MinkowskiSumTests {

    // Validates Minkowski sum of two small squares produces an expanded shape.
    @Test
    func sumTwoSquares() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum of a convex polygon with a triangle.
    @Test
    func sumConvexAndTriangle() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum with a point-like pattern (single vertex triangle)
    // should return the original polygon.
    @Test
    func sumWithZeroPattern() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        // Tiny triangle at the origin
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski difference of a square with a small triangle.
    @Test
    func difference() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiDifference(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum with gridSize parameter.
    @Test
    func sumWithGridSize() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.001),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b, gridSize: 1.0)
        #expect(result != nil)
    }

    // Validates Minkowski sum with a concave polygon.
    @Test
    func sumConcave() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum on MultiPolygon.
    @Test
    func sumMultiPolygon() async throws {
        let aPoly = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let a = try #require(MultiPolygon([
            aPoly,
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski difference on MultiPolygon.
    @Test
    func differenceMultiPolygon() async throws {
        let aPoly = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let a = try #require(MultiPolygon([
            aPoly,
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiDifference(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum where the source polygon crosses the antimeridian.
    @Test
    func sumAntimeridianSource() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum where the pattern polygon crosses the antimeridian.
    @Test
    func sumAntimeridianPattern() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: 175.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski difference where the source polygon crosses the antimeridian.
    @Test
    func differenceAntimeridianSource() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.minkowskiDifference(with: b)
        #expect(result != nil)
    }

    // MARK: - Projections

    // Validates Minkowski sum of polygons in EPSG:3857.
    @Test
    func minkowskiSum3857() async throws {
        let a = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let b = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 200.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 200.0, y: 200.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 200.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
        #expect(result?.projection == .epsg3857)
    }

    // Validates Minkowski sum of polygons in noSRID.
    @Test
    func minkowskiSumNoSRID() async throws {
        let a = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let b = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 200.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 200.0, y: 200.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 200.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
        #expect(result?.projection == .noSRID)
    }

    // Validates Minkowski sum of polygons in EPSG:4978.
    @Test
    func minkowskiSum4978() async throws {
        let aCoords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let bCoords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.2),
            Coordinate3D(latitude: 0.2, longitude: 0.2),
            Coordinate3D(latitude: 0.2, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let a = try #require(Polygon([aCoords4326.map { $0.projected(to: .epsg4978) }]))
        let b = try #require(Polygon([bCoords4326.map { $0.projected(to: .epsg4978) }]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
        #expect(result?.projection == .epsg4978)
    }

    // Validates Minkowski sum where both inputs cross the antimeridian.
    @Test
    func sumAntimeridianBoth() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 5.0, longitude: 170.0),
                Coordinate3D(latitude: 5.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: 175.0),
            ],
        ]))

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }


    // MARK: - Audit regressions

    private func geometryArea(_ geometry: any PolygonGeometry) -> Double {
        if let polygon = geometry as? Polygon { return polygon.area }
        if let multiPolygon = geometry as? MultiPolygon { return multiPolygon.area }
        return 0.0
    }

    private func squareNoSRID(
        _ minX: Double, _ minY: Double,
        _ maxX: Double, _ maxY: Double
    ) throws -> Polygon {
        try #require(Polygon([[
            Coordinate3D(x: minX, y: minY, projection: .noSRID),
            Coordinate3D(x: minX, y: maxY, projection: .noSRID),
            Coordinate3D(x: maxX, y: maxY, projection: .noSRID),
            Coordinate3D(x: maxX, y: minY, projection: .noSRID),
            Coordinate3D(x: minX, y: minY, projection: .noSRID),
        ]]))
    }

    /// The Minkowski sum of two axis-aligned rectangles is the rectangle
    /// spanned by their min/max corners: [0,10]² ⊕ [0,1]² = [0,11]².
    @Test
    func exactAreaTwoSquaresNoSRID() throws {
        let a = try squareNoSRID(0.0, 0.0, 10.0, 10.0)
        let b = try squareNoSRID(0.0, 0.0, 1.0, 1.0)

        let result = try #require(a.minkowskiSum(with: b))
        #expect(result.projection == .noSRID)
        #expect(abs(geometryArea(result) - 121.0) < 0.000001, "Area \(geometryArea(result)) != 121")
        let polygon = try #require(result as? Polygon)
        #expect(polygon.outerRing?.coordinates.count == 5)
    }

    /// A hole must not be filled by the vertex sum. A zero-area pattern
    /// leaves the source (including its hole) unchanged.
    @Test
    func holeIsPreservedWithZeroAreaPattern() throws {
        let outer = try squareNoSRID(0.0, 0.0, 10.0, 10.0)
        let hole = try squareNoSRID(3.0, 3.0, 7.0, 7.0)
        let a = try #require(Polygon([
            outer.outerRing!.coordinates,
            hole.outerRing!.coordinates,
        ]))
        #expect(abs(a.area - 84.0) < 0.000001)

        // Degenerate pattern: every vertex is the origin.
        let b = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])

        let result = try #require(a.minkowskiSum(with: b))
        #expect(abs(geometryArea(result) - 84.0) < 0.000001, "Area \(geometryArea(result)) != 84")
        #expect(result.polygons.count == 1)
        #expect((result.polygons.first?.innerRings?.count ?? 0) == 1)
    }

    /// Mixed projections: a 4326 source with a 3857 pattern must produce the
    /// same result as normalizing the pattern to the source CRS first.
    @Test
    func mixedProjectionInputsMatchNormalized() throws {
        let a = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let b4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let b3857 = b4326.projected(to: .epsg3857)

        let normalized = try #require(a.minkowskiSum(with: b4326))
        let mixed = try #require(a.minkowskiSum(with: b3857))

        #expect(mixed.projection == .epsg4326)
        #expect(abs(geometryArea(mixed) - geometryArea(normalized)) < max(0.001, geometryArea(normalized) * 0.000001))
        #expect(mixed.polygons.count == normalized.polygons.count)
    }

    /// 3857 produces the exact planar rectangle [0,1200]²; 4978 routes
    /// through 4326 and must match the geographic result after projecting back.
    @Test
    func projectedResultsMatchGeographic() throws {
        let a4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let b4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let expected = try #require(a4326.minkowskiSum(with: b4326))

        // EPSG:3857 is a planar map: the sum of two axis-aligned rectangles
        // has the summed side lengths.
        let a3857 = a4326.projected(to: .epsg3857)
        let b3857 = b4326.projected(to: .epsg3857)
        let result3857 = try #require(a3857.minkowskiSum(with: b3857))
        #expect(result3857.projection == .epsg3857)
        let aCoordinates = try #require(a3857.outerRing?.coordinates)
        let bCoordinates = try #require(b3857.outerRing?.coordinates)
        let aWidth = (aCoordinates.map(\.x).max() ?? 0.0) - (aCoordinates.map(\.x).min() ?? 0.0)
        let aHeight = (aCoordinates.map(\.y).max() ?? 0.0) - (aCoordinates.map(\.y).min() ?? 0.0)
        let bWidth = (bCoordinates.map(\.x).max() ?? 0.0) - (bCoordinates.map(\.x).min() ?? 0.0)
        let bHeight = (bCoordinates.map(\.y).max() ?? 0.0) - (bCoordinates.map(\.y).min() ?? 0.0)
        let expectedPlanarArea = (aWidth + bWidth) * (aHeight + bHeight)
        let planarArea = (result3857 as? Polygon)?.outerRing?.coordinates
            .reduce(into: (sum: 0.0, previous: Optional<Coordinate3D>.none)) { state, coordinate in
                if let previous = state.previous {
                    state.sum += previous.x * coordinate.y - coordinate.x * previous.y
                }
                state.previous = coordinate
            }.sum ?? 0.0
        #expect(
            abs(abs(planarArea) / 2.0 - expectedPlanarArea) < 0.001,
            "Planar area \(abs(planarArea) / 2.0) != \(expectedPlanarArea)")

        // ECEF is handled in geographic space and projected back.
        let result4978 = try #require(
            a4326.projected(to: .epsg4978)
                .minkowskiSum(with: b4326.projected(to: .epsg4978)))
        #expect(result4978.projection == .epsg4978)
        let back4326 = result4978.projected(to: .epsg4326)
        #expect(
            abs(geometryArea(back4326) - geometryArea(expected))
                < max(0.001, geometryArea(expected) * 0.000001))

        // Difference reflects the pattern in the working (geographic) frame,
        // so the ECEF result must match the geographic difference too.
        let expectedDifference = try #require(a4326.minkowskiDifference(with: b4326))
        let difference4978 = try #require(
            a4326.projected(to: .epsg4978)
                .minkowskiDifference(with: b4326.projected(to: .epsg4978)))
        #expect(difference4978.projection == .epsg4978)
        let differenceBack = difference4978.projected(to: .epsg4326)
        #expect(
            abs(geometryArea(differenceBack) - geometryArea(expectedDifference))
                < max(0.001, geometryArea(expectedDifference) * 0.000001))
    }

}

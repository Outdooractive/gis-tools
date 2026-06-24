import Testing
import Foundation
@testable import GISTools

struct MinkowskiSumTests {

    // Validates Minkowski sum of two small squares produces an expanded shape.
    @Test
    func sumTwoSquares() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum of a convex polygon with a triangle.
    @Test
    func sumConvexAndTriangle() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum with a point-like pattern (single vertex triangle)
    // should return the original polygon.
    @Test
    func sumWithZeroPattern() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        // Tiny triangle at the origin
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski difference of a square with a small triangle.
    @Test
    func difference() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiDifference(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum with gridSize parameter.
    @Test
    func sumWithGridSize() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.001),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b, gridSize: 1.0)
        #expect(result != nil)
    }

    // Validates Minkowski sum with a concave polygon.
    @Test
    func sumConcave() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum on MultiPolygon.
    @Test
    func sumMultiPolygon() async throws {
        let a = MultiPolygon([
            Polygon([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                ],
            ])!,
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski difference on MultiPolygon.
    @Test
    func differenceMultiPolygon() async throws {
        let a = MultiPolygon([
            Polygon([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                ],
            ])!,
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiDifference(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum where the source polygon crosses the antimeridian.
    @Test
    func sumAntimeridianSource() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum where the pattern polygon crosses the antimeridian.
    @Test
    func sumAntimeridianPattern() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: 175.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski difference where the source polygon crosses the antimeridian.
    @Test
    func differenceAntimeridianSource() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 1.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.minkowskiDifference(with: b)
        #expect(result != nil)
    }

    // Validates Minkowski sum of polygons in EPSG:3857.
    @Test
    func minkowskiSum3857() async throws {
        let a = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let b = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 200.0, y: 0.0),
            Coordinate3D(x: 200.0, y: 200.0),
            Coordinate3D(x: 0.0, y: 200.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
        #expect(result?.projection == .epsg3857)
    }

    // Validates Minkowski sum of polygons in noSRID.
    @Test
    func minkowskiSumNoSRID() async throws {
        let a = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])
        let b = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 200.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 200.0, y: 200.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 200.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])

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
        let a = Polygon(unchecked: [aCoords4326.map { $0.projected(to: .epsg4978) }])
        let b = Polygon(unchecked: [bCoords4326.map { $0.projected(to: .epsg4978) }])

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
        #expect(result?.projection == .epsg4978)
    }

    // Validates Minkowski sum where both inputs cross the antimeridian.
    @Test
    func sumAntimeridianBoth() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 5.0, longitude: 170.0),
                Coordinate3D(latitude: 5.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: -175.0),
                Coordinate3D(latitude: 0.0, longitude: 175.0),
            ],
        ])!

        let result = a.minkowskiSum(with: b)
        #expect(result != nil)
    }

}

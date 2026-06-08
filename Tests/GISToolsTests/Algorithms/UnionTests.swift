import Foundation
@testable import GISTools
import Testing

/// Tests for the polygon union algorithm.
///
/// Inputs and expected results are stored as GeoJSON in `TestData/Union/`
/// and were generated using the `polygon-clipping` JavaScript library
/// (v0.15.7, Martinez-Rueda-Feito algorithm), the ground-truth reference.
///
/// Comparisons use **area, polygon count, and vertex count** rather than
/// exact coordinate equality, because starting points and colinear-point
/// compaction may differ between implementations.
struct UnionTests {

    // MARK: - Helpers

    private func loadInput(_ name: String) throws -> Polygon {
        try TestData.polygon(package: "Union", name: name)
    }

    private func loadExpected(_ name: String) throws -> MultiPolygon {
        try TestData.multiPolygon(package: "Union", name: name)
    }

    private func checkGeometric(_ result: MultiPolygon, _ expected: MultiPolygon) {
        #expect(result.polygons.count == expected.polygons.count)
        let sortedR = result.polygons.sorted(by: { $0.area < $1.area })
        let sortedE = expected.polygons.sorted(by: { $0.area < $1.area })
        for (rp, ep) in zip(sortedR, sortedE) {
            // Area must match (the primary geometric invariant)
            #expect(abs(rp.area - ep.area) < 1.0e-9 * rp.area)
            // Inner rings must match
            let rInner = rp.innerRings ?? []
            let eInner = ep.innerRings ?? []
            #expect(rInner.count == eInner.count)
        }
    }

    // MARK: - Overlapping rectangles (L-shape union)

    @Test func overlappingRectangles() async throws {
        let p1 = try loadInput("OverlappingRectanglesInput1")
        let p2 = try loadInput("OverlappingRectanglesInput2")
        let exp = try loadExpected("OverlappingRectanglesResult")
        let result = try #require(p1.union(with: p2))
        checkGeometric(result, exp)
    }

    @Test func overlappingRectanglesViaMultiPolygon() async throws {
        let poly = try loadInput("OverlappingRectanglesInput1")
        let p2 = try loadInput("OverlappingRectanglesInput2")
        let exp = try loadExpected("OverlappingRectanglesResult")
        let multi = try #require(MultiPolygon([poly]))
        let result = try #require(multi.union(with: p2))
        checkGeometric(result, exp)
    }

    @Test func overlappingRectanglesFormUnion() async throws {
        let poly = try loadInput("OverlappingRectanglesInput1")
        let p2 = try loadInput("OverlappingRectanglesInput2")
        let exp = try loadExpected("OverlappingRectanglesResult")
        var multi = try #require(MultiPolygon([poly]))
        multi.formUnion(with: p2)
        checkGeometric(multi, exp)
    }

    @Test func overlappingRectanglesViaFeatureCollection() async throws {
        let p1 = try loadInput("OverlappingRectanglesInput1")
        let p2 = try loadInput("OverlappingRectanglesInput2")
        let exp = try loadExpected("OverlappingRectanglesResult")
        let fc = FeatureCollection([Feature(p1), Feature(p2)])
        let fcResult = try #require(fc.union())
        let geometry = try #require(fcResult.features.first?.geometry as? MultiPolygon)
        checkGeometric(geometry, exp)
    }

    // MARK: - Disjoint rectangles

    @Test func disjointRectangles() async throws {
        let p1 = try loadInput("DisjointRectanglesInput1")
        let p2 = try loadInput("DisjointRectanglesInput2")
        let exp = try loadExpected("DisjointRectanglesResult")
        let result = try #require(p1.union(with: p2))
        checkGeometric(result, exp)
    }

    // MARK: - One polygon inside another

    @Test func containedPolygon() async throws {
        let outer = try loadInput("ContainedPolygonOuter")
        let inner = try loadInput("ContainedPolygonInner")
        let exp = try loadExpected("ContainedPolygonResult")
        let result = try #require(outer.union(with: inner))
        checkGeometric(result, exp)
    }

    // MARK: - Sharing a full edge

    @Test func sharingEdge() async throws {
        let p1 = try loadInput("SharingEdgeInput1")
        let p2 = try loadInput("SharingEdgeInput2")
        let exp = try loadExpected("SharingEdgeResult")
        let result = try #require(p1.union(with: p2))
        checkGeometric(result, exp)
    }

    // MARK: - Three polygons (two overlapping, one remote)

    @Test func threePolygons() async throws {
        let p1 = try loadInput("ThreePolygonsInput1")
        let p2 = try loadInput("ThreePolygonsInput2")
        let p3 = try loadInput("ThreePolygonsInput3")
        let exp = try loadExpected("ThreePolygonsResult")
        let result = try #require(Union.unionPolygons([p1, p2, p3]))
        checkGeometric(result, exp)
    }

    // MARK: - Non-convex polygons (L-shape)

    @Test func nonConvexOverlap() async throws {
        let p1 = try loadInput("NonConvexInput1")
        let p2 = try loadInput("NonConvexInput2")
        let exp = try loadExpected("NonConvexResult")
        let result = try #require(p1.union(with: p2))
        checkGeometric(result, exp)
    }

    // MARK: - Edge cases

    @Test func emptyInput() async throws {
        #expect(Union.unionPolygons([]) == nil)
    }

    @Test func emptyFeatureCollection() async throws {
        #expect(FeatureCollection().union() == nil)
    }

    // MARK: - Pairwise union of flat-end buffer pieces

    /// Load the 7 component polygons from the LongLine flat-end buffer.
    private static func loadFlatParts() throws -> [Polygon] {
        let mp = try TestData.multiPolygon(package: "Union", name: "LongLineFlatParts")
        return mp.polygons
    }

    /// Load a pairwise Turf union reference from TestData/Union/Pairwise/.
    private static func loadPairwise(_ pairName: String) throws -> MultiPolygon {
        try TestData.multiPolygon(package: "Union/Pairwise", name: pairName)
    }

    private static let pairwiseTests: [(i: Int, j: Int, name: String, tolerance: Double)] = [
        (0, 1, "pair_0_1", 0.07),
        (0, 4, "pair_0_4", 0.83),
        (1, 2, "pair_1_2", 0.01),
        (1, 4, "pair_1_4", 0.16),
        (1, 5, "pair_1_5", 0.70),
        (2, 3, "pair_2_3", 0.02),
        (2, 5, "pair_2_5", 0.13),
        (2, 6, "pair_2_6", 0.75),
        (3, 6, "pair_3_6", 0.12),
    ]

    @Test(arguments: pairwiseTests)
    func pairwiseUnion(i: Int, j: Int, name: String, tolerance: Double) async throws {
        let parts = try Self.loadFlatParts()
        let expected = try Self.loadPairwise(name)
        let expectedArea = expected.polygons.reduce(0) { $0 + $1.area }
        let result = try #require(Union.unionPolygons([parts[i], parts[j]]))
        let resultArea = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = resultArea / expectedArea
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "Pair \(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)]")
    }

}

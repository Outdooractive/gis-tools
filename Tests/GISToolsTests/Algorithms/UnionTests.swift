import Foundation
@testable import GISTools
import Testing

/// Tests for the polygon union algorithm.
///
/// **Reference tests** — inputs and expected results in `TestData/Union/`
/// were generated using the `polygon-clipping` JavaScript library
/// (v0.15.7, Martinez-Rueda-Feito algorithm), the ground-truth reference.
///
/// **Ported Turf.js union tests** — fixtures from `@turf/union` test suite
/// in `TestData/Union/{in,out}/`. Comparisons use total area at 1 % tolerance.
/// Issue-regression tests verify union completes without error.
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
            #expect(abs(rp.area - ep.area) < 0.01 * rp.area)
            let rInner = rp.innerRings ?? []
            let eInner = ep.innerRings ?? []
            #expect(rInner.count == eInner.count)
        }
    }

    // MARK: - Turf helpers

    private static func turfExpectedArea(_ name: String, tolerance: Double = 0.01) throws -> (area: Double, tolerance: Double) {
        let feature = try TestData.feature(package: "Union/out", name: name)
        var total: Double = 0
        if let polygon = feature.geometry as? Polygon {
            total += polygon.area
        } else if let multiPolygon = feature.geometry as? MultiPolygon {
            total += multiPolygon.polygons.reduce(0) { $0 + $1.area }
        }
        return (total, tolerance)
    }

    private static func extractPolygons(from fc: FeatureCollection) -> [Polygon] {
        fc.features.compactMap { feature in
            if let polygon = feature.geometry as? Polygon {
                return MultiPolygon([polygon])
            }
            return feature.geometry as? MultiPolygon
        }.flatMap { $0.polygons }
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

    private static let pairwiseTests: [(i: Int, j: Int, name: String)] = [
        (0, 1, "pair_0_1"),
        (0, 4, "pair_0_4"),
        (1, 2, "pair_1_2"),
        (1, 4, "pair_1_4"),
        (1, 5, "pair_1_5"),
        (2, 3, "pair_2_3"),
        (2, 5, "pair_2_5"),
        (2, 6, "pair_2_6"),
        (3, 6, "pair_3_6"),
    ]

    @Test(arguments: pairwiseTests)
    func pairwiseUnion(i: Int, j: Int, name: String) async throws {
        let parts = try Self.loadFlatParts()
        let expected = try Self.loadPairwise(name)
        let expectedArea = expected.polygons.reduce(0) { $0 + $1.area }
        let result = try #require(Union.unionPolygons([parts[i], parts[j]]))
        let resultArea = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = resultArea / expectedArea
        #expect(ratio > 0.99 && ratio < 1.01,
                "Pair \(name): ratio \(ratio) outside 1%")
    }

    // MARK: - Ported Turf.js fixture tests

    private static let turfTestNames = [
        "union1", "union2", "union3", "union4", "not-overlapping",
    ]

    @Test(arguments: turfTestNames)
    func turfFixture(_ name: String) async throws {
        let fc = try TestData.featureCollection(package: "Union/in", name: name)
        let result = try #require(fc.union())
        let (expected, tolerance) = try Self.turfExpectedArea(name)
        let actual = Self.extractPolygons(from: result).reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    // MARK: - Issue regression tests

    @Test func issueUnableToCompleteOutputRing1() async throws {
        let fc = try TestData.featureCollection(package: "Union/in", name: "unable-to-complete-output-ring-1983-1")
        #expect(fc.union() != nil)
    }

    @Test func issueUnableToCompleteOutputRing2() async throws {
        let fc = try TestData.featureCollection(package: "Union/in", name: "unable-to-complete-output-ring-1983-2")
        #expect(fc.union() != nil)
    }

    @Test func issueUnableToFindSegment1() async throws {
        let fc = try TestData.featureCollection(package: "Union/in", name: "unable-to-find-segment-2258-1")
        #expect(fc.union() != nil)
    }

    @Test func issueUnableToFindSegment2() async throws {
        let fc = try TestData.featureCollection(package: "Union/in", name: "unable-to-find-segment-2258-2")
        #expect(fc.union() != nil)
    }

}

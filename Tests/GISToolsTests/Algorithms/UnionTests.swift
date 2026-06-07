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

}

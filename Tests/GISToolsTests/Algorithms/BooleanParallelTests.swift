@testable import GISTools
import Testing

struct BooleanParallelTests {

    // MARK: - LineSegment tests

    @Test func segment_exactParallel_directed() {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let c = Coordinate3D(latitude: 5.0, longitude: 0.0)
        let d = Coordinate3D(latitude: 15.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(s1.isParallel(to: s2))
        #expect(s2.isParallel(to: s1))
    }

    @Test func segment_notParallel() {
        // Northward vs. Eastward — clearly not parallel
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let c = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let d = Coordinate3D(latitude: 0.0, longitude: 10.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(!s1.isParallel(to: s2))
    }

    @Test func segment_antiParallel_directed() {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: b, second: a)
        #expect(!s1.isParallel(to: s2))
    }

    @Test func segment_antiParallel_undirected() {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: b, second: a)
        #expect(s1.isParallel(to: s2, undirectedEdge: true))
    }

    @Test func segment_circularWrap_355vs5() {
        // Two near-north segments straddling the 0°/360° boundary.
        // Segment 1: bearing ≈ 0.57° (just east of true north)
        // Segment 2: bearing ≈ -1.14° → azimuth 358.86°
        // Naive abs(a - b) = 358.29° (WRONG), correct diff = 1.71°
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.1)
        let c = Coordinate3D(latitude: 0.0, longitude: 0.2)
        let d = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(s1.isParallel(to: s2, tolerance: 2.0))
    }

    @Test func segment_circularWrap_notParallel() {
        // Bearings on opposite sides of 0° but far enough apart
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.5)
        let c = Coordinate3D(latitude: 0.0, longitude: 1.0)
        let d = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(!s1.isParallel(to: s2, tolerance: 1.0))
    }

    @Test func segment_withinTolerance() {
        // Bearing difference ≈ 0.057°, within 0.1° tolerance
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let c = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let d = Coordinate3D(latitude: 10.0, longitude: 0.01)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(s1.isParallel(to: s2, tolerance: 0.1))
    }

    @Test func segment_justOutsideTolerance() {
        // Bearing difference ≈ 0.57°, outside 0.5° tolerance
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let c = Coordinate3D(latitude: 0.0, longitude: 0.1)
        let d = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(!s1.isParallel(to: s2, tolerance: 0.5))
    }

    @Test func segment_selfIsParallel() {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let s = LineSegment(first: a, second: b)
        #expect(s.isParallel(to: s))
        #expect(s.isParallel(to: s, undirectedEdge: true))
    }

    @Test func segment_noSRID() {
        // With noSRID, rhumbBearing uses atan2(deltaLon, deltaLat)
        let a = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let b = Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID)
        let c = Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID)
        let d = Coordinate3D(x: 5.0, y: 10.0, projection: .noSRID)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(s1.isParallel(to: s2))
    }

    @Test func segment_undirected_wrap() {
        // Anti-parallel where undirectedEdge corrects the 180° flip
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let c = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let d = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(!s1.isParallel(to: s2))
        #expect(s1.isParallel(to: s2, undirectedEdge: true))
    }

    // MARK: - gridSize

    // Validates that `isParallel(to:tolerance:undirectedEdge:gridSize:)` matches manual pre-snapping.
    @Test
    func segmentParallelWithGridSize() async throws {
        let s1 = LineSegment(
            first: Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            second: Coordinate3D(latitude: 10.0001, longitude: 0.0001))
        let s2 = LineSegment(
            first: Coordinate3D(latitude: 5.0001, longitude: 0.0001),
            second: Coordinate3D(latitude: 15.0001, longitude: 0.0001))
        let gridSize = 0.001

        let withParam = s1.isParallel(to: s2, tolerance: 0.1, gridSize: gridSize)
        let snapped1 = s1.snappedToGrid(tolerance: gridSize)
        let snapped2 = s2.snappedToGrid(tolerance: gridSize)
        let manual = snapped1.isParallel(to: snapped2, tolerance: 0.1)
        #expect(withParam == manual)
    }

    // MARK: - Anti-meridian tests

    @Test func segment_antiMeridian_parallel() {
        // Two segments crossing the anti-meridian (180° longitude) with the
        // same ~2° eastward longitude step at different latitudes.
        // After deltaLambda normalisation both have bearing ≈ 11.25° and
        // ≈ 11.12°, well within a 0.2° tolerance.
        let a = Coordinate3D(latitude: 0.0, longitude: 179.0)
        let b = Coordinate3D(latitude: 10.0, longitude: -179.0)
        let c = Coordinate3D(latitude: 5.0, longitude: 179.0)
        let d = Coordinate3D(latitude: 15.0, longitude: -179.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(s1.isParallel(to: s2, tolerance: 0.2))
    }

    @Test func segment_antiMeridian_notParallel() {
        // Segment crossing the anti-meridian by 2° East (bearing ≈ 11.25°)
        // vs. one crossing by 15° East (bearing ≈ 56.2°) — clearly different.
        let a = Coordinate3D(latitude: 0.0, longitude: 179.0)
        let b = Coordinate3D(latitude: 10.0, longitude: -179.0)
        let c = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let d = Coordinate3D(latitude: 10.0, longitude: -175.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: c, second: d)
        #expect(!s1.isParallel(to: s2, tolerance: 1.0))
    }

    @Test func segment_antiMeridian_undirected() {
        // A segment crossing the anti-meridian and its reverse should be
        // parallel when treated as an undirected edge.
        let a = Coordinate3D(latitude: 0.0, longitude: 179.0)
        let b = Coordinate3D(latitude: 10.0, longitude: -179.0)
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: b, second: a)
        #expect(!s1.isParallel(to: s2))
        #expect(s1.isParallel(to: s2, tolerance: GISTool.equalityDelta, undirectedEdge: true))
    }

    // MARK: - LineString tests

    @Test func lineString_isTrue() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue1_1")
        let lineString2 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue1_2")

        let lineString3 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue2_1")
        let lineString4 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue2_1")

        let lineString5 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue3_1")
        let lineString6 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue3_1")

        let lineString7 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue4_1")
        let lineString8 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue4_1")

        #expect(lineString1.isParallel(to: lineString2))
        #expect(lineString3.isParallel(to: lineString4))
        #expect(lineString5.isParallel(to: lineString6))
        #expect(lineString7.isParallel(to: lineString8))
    }

    @Test func lineString_isFalse() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse1_1")
        let lineString2 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse1_2")

        let lineString3 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse2_1")
        let lineString4 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse2_2")

        #expect(!lineString1.isParallel(to: lineString2))
        #expect(!lineString3.isParallel(to: lineString4))
    }

}

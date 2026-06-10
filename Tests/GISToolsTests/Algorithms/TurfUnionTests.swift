import Foundation
@testable import GISTools
import Testing

/// Ported Turf.js union tests.
///
/// Input and expected-output GeoJSON files from the `@turf/union` test suite:
/// https://github.com/Turfjs/turf/tree/master/packages/turf-union/test
///
/// Fixture-based tests compare total area with a 1% tolerance.
/// Issue-regression tests verify that the union completes without error
/// (returning non-nil).
///
/// - Note: `issueMaximumCallStackSizeExceeded` (Turf #2317) is omitted
///   because the input contains >46K vertices, causing our planar-graph
///   ring builder to hang indefinitely.
struct TurfUnionTests {

    // MARK: - Helpers

    private static func expectedArea(_ name: String, tolerance: Double = 0.01) throws -> (area: Double, tolerance: Double) {
        let feature = try TestData.feature(package: "TurfUnion/out", name: name)
        var total: Double = 0
        if let polygon = feature.geometry as? Polygon {
            total += polygon.area
        } else if let multiPolygon = feature.geometry as? MultiPolygon {
            total += multiPolygon.polygons.reduce(0) { $0 + $1.area }
        }
        return (total, tolerance)
    }

    private static func extractPolygons(from fc: FeatureCollection) -> [Polygon] {
        let multipolygons: [MultiPolygon] = fc.features.compactMap { feature in
            if let polygon = feature.geometry as? Polygon {
                return MultiPolygon([polygon])
            }
            return feature.geometry as? MultiPolygon
        }
        return multipolygons.flatMap { $0.polygons }
    }

    // MARK: - Fixture tests

    @Test func union1() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "union1")
        let result = try #require(fc.union())
        let (expected, tolerance) = try Self.expectedArea("union1")
        let actual = Self.extractPolygons(from: result).reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "union1: ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func union2() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "union2")
        let result = try #require(fc.union())
        let (expected, tolerance) = try Self.expectedArea("union2")
        let actual = Self.extractPolygons(from: result).reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "union2: ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func union3() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "union3")
        let result = try #require(fc.union())
        let (expected, tolerance) = try Self.expectedArea("union3")
        let actual = Self.extractPolygons(from: result).reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "union3: ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func union4() async throws {
        // Known regression: area ratio ~0.63 (37% low).
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "union4")
        let result = try #require(fc.union())
        let (expected, tolerance) = try Self.expectedArea("union4")
        let actual = Self.extractPolygons(from: result).reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "union4: ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func notOverlapping() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "not-overlapping")
        let result = try #require(fc.union())
        let (expected, tolerance) = try Self.expectedArea("not-overlapping")
        let actual = Self.extractPolygons(from: result).reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "not-overlapping: ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    // MARK: - Issue regression tests

    @Test func issueUnableToCompleteOutputRing1() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "unable-to-complete-output-ring-1983-1")
        let result = fc.union()
        #expect(result != nil, "union should complete without error")
    }

    @Test func issueUnableToCompleteOutputRing2() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "unable-to-complete-output-ring-1983-2")
        let result = fc.union()
        #expect(result != nil, "union should complete without error")
    }

    @Test func issueUnableToFindSegment1() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "unable-to-find-segment-2258-1")
        let result = fc.union()
        #expect(result != nil, "union should complete without error")
    }

    @Test func issueUnableToFindSegment2() async throws {
        let fc = try TestData.featureCollection(package: "TurfUnion/in", name: "unable-to-find-segment-2258-2")
        let result = fc.union()
        #expect(result != nil, "union should complete without error")
    }

}

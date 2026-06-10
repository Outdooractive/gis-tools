import Foundation
@testable import GISTools
import Testing

/// Ported Turf.js buffer tests.
///
/// Input and expected-output GeoJSON files from the `@turf/buffer` test suite:
/// https://github.com/Turfjs/turf/tree/master/packages/turf-buffer/test
///
/// Each input file has `properties.{radius,units}` controlling the buffer
/// distance. The expected-output file is a FeatureCollection containing
/// the buffered results (stroke=#F00) and the original input (stroke=#00F)
/// for visual comparison.
///
/// Comparisons use TOTAL AREA with a 15% tolerance to account for the
/// difference between Turf's JTS offset-curve buffer and GISTools'
/// rectangle‑+‑circle‑+‑union approximation.
struct TurfBufferTests {

    private static func expectedArea(_ name: String, tolerance: Double = 0.15) throws -> (area: Double, tolerance: Double) {
        let fc = try TestData.featureCollection(package: "TurfBuffer/out", name: name)
        var total: Double = 0
        for feature in fc.features {
            guard feature.properties["stroke"] as? String == "#F00" else { continue }
            if let polygon = feature.geometry as? Polygon {
                total += polygon.area
            } else if let multiPolygon = feature.geometry as? MultiPolygon {
                total += multiPolygon.polygons.reduce(0) { $0 + $1.area }
            }
        }
        return (total, tolerance)
    }

    private static func bufferParams(_ name: String) throws -> (distance: Double, steps: Int) {
        let json = try TestData.stringFromFile(package: "TurfBuffer/in", name: name)
        guard let data = json.data(using: .utf8),
              let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return (GISTool.convertToMeters(50, .miles), 64) }
        let props = dict["properties"] as? [String: Any] ?? [:]
        let radius = props["radius"] as? Double ?? 50.0
        let units = props["units"] as? String ?? "miles"
        let steps = props["steps"] as? Int ?? 64

        let unit: GISTool.Unit
        switch units {
        case "meters", "metres": unit = .meters
        case "miles": unit = .miles
        default: unit = .miles
        }
        return (GISTool.convertToMeters(abs(radius), unit), steps)
    }

    // MARK: - Fixture tests

    @Test func featureCollectionPoints() async throws {
        let name = "feature-collection-points"
        let params = try Self.bufferParams(name)
        let fc = try TestData.featureCollection(package: "TurfBuffer/in", name: name)
        let result = try #require(fc.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func geometryCollectionPoints() async throws {
        let name = "geometry-collection-points"
        let params = try Self.bufferParams(name)
        let gc = try TestData.geometryCollection(package: "TurfBuffer/in", name: name)
        let result = try #require(gc.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func linestring() async throws {
        let name = "linestring"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? LineString)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func multiLinestring() async throws {
        let name = "multi-linestring"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? MultiLineString)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func multiPoint() async throws {
        let name = "multi-point"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? MultiPoint)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func multiPolygon() async throws {
        let name = "multi-polygon"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? MultiPolygon)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func bufferPoint() async throws {
        let name = "point"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? Point)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func polygonWithHoles() async throws {
        let name = "polygon-with-holes"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? Polygon)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func northernPolygon() async throws {
        let name = "northern-polygon"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? Polygon)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func issue783() async throws {
        let name = "issue-#783"
        let params = try Self.bufferParams(name)
        let fc = try TestData.featureCollection(package: "TurfBuffer/in", name: name)
        let result = try #require(fc.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func issue801Ecuador() async throws {
        let name = "issue-#801-Ecuador"
        let params = try Self.bufferParams(name)
        let fc = try TestData.featureCollection(package: "TurfBuffer/in", name: name)
        let result = try #require(fc.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func issue801() async throws {
        let name = "issue-#801"
        let params = try Self.bufferParams(name)
        let fc = try TestData.featureCollection(package: "TurfBuffer/in", name: name)
        let result = try #require(fc.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func issue815() async throws {
        let name = "issue-#815"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? LineString)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func issue900() async throws {
        let name = "issue-#900"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? LineString)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func issue916() async throws {
        let name = "issue-#916"
        let params = try Self.bufferParams(name)
        let fc = try TestData.featureCollection(package: "TurfBuffer/in", name: name)
        let result = try #require(fc.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    @Test func northLatitudePoints() async throws {
        let name = "north-latitude-points"
        let params = try Self.bufferParams(name)
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? MultiPoint)
        let result = try #require(geometry.buffered(by: params.distance, steps: params.steps))
        let (expected, tolerance) = try Self.expectedArea(name)
        let actual = result.polygons.reduce(0) { $0 + $1.area }
        let ratio = expected > 0 ? actual / expected : (actual == 0 ? 1 : 0)
        #expect(ratio > 1.0 - tolerance && ratio < 1.0 + tolerance,
                "\(name): ratio \(ratio) outside [\(1 - tolerance), \(1 + tolerance)], actual=\(actual), expected=\(expected)")
    }

    // MARK: - Negative buffer

    @Test func negativeBuffer() async throws {
        let name = "negative-buffer"
        let json = try TestData.stringFromFile(package: "TurfBuffer/in", name: name)
        guard let data = json.data(using: .utf8),
              let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        let props = dict["properties"] as? [String: Any] ?? [:]
        let radius = props["radius"] as? Double ?? -200.0

        // GISTools does not yet support negative buffer distances.
        #expect(radius < 0)
        // Buffering with a negative distance should return nil.
        let feature = try TestData.feature(package: "TurfBuffer/in", name: name)
        let geometry = try #require(feature.geometry as? Polygon)
        #expect(geometry.buffered(by: GISTool.convertToMeters(radius, .miles)) == nil)
    }

}

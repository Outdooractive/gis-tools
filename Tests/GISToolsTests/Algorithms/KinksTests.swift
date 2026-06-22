import Foundation
@testable import GISTools
import Testing

struct KinksTests {

    // Tests that a simple line string with two vertices has no kinks.
    @Test
    func lineStringNoKinks() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let result = ls.kinks()
        #expect(result.points.isEmpty)
    }

    // Tests that a simple closed polygon has no kinks.
    @Test
    func polygonNoKinks() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = polygon.kinks()
        #expect(result.points.isEmpty)
    }

    /// Tests that a self-intersecting (bow-tie) polygon detects kinks.
    @Test
    func polygonWithKinks() async throws {
        // Bow-tie polygon: self-intersecting
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = polygon.kinks()
        #expect(result.points.isNotEmpty)
    }

    // Tests that a self-intersecting line string detects kinks.
    @Test
    func lineStringWithKinks() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let result = ls.kinks()
        #expect(result.points.isNotEmpty)
    }

    // Tests that a multi-line string with intersecting lines detects kinks.
    @Test
    func multiLineStringWithKinks() async throws {
        let mls = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
            ],
        ]))
        let result = mls.kinks()
        // The second line crosses the first
        #expect(result.points.isNotEmpty)
    }

    // Tests that kink detection works through the Feature wrapper type.
    @Test
    func featureKinks() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(polygon)
        let result = feature.kinks()
        #expect(result.points.isNotEmpty)
    }

    // Tests that unsupported geometry types (e.g., Point) return no kinks.
    @Test
    func unsupportedGeometryKinks() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let result = point.kinks()
        #expect(result.points.isEmpty)
    }

    // MARK: - gridSize

    // Validates that `kinks(gridSize:)` matches manual pre-snapping.
    @Test
    func kinksWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let gridSize = 0.001

        let withParam = polygon.kinks(gridSize: gridSize)
        let snapped = polygon.snappedToGrid(tolerance: gridSize)
        let manual = snapped.kinks()
        #expect(withParam.points.count == manual.points.count)
    }

    // MARK: - EPSG:3857

    // Tests kink detection on simple and self-intersecting polygons in EPSG:3857.
    @Test
    func kinks3857() async {
        let simple = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let simpleResult = simple.kinks()
        #expect(simpleResult.points.isEmpty)

        let bowtie = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let bowtieResult = bowtie.kinks()
        #expect(bowtieResult.points.isNotEmpty)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let kinks = polygon.kinks()
        #expect(kinks.coordinates.isEmpty)
    }

    // MARK: - Unkink polygon

    /// Tests that a simple convex polygon remains unchanged.
    @Test
    func simplePolygonUnkinked() async throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let result = polygon.unkinked()
        #expect(result.count == 1)
        #expect(result[0].isValid)
    }

    /// Tests that a self-intersecting (bow-tie) polygon is split into simple polygons.
    @Test
    func selfIntersectingPolygonUnkinked() async throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let result = polygon.unkinked()
        #expect(result.count >= 1)
        for p in result {
            #expect(p.isValid)
        }
    }

    /// Tests that a multi-polygon with one self-intersecting polygon is handled correctly.
    @Test
    func multiPolygonUnkinked() async throws {
        let coords1: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let coords2: [Coordinate3D] = [
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 30.0, longitude: 20.0),
            Coordinate3D(latitude: 30.0, longitude: 30.0),
            Coordinate3D(latitude: 20.0, longitude: 30.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]
        let p1 = try #require(Polygon([coords1]))
        let p2 = try #require(Polygon([coords2]))
        let multi = try #require(MultiPolygon([p1, p2]))
        let result = multi.unkinked()
        #expect(result.count >= 2)
        for p in result {
            #expect(p.isValid)
        }
    }

    /// Tests that a valid (non-self-intersecting) polygon remains unchanged.
    @Test
    func validPolygonUnchanged() async throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let result = polygon.unkinked()
        #expect(result.count >= 1)
    }

    /// Tests that a polygon with a hole (inner ring) is handled correctly.
    @Test
    func polygonWithHoleUnkinked() async throws {
        let outer: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let inner: [Coordinate3D] = [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]
        let polygon = try #require(Polygon([outer, inner]))
        let result = polygon.unkinked()
        #expect(result.count >= 1)
        for p in result {
            #expect(p.isValid)
        }
    }

}

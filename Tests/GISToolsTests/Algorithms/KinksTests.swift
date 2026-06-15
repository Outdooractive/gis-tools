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

    // Tests that a self-intersecting (bow-tie) polygon detects kinks.
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

}

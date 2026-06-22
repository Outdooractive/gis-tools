import Foundation
@testable import GISTools
import Testing

struct NearestPointTests {

    // Verifies that the nearest vertex on a line string to a reference point is correctly identified.
    @Test
    func nearestPointLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let ref = Coordinate3D(latitude: 0.0, longitude: 10.0)

        let result = try #require(ls.nearestCoordinate(from: ref))
        // (0,0) is closer to (0,10) than (10,10)
        #expect(result.coordinate == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(result.distance > 0)
    }

    // Verifies that the nearest vertex on a multi-point to a reference point is correctly identified.
    @Test
    func nearestPointMultiPoint() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let ref = Coordinate3D(latitude: 1.0, longitude: 1.0)

        let result = try #require(mp.nearestCoordinate(from: ref))
        #expect(result.coordinate == Coordinate3D(latitude: 0.0, longitude: 0.0))
    }

    // Verifies that the nearest point on a feature wrapping a line string is correctly identified.
    @Test
    func nearestPointFeature() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let feature = Feature(ls)
        let ref = Point(Coordinate3D(latitude: 0.0, longitude: 10.0))

        let result = try #require(feature.nearestPoint(from: ref))
        #expect(result.point.coordinate == Coordinate3D(latitude: 0.0, longitude: 0.0))
    }

    // Verifies that an empty line string returns nil for the nearest coordinate query.
    @Test
    func nearestPointEmpty() async throws {
        let ls = LineString()
        #expect(ls.nearestCoordinate(from: Coordinate3D(latitude: 0.0, longitude: 0.0)) == nil)
    }

    // MARK: - gridSize

    // Validates that `nearestCoordinate(from:gridSize:)` matches manual pre-snapping.
    @Test
    func nearestPointWithGridSize() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let ref = Coordinate3D(latitude: 0.0001, longitude: 10.0001)
        let gridSize = 0.001

        let withParam = try #require(ls.nearestCoordinate(from: ref, gridSize: gridSize))
        let snappedLine = ls.snappedToGrid(tolerance: gridSize)
        let snappedRef = Point(ref).snappedToGrid(tolerance: gridSize).coordinate
        let manual = try #require(snappedLine.nearestCoordinate(from: snappedRef))
        #expect(withParam.coordinate == manual.coordinate)
        #expect(withParam.distance == manual.distance)
    }

    // Validates that `nearestPoint(from:gridSize:)` on Feature matches manual pre-snapping.
    @Test
    func nearestPointFeatureWithGridSize() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let feature = Feature(ls)
        let ref = Point(Coordinate3D(latitude: 0.0001, longitude: 10.0001))
        let gridSize = 0.001

        let withParam = try #require(feature.nearestPoint(from: ref, gridSize: gridSize))
        let snappedFeature = feature.snappedToGrid(tolerance: gridSize)
        let snappedRef = ref.snappedToGrid(tolerance: gridSize)
        let manual = try #require(snappedFeature.nearestPoint(from: snappedRef))
        #expect(withParam.point.coordinate == manual.point.coordinate)
    }

    // MARK: - Projection tests

    // Verifies nearest coordinate on a line string in EPSG:3857.
    @Test
    func nearestPointLineString3857() throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
        ]))
        let ref = Coordinate3D(x: 0.0, y: 1_000.0)
        let result = try #require(ls.nearestCoordinate(from: ref))
        #expect(result.distance > 0.0)
        #expect(result.coordinate.x == 0.0)
        #expect(result.coordinate.y == 0.0)
    }

    // Verifies nearest point on a feature in EPSG:3857.
    @Test
    func nearestPointFeature3857() throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
        ]))
        let feature = Feature(ls)
        let ref = Point(Coordinate3D(x: 0.0, y: 1_000.0))
        let result = try #require(feature.nearestPoint(from: ref))
        #expect(result.point.coordinate.x == 0.0)
        #expect(result.point.coordinate.y == 0.0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let ref = Coordinate3D(latitude: 5.0, longitude: 180.0)
        let result = try #require(mp.nearestCoordinate(from: ref))
        #expect(result.distance > 0)
        #expect(result.coordinate.latitude >= 0.0 && result.coordinate.latitude <= 10.0)
    }

}

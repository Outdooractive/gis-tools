import Foundation
@testable import GISTools
import Testing

struct PointsWithinPolygonTests {

    // Tests filtering an array of coordinates to those that lie inside a polygon.
    @Test
    func coordinatesWithin() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let candidates = [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]
        let result = polygon.coordinatesWithin(candidates)
        #expect(result.count == 2)
        #expect(result.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(result.contains(Coordinate3D(latitude: 2.0, longitude: 2.0)))
        #expect(!result.contains(Coordinate3D(latitude: 15.0, longitude: 5.0)))
    }

    // Tests filtering an array of Point objects to those that lie inside a polygon.
    @Test
    func pointsWithin() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let candidates = [
            Point(Coordinate3D(latitude: 5.0, longitude: 5.0)),
            Point(Coordinate3D(latitude: 15.0, longitude: 5.0)),
        ]
        let result = polygon.pointsWithin(candidates)
        #expect(result.count == 1)
        #expect(result[0].coordinate == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

    // Tests filtering coordinates within a MultiPolygon, returning matches from both constituent polygons.
    @Test
    func pointsWithinMultiPolygon() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))
        let candidates = [
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 12.0, longitude: 12.0),
            Coordinate3D(latitude: 7.0, longitude: 7.0),
        ]
        let result = mp.coordinatesWithin(candidates)
        #expect(result.count == 2)
    }

    // Tests that an empty candidates array returns an empty result when filtering coordinates within a polygon.
    @Test
    func coordinatesWithinEmpty() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = polygon.coordinatesWithin([])
        #expect(result.isEmpty)
    }

    // MARK: - gridSize

    // Validates that `coordinatesWithin(_:gridSize:)` matches manual pre-snapping.
    @Test
    func coordinatesWithinWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let candidates = [
            Coordinate3D(latitude: 5.00005, longitude: 5.00005),
            Coordinate3D(latitude: 15.00005, longitude: 5.00005),
        ]
        let gridSize = 0.001

        let withParam = polygon.coordinatesWithin(candidates, gridSize: gridSize)
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let manual = snappedPolygon.coordinatesWithin(candidates)
        // Compare counts only — coordinatesWithin returns original (unsnapped) coordinates
        #expect(withParam.count == manual.count)
        #expect(withParam.count == 1)
    }

    // MARK: - EPSG:3857

    @Test
    func pointsWithinPolygon3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let candidates = [
            Coordinate3D(x: 50_000.0, y: 50_000.0),
            Coordinate3D(x: 200_000.0, y: 200_000.0),
        ]
        let result = polygon.coordinatesWithin(candidates)
        #expect(result.count == 1)
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
        let inside = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let outside = Point(Coordinate3D(latitude: 5.0, longitude: 165.0))
        let points = [inside, outside]
        let result = polygon.pointsWithin(points)
        #expect(result.count == 1)
        #expect(result[0].coordinate.longitude == 175.0)
    }

}

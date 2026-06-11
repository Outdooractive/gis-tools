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

}

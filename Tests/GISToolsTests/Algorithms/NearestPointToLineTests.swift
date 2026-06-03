import Foundation
@testable import GISTools
import Testing

struct NearestPointToLineTests {

    @Test
    func nearestCoordinateOutOf() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let candidates = [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]
        let result = try #require(ls.nearestCoordinate(outOf: candidates))
        // (0, 1) is closest to the line (which runs along lon=0)
        #expect(result.coordinate == Coordinate3D(latitude: 0.0, longitude: 1.0))
    }

    @Test
    func nearestPointAndDistance() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let candidates = [
            Point(Coordinate3D(latitude: 5.0, longitude: 5.0)),
            Point(Coordinate3D(latitude: 0.0, longitude: 2.0)),
        ]
        let result = try #require(ls.nearestPointAndDistance(outOf: candidates))
        #expect(result.point.coordinate == Coordinate3D(latitude: 0.0, longitude: 2.0))
    }

    @Test
    func nearestCoordinateOutOfEmpty() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        #expect(ls.nearestCoordinate(outOf: []) == nil)
    }

}

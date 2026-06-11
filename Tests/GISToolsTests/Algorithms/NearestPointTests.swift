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

}

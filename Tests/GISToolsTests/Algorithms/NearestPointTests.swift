import Foundation
@testable import GISTools
import Testing

struct NearestPointTests {

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

    @Test
    func nearestPointEmpty() async throws {
        let ls = LineString()
        #expect(ls.nearestCoordinate(from: Coordinate3D(latitude: 0.0, longitude: 0.0)) == nil)
    }

}

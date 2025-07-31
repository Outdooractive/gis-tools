@testable import GISTools
import Testing

struct PointToLineDistanceTests {

    @Test
    func pointToLineDistance() async throws {
        let coordinate = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let lineString = try #require(LineString([Coordinate3D(latitude: 1.0, longitude: 1.0), Coordinate3D(latitude: 1.0, longitude: -1.0)]))

        #expect(lineString.distanceFrom(coordinate: coordinate) == 111_195.0802335329)
    }

}

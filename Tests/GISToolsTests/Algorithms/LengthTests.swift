#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct LengthTests {

    @Test
    func length() async throws {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedLength: CLLocationDistance = 97129.22118967835

        let lineSegment = LineSegment(
            first: coordinate1,
            second: coordinate2,
            index: 0)

        #expect(abs(lineSegment.length - expectedLength) < 0.000001)
        #expect(lineSegment.index == 0)
    }

}

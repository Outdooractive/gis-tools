#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct LengthTests {

    // Tests that the haversine distance between two coordinates is calculated correctly.
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

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        #expect(lineString.length > 2_000_000.0 && lineString.length < 2_500_000.0)
    }

}

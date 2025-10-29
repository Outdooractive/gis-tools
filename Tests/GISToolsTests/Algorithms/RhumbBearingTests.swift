#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct RhumbBearingTests {

    @Test
    func rhumbBearing() async throws {
        let start = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let end = Coordinate3D(latitude: 60.0, longitude: 20.0)

        let initialBearing: CLLocationDegrees = start.rhumbBearing(to: end)
        let finalBearing: CLLocationDegrees = start.rhumbBearing(to: end, final: true)

        #expect(abs(initialBearing - 75.28) < 0.01)
        #expect(abs(finalBearing - -104.719) < 0.01)
    }

}

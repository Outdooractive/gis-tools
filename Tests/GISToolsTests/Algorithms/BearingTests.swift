#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct BearingTests {

    @Test
    func bearing() async throws {
        let start = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let end = Coordinate3D(latitude: 60.0, longitude: 20.0)

        let initialBearing: CLLocationDegrees = start.bearing(to: end)
        let finalBearing: CLLocationDegrees = start.bearing(to: end, final: true)

        #expect(abs(initialBearing - 37.75) < 0.01)
        #expect(abs(finalBearing - 120.01) < 0.01)
    }

    @Test
    func bearingToAzimuth() async throws {
        #expect(40.0.bearingToAzimuth == 40.0)
        #expect((-105.0).bearingToAzimuth == 255.0)
        #expect(410.0.bearingToAzimuth == 50.0)
        #expect((-200.0).bearingToAzimuth == 160.0)
        #expect((-395.0).bearingToAzimuth == 325.0)
    }

}

#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct BearingTests {

    // Tests initial and final bearing calculation between two coordinates.
    @Test
    func bearing() async throws {
        let start = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let end = Coordinate3D(latitude: 60.0, longitude: 20.0)

        let initialBearing: CLLocationDegrees = start.bearing(to: end)
        let finalBearing: CLLocationDegrees = start.bearing(to: end, final: true)

        #expect(abs(initialBearing - 37.75) < 0.01)
        #expect(abs(finalBearing - 120.01) < 0.01)
    }

    // Tests conversion of bearing values to azimuth (normalized to 0-360 degrees).
    @Test
    func bearingToAzimuth() async throws {
        #expect(40.0.bearingToAzimuth == 40.0)
        #expect((-105.0).bearingToAzimuth == 255.0)
        #expect(410.0.bearingToAzimuth == 50.0)
        #expect((-200.0).bearingToAzimuth == 160.0)
        #expect((-395.0).bearingToAzimuth == 325.0)
    }

    // Tests bearing calculation with .noSRID (Cartesian coordinates).
    @Test
    func bearingNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let east = Coordinate3D(x: 1.0, y: 0.0, projection: .noSRID)
        let north = Coordinate3D(x: 0.0, y: 1.0, projection: .noSRID)
        let northEast = Coordinate3D(x: 1.0, y: 1.0, projection: .noSRID)

        #expect(abs(origin.bearing(to: east) - 90.0) < 1e-10)
        #expect(abs(origin.bearing(to: north)) < 1e-10)
        #expect(abs(origin.bearing(to: northEast) - 45.0) < 1e-10)
    }

}

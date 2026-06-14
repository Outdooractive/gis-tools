#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct RhumbBearingTests {

    // Tests rhumb line bearing calculation between two coordinates for both initial and final bearings.
    @Test
    func rhumbBearing() async throws {
        let start = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let end = Coordinate3D(latitude: 60.0, longitude: 20.0)

        let initialBearing: CLLocationDegrees = start.rhumbBearing(to: end)
        let finalBearing: CLLocationDegrees = start.rhumbBearing(to: end, final: true)

        #expect(abs(initialBearing - 75.28) < 0.01)
        #expect(abs(finalBearing - -104.719) < 0.01)
    }

    // Tests rhumb bearing calculation with .noSRID (Cartesian coordinates).
    @Test
    func rhumbBearingNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let east = Coordinate3D(x: 1.0, y: 0.0, projection: .noSRID)
        let north = Coordinate3D(x: 0.0, y: 1.0, projection: .noSRID)
        let northEast = Coordinate3D(x: 1.0, y: 1.0, projection: .noSRID)

        #expect(abs(origin.rhumbBearing(to: east) - 90.0) < 1e-10)
        #expect(abs(origin.rhumbBearing(to: north)) < 1e-10)
        #expect(abs(origin.rhumbBearing(to: northEast) - 45.0) < 1e-10)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let end = Coordinate3D(latitude: 10.0, longitude: -170.0)
        let bearing: CLLocationDegrees = start.rhumbBearing(to: end)
        #expect(bearing.isFinite)
        #expect(bearing >= -180.0)
        #expect(bearing <= 180.0)
    }

}

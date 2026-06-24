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

    // Tests rhumb bearing calculation in EPSG:3857 (Web Mercator).
    @Test
    func rhumbBearing3857() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0)
        let target = Coordinate3D(x: 100_000.0, y: 100_000.0)

        #expect(abs(origin.rhumbBearing(to: target) - 45.0) < 0.01)
    }

    // Tests rhumb bearing calculation in EPSG:4978 (ECEF Cartesian).
    @Test
    func rhumbBearing4978() async throws {
        // Project known 4326 coordinates to 4978, then compute rhumb bearing.
        let origin4326 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let target4326 = Coordinate3D(latitude: 0.0, longitude: 1.0)
        let origin = origin4326.projected(to: .epsg4978)
        let target = target4326.projected(to: .epsg4978)
        #expect(abs(origin.rhumbBearing(to: target) - 90.0) < 0.01)
    }

    // Tests rhumb bearing calculation with .noSRID (Cartesian coordinates).
    @Test
    func rhumbBearingNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let east = Coordinate3D(x: 1.0, y: 0.0, projection: .noSRID)
        let north = Coordinate3D(x: 0.0, y: 1.0, projection: .noSRID)
        let northEast = Coordinate3D(x: 1.0, y: 1.0, projection: .noSRID)

        #expect(abs(origin.rhumbBearing(to: east) - 90.0) < 0.0000000001)
        #expect(abs(origin.rhumbBearing(to: north)) < 0.0000000001)
        #expect(abs(origin.rhumbBearing(to: northEast) - 45.0) < 0.0000000001)
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

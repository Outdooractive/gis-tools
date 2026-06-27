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

    // MARK: - Projections

    // Tests bearing calculation in EPSG:3857 (Web Mercator).
    @Test
    func bearing3857() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0)
        let target = Coordinate3D(x: 100_000.0, y: 100_000.0)

        let bearing: CLLocationDegrees = origin.bearing(to: target)
        #expect(abs(bearing - 45.0) < 0.01)
    }

    // Tests bearing calculation in EPSG:4978.
    @Test
    func bearing4978() async throws {
        let origin4326 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let target4326 = Coordinate3D(latitude: 0.0, longitude: 1.0)
        let origin = origin4326.projected(to: .epsg4978)
        let target = target4326.projected(to: .epsg4978)
        let bearing: CLLocationDegrees = origin.bearing(to: target)
        #expect(abs(bearing - 90.0) < 0.01)
    }

    // Tests bearing calculation with noSRID.
    @Test
    func bearingNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let east = Coordinate3D(x: 1.0, y: 0.0, projection: .noSRID)
        let north = Coordinate3D(x: 0.0, y: 1.0, projection: .noSRID)
        let northEast = Coordinate3D(x: 1.0, y: 1.0, projection: .noSRID)

        #expect(abs(origin.bearing(to: east) - 90.0) < 0.0000000001)
        #expect(abs(origin.bearing(to: north)) < 0.0000000001)
        #expect(abs(origin.bearing(to: northEast) - 45.0) < 0.0000000001)
    }

    // MARK: - Antimeridian

    // Validates bearing across the antimeridian.
    @Test
    func antimeridian() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let end = Coordinate3D(latitude: 10.0, longitude: -170.0)
        let bearing = start.bearing(to: end)
        #expect(bearing > 0.0 && bearing < 180.0)
    }

    // MARK: - Edge cases

    // Validates bearing returns a finite value for identical points.
    @Test
    func bearingIdenticalPoints() async throws {
        let point = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let bearing = point.bearing(to: point)
        #expect(bearing.isFinite)
    }

}

#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct DistanceTests {

    // Validates the haversine distance between two coordinates matches the expected value.
    @Test
    func distance() async throws {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedDistance: CLLocationDistance = 97129.22118967835

        #expect(abs(coordinate1.distance(from: coordinate2) - expectedDistance) < 0.000001)
    }

    // Validates Euclidean distance in EPSG:3857 (projected meters).
    @Test
    func distanceEPSG3857() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0)
        let point = Coordinate3D(x: 300_000.0, y: 400_000.0)
        let expected = 500_000.0 // 3-4-5 triangle

        #expect(abs(origin.distance(from: point) - expected) < 1e-6)
    }

    // Validates Euclidean distance in noSRID (Cartesian plane).
    @Test
    func distanceNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let point = Coordinate3D(x: 3.0, y: 4.0, projection: .noSRID)

        #expect(abs(origin.distance(from: point) - 5.0) < 1e-12)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: -170.0)
        let distance = coordinate1.distance(from: coordinate2)
        #expect(abs(distance - 2_226_000.0) < 10_000.0)
    }

}

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

    // MARK: - Projections

    @Test
    func distance3857() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0)
        let point = Coordinate3D(x: 300_000.0, y: 400_000.0)
        let expected = 500_000.0

        #expect(abs(origin.distance(from: point) - expected) < 0.000001)
    }

    // Validates Euclidean distance in EPSG:4978.
    @Test
    func distance4978() async throws {
        let origin = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let point = Coordinate3D(latitude: 0.0, longitude: 0.09).projected(to: .epsg4978)
        let dist = origin.distance(from: point)
        #expect(dist > 5_000.0)
        #expect(dist < 15_000.0)
    }

    // Validates Euclidean distance in noSRID.
    @Test
    func distanceNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let point = Coordinate3D(x: 3.0, y: 4.0, projection: .noSRID)

        #expect(abs(origin.distance(from: point) - 5.0) < 0.000000000001)
    }

    // MARK: - 3D distance (ECEF)

    // Validates that ECEF distance uses full 3D (X, Y, Z), not just 2D.
    @Test
    func distance49783D() async throws {
        let surface = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let above = Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 1000.0)
        let above4978 = above.projected(to: .epsg4978)
        let distance = surface.distance(from: above4978)
        #expect(abs(distance - 1000.0) < 1.0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: -170.0)
        let distance = coordinate1.distance(from: coordinate2)
        #expect(abs(distance - 2_226_000.0) < 10_000.0)
    }

    // MARK: - Edge cases

    @Test
    func distanceIdenticalPoints() async throws {
        let point = Coordinate3D(latitude: 45.0, longitude: -75.0)
        #expect(point.distance(from: point) == 0.0)
    }

}

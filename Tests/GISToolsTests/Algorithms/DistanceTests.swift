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

    // Validates Euclidean distance in EPSG:3857 projection.
    @Test
    func distance3857() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857)
        let point = Coordinate3D(x: 300_000.0, y: 400_000.0, projection: .epsg3857)
        let expected = 500_000.0

        #expect(abs(origin.distance(from: point) - expected) < 0.000001)
    }

    // Validates Euclidean distance in EPSG:4978.
    @Test
    func distance4978() async throws {
        let origin = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let point = Coordinate3D(latitude: 0.0, longitude: 0.09).projected(to: .epsg4978)
        let dist = origin.distance(from: point)
        #expect(abs(dist - 10_018.753141382776) < 0.1)
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

    // Validates distance calculation across the antimeridian.
    @Test
    func antimeridian() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: -170.0)
        let distance = coordinate1.distance(from: coordinate2)
        #expect(abs(distance - 2_223_901.604670658) < 1.0)
    }

    // MARK: - Edge cases

    // Validates distance between identical points is zero.
    @Test
    func distanceIdenticalPoints() async throws {
        let point = Coordinate3D(latitude: 45.0, longitude: -75.0)
        #expect(point.distance(from: point) == 0.0)
    }

}

// MARK: - Audit regressions

extension DistanceTests {

    @Test
    func mixedProjectionDistanceUsesReceiverProjection() {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857)
        let other = Coordinate3D(latitude: 1.0, longitude: 1.0)

        #expect(abs(origin.distance(to: other) - 157_433.53030626837) < 0.000001)
        #expect(abs(other.distance(to: origin) - 157_411.0) < 200.0)
    }

    @Test
    func planarDistanceAcrossAntimeridianIsShort() {
        let first = Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg3857)
        let second = Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg3857)

        #expect(abs(first.distance(to: second) - 2_226_389.8158654715) < 0.001)
    }

}

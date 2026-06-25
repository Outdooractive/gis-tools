@testable import GISTools
import Testing

struct MidPointTests {

    // Verifies that the midpoint between two points along the equator is equidistant from both.
    @Test
    func horizontalEquator() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: 10.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    // Verifies that the midpoint from the equator northward is equidistant from both points.
    @Test
    func verticalFromEquator() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    // Verifies that the midpoint from a northern point back to the equator is equidistant from both.
    @Test
    func verticalToEquator() async throws {
        let coordinate1 = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    // Verifies that the midpoint over a long distance is equidistant from both coordinates.
    @Test
    func longDistance() async throws {
        let coordinate1 = Coordinate3D(latitude: 21.94304553343818, longitude: 22.5)
        let coordinate2 = Coordinate3D(latitude: 46.800059446787316, longitude: 92.10937499999999)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    // MARK: - Altitude / Z

    @Test
    func midpointPreservesAltitudeAndM() async throws {
        let a = Coordinate3D(latitude: 45.0, longitude: -75.0, altitude: 500.0, m: 10.0)
        let b = Coordinate3D(latitude: 46.0, longitude: -74.0, altitude: 1000.0, m: 20.0)
        let result = a.midpoint(to: b)
        #expect(result.altitude == 750.0)
        #expect(result.m == a.m)
    }

    // MARK: - Projections

    @Test
    func midPoint3857() async throws {
        let coord1 = Coordinate3D(x: 0.0, y: 0.0)
        let coord2 = Coordinate3D(x: 100_000.0, y: 100_000.0)
        let mid = coord1.midpoint(to: coord2)
        #expect(mid.projection == .epsg3857)
    }

    // Verifies midpoint in EPSG:4978.
    @Test
    func midPoint4978() async throws {
        let coord1 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let coord2 = Coordinate3D(latitude: 10.0, longitude: 10.0).projected(to: .epsg4978)
        let mid = coord1.midpoint(to: coord2)
        #expect(mid.projection == .epsg4978)
        #expect(mid.longitude.isFinite)
        #expect(mid.latitude.isFinite)
    }

    // Verifies midpoint in noSRID.
    @Test
    func midPointNoSRID() async throws {
        let coord1 = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let coord2 = Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID)
        let mid = coord1.midpoint(to: coord2)
        #expect(mid.projection == .noSRID)
        #expect(mid.longitude == 5.0)
        #expect(mid.latitude == 5.0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 170.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: -170.0)
        let middle = coordinate1.midpoint(to: coordinate2)
        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    // MARK: - Edge cases

    @Test
    func midpointIdenticalPoints() async throws {
        let point = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let mid = point.midpoint(to: point)
        #expect(mid == point)
    }

}

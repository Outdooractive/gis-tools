@testable import GISTools
import Testing

struct CircleTests {

    // Validates that `point.circle(radius:)` generates a polygon approximating a circle within tolerance.
    @Test
    func circle() async throws {
        let point = Point(Coordinate3D(latitude: 39.984, longitude: -75.343))
        let circle = point.circle(radius: 5000.0)
        let expected = try TestData.polygon(package: "Circle", name: "CircleResult")

        let circleCoordinates = circle!.outerRing!.coordinates
        let expectedCoordinates = expected.outerRing!.coordinates

        #expect(circleCoordinates.count == expectedCoordinates.count)

        for index in 0 ..< circleCoordinates.count {
            #expect(abs(circleCoordinates[index].latitude - expectedCoordinates[index].latitude) < 0.00001)
            #expect(abs(circleCoordinates[index].longitude - expectedCoordinates[index].longitude) < 0.00001)
        }
    }

    // MARK: - Projection tests

    @Test
    func circle3857() async throws {
        let point = Point(Coordinate3D(x: 0.0, y: 0.0))
        let circle = try #require(point.circle(radius: 5000.0))
        #expect(circle.isValid)
    }

    @Test
    func circle4978() async throws {
        let point = Point(Coordinate3D(
            latitude: 0.0, longitude: 0.0).projected(to: .epsg4978))
        let circle = try #require(point.circle(radius: 5000.0))
        #expect(circle.isValid)
    }

    @Test
    func circleNoSRID() async throws {
        let point = Point(Coordinate3D(
            x: 0.0, y: 0.0, projection: .noSRID))
        let circle = try #require(point.circle(radius: 5000.0))
        #expect(circle.isValid)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 180.0))
        let circle = try #require(point.circle(radius: 100_000.0))
        #expect(circle.isValid)
    }

    // MARK: - Altitude preservation

    @Test
    func circlePreservesAltitude() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 500.0)
        let circle = try #require(center.circle(radius: 1000.0, steps: 8))
        let ring = try #require(circle.outerRing)
        #expect(ring.coordinates.allSatisfy({ $0.altitude == 500.0 }))
    }

}

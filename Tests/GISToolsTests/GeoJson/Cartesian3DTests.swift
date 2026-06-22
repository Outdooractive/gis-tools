import Foundation
@testable import GISTools
import Testing

struct Cartesian3DTests {

    private let accuracy: Double = 0.000000000001

    @Test
    func description() async throws {
        let point = Cartesian3D(x: 1.0, y: 2.0, z: 3.0)

        #expect(point.description == "Cartesian3D(x: 1.0, y: 2.0, z: 3.0)")
    }

    @Test
    func initialization() async throws {
        let point = Cartesian3D(x: 1.0, y: 2.0, z: 3.0)

        #expect(point.x == 1.0)
        #expect(point.y == 2.0)
        #expect(point.z == 3.0)
    }

    @Test
    func conversionFromCoordinate3D() async throws {
        // Equator, prime meridian → (1, 0, 0)
        let equator = Cartesian3D(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(abs(equator.x - 1.0) < accuracy)
        #expect(abs(equator.y - 0.0) < accuracy)
        #expect(abs(equator.z - 0.0) < accuracy)

        // North pole → (0, 0, 1)
        let northPole = Cartesian3D(Coordinate3D(latitude: 90.0, longitude: 0.0))
        #expect(abs(northPole.x - 0.0) < accuracy)
        #expect(abs(northPole.y - 0.0) < accuracy)
        #expect(abs(northPole.z - 1.0) < accuracy)

        // South pole → (0, 0, -1)
        let southPole = Cartesian3D(Coordinate3D(latitude: -90.0, longitude: 0.0))
        #expect(abs(southPole.x - 0.0) < accuracy)
        #expect(abs(southPole.z - (-1.0)) < accuracy)

        // Equator, 90°E → (0, 1, 0)
        let east = Cartesian3D(Coordinate3D(latitude: 0.0, longitude: 90.0))
        #expect(abs(east.x - 0.0) < accuracy)
        #expect(abs(east.y - 1.0) < accuracy)
        #expect(abs(east.z - 0.0) < accuracy)
    }

    @Test
    func conversionFromCartesian3D() async throws {
        let cartesian = Cartesian3D(x: 1.0, y: 0.0, z: 0.0)
        let coordinate = Coordinate3D(cartesian)

        #expect(abs(coordinate.latitude - 0.0) < accuracy)
        #expect(abs(coordinate.longitude - 0.0) < accuracy)
    }

    @Test
    func roundTrip() async throws {
        let original = Coordinate3D(latitude: 42.5, longitude: -73.8)
        let cartesian = Cartesian3D(original)
        let roundTripped = Coordinate3D(cartesian)

        #expect(abs(roundTripped.latitude - original.latitude) < accuracy)
        #expect(abs(roundTripped.longitude - original.longitude) < accuracy)
    }

    @Test
    func equatable() async throws {
        let a = Cartesian3D(x: 1.0, y: 2.0, z: 3.0)
        let b = Cartesian3D(x: 1.0, y: 2.0, z: 3.0)
        let c = Cartesian3D(x: 4.0, y: 5.0, z: 6.0)

        #expect(a == b)
        #expect(a != c)
    }

    @Test
    func hashable() async throws {
        let a = Cartesian3D(x: 1.0, y: 2.0, z: 3.0)
        let b = Cartesian3D(x: 1.0, y: 2.0, z: 3.0)

        let set: Set<Cartesian3D> = [a, b]
        #expect(set.count == 1)
    }

}

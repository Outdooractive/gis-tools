@testable import GISTools
import Testing

struct DestinationTests {

    @Test
    func destination1() async throws {
        let bearing = 0.0
        let distance = 100_000.0

        let coordinate = Coordinate3D(latitude: 38.10096062273525, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)

        #expect(abs(destination.latitude - 39.000281) < 0.000001)
        #expect(abs(destination.longitude - -75.0) < 0.000001)
    }

    @Test
    func destination2() async throws {
        let bearing = 180.0
        let distance = 100_000.0

        let coordinate = Coordinate3D(latitude: 39.0, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)

        #expect(abs(destination.latitude - 38.10068) < 0.000001)
        #expect(abs(destination.longitude - -75.0) < 0.000001)
    }

    @Test
    func destination3() async throws {
        let bearing = 90.0
        let distance = 100_000.0

        let coordinate = Coordinate3D(latitude: 39.0, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)

        #expect(abs(destination.latitude - 38.994285) < 0.000001)
        #expect(abs(destination.longitude - -73.842853) < 0.000001)
    }

    // TODO: This returns a completly different result than the original Turf implementation
    @Test
    func destination4() async throws {
        let bearing = 90.0
        let distance: Double = GISTool.convert(length: 5000.0, from: .miles, to: .meters)!
        #expect(abs(distance - 8_046_720.0) < 0.1)

        let coordinate = Coordinate3D(latitude: 39.0, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)
        #expect(abs(destination.latitude - 10.990466075751455) < 0.000001)
        #expect(abs(destination.longitude - 1.123702522680564) < 0.000001)
    }

}

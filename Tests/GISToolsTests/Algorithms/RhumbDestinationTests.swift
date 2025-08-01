@testable import GISTools
import Testing

struct RhumbDestinationTests {

    @Test
    func distance() async throws {
        let coordinate1 = Coordinate3D(latitude: 38, longitude: -75)
        let other1 = coordinate1.rhumbDestination(distance: 100_000.0, bearing: 0.0)
        let result1 = Coordinate3D(latitude: 38.89932036372454, longitude: -75.0)

        let coordinate2 = Coordinate3D(latitude: 39, longitude: -75)
        let other2 = coordinate2.rhumbDestination(distance: 100_000.0, bearing: 180.0)
        let result2 = Coordinate3D(latitude: 38.10067963627546, longitude: -75.0)

        let coordinate3 = Coordinate3D(latitude: 39, longitude: -75)
        let other3 = coordinate3.rhumbDestination(distance: 100_000.0, bearing: 90.0)
        let result3 = Coordinate3D(latitude: 39.0, longitude: -73.84279091917494)

        let coordinate4 = Coordinate3D(latitude: 39, longitude: -75)
        let other4 = coordinate4.rhumbDestination(distance: GISTool.convert(length: 5000, from: .miles, to: .meters)!, bearing: 90.0)
        let result4 = Coordinate3D(latitude: 39.0, longitude: 18.117374548567227)

        #expect(other1 == result1)
        #expect(other2 == result2)
        #expect(other3 == result3)
        #expect(other4 == result4)
    }

    @Test
    func meridian() async throws {
        let coordinate1 = Coordinate3D(latitude: -16.5, longitude: -539.5)
        let other1 = coordinate1.rhumbDestination(distance: 100_000.0, bearing: -90.0)
        let result1 = Coordinate3D(latitude: -16.5, longitude: -540.4379451955566)

        let coordinate2 = Coordinate3D(latitude: -16.5, longitude: -179.5)
        let other2 = coordinate2.rhumbDestination(distance: 100_000.0, bearing: -90.0)
        let result2 = Coordinate3D(latitude: -16.5, longitude: -180.43794519555667)

        let coordinate3 = Coordinate3D(latitude: -16.5, longitude: 179.5)
        let other3 = coordinate3.rhumbDestination(distance: 150_000.0, bearing: 120.0)
        let result3 = Coordinate3D(latitude: -17.174490272793403, longitude: 180.72058412338447)

        #expect(other1 == result1)
        #expect(other2 == result2)
        #expect(other3 == result3)
    }

    @Test
    func allowsZeroDistance() async throws {
        let coordinate = Coordinate3D(latitude: 38, longitude: -75)
        let other = coordinate.rhumbDestination(distance: 0.0, bearing: 45.0)

        #expect(other == coordinate)
    }

    @Test
    func allowsNegativeDistance() async throws {
        let coordinate = Coordinate3D(latitude: -54.0, longitude: 12.0)
        let other = coordinate.rhumbDestination(distance: -100_000.0, bearing: 45.0)
        let result = Coordinate3D(latitude: -54.63591552764877, longitude: 10.90974456038191)

        #expect(other == result)
    }

}

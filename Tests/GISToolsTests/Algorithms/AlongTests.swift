@testable import GISTools
import Testing

struct AlongTests {

    // Tests coordinateAlong(distance:) returns the correct coordinate at a given distance along a LineString.
    @Test
    func along() async throws {
        let lineString = try TestData.lineString(package: "Along", name: "AlongLineString1")

        let distance1: Double = GISTool.convert(length: 1.0, from: .miles, to: .meters)!
        let distance2: Double = GISTool.convert(length: 100.0, from: .miles, to: .meters)!

        let coordinate1: Coordinate3D = lineString.coordinateAlong(distance: distance1)
        let coordinate2: Coordinate3D = lineString.coordinateAlong(distance: distance2)

        #expect(coordinate1 == Coordinate3D(latitude: 38.88533832382329, longitude: -77.02418026178886))
        #expect(coordinate2 == lineString.coordinates[lineString.coordinates.count - 1])
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
        ]))
        let coordinate = lineString.coordinateAlong(distance: 500_000.0)
        #expect(coordinate.latitude >= 0.0)
        #expect(coordinate.latitude <= 10.0)
        #expect(abs(coordinate.longitude) > 150.0)
    }

}

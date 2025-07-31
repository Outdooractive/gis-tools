@testable import GISTools
import Testing

struct AlongTests {

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

}

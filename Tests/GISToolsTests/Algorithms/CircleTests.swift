@testable import GISTools
import Testing

struct CircleTests {

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

}

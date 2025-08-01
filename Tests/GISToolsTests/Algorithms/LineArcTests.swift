@testable import GISTools
import Testing

struct LineArcTests {

    @Test
    func lineArc() async throws {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        let lineArc = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let expected = try TestData.lineString(package: "LineArc", name: "LineArcResult")

        let lineArcCoordinates = lineArc.coordinates
        let expectedCoordinates = expected.coordinates

        #expect(lineArcCoordinates.count == expectedCoordinates.count)

        for index in 0 ..< lineArcCoordinates.count {
            #expect(abs(lineArcCoordinates[index].latitude - expectedCoordinates[index].latitude) < 0.00001)
            #expect(abs(lineArcCoordinates[index].longitude - expectedCoordinates[index].longitude) < 0.00001)
        }
    }

}

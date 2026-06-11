@testable import GISTools
import Testing

struct TransformRotateTests {

    // Validates rotating a point 90 degrees around the origin.
    @Test
    func rotate() async throws {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 0.0))
        let pointTransformed = point.rotated(angle: 90.0, pivot: Coordinate3D.zero)
        let pointResult = Point(Coordinate3D(latitude: 0.0, longitude: 45.0))

        #expect(pointTransformed == pointResult)
    }

}

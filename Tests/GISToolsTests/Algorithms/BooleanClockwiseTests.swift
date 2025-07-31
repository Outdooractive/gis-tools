@testable import GISTools
import Testing

struct BooleanClockwiseTests {

    @Test
    func booleanClockwise() async throws {
        let ring = Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])!

        #expect(ring.isClockwise)
        #expect(ring.isCounterClockwise == false)
    }

    @Test
    func booleanCounterClockwise() async throws {
        let ring = Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])!

        #expect(ring.isClockwise == false)
        #expect(ring.isCounterClockwise)
    }

}

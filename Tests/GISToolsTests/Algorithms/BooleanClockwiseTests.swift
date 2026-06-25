@testable import GISTools
import Testing

struct BooleanClockwiseTests {

    // Tests detection of a clockwise ring orientation.
    @Test
    func booleanClockwise() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))

        #expect(ring.isClockwise)
        #expect(ring.isCounterClockwise == false)
    }

    // Tests detection of a counter-clockwise ring orientation.
    @Test
    func booleanCounterClockwise() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))

        #expect(ring.isClockwise == false)
        #expect(ring.isCounterClockwise)
    }

    // MARK: - Projections

    // Tests clockwise detection in EPSG:3857.
    @Test
    func booleanClockwise3857() async throws {
        // Geographic CW ring projected to 3857.
        let cw4326 = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let cw = try #require(Ring(cw4326.coordinates.map { $0.projected(to: .epsg3857) }))
        #expect(cw.isClockwise)
        #expect(cw.isCounterClockwise == false)

        // Geographic CCW ring projected to 3857.
        let ccw4326 = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let ccw = try #require(Ring(ccw4326.coordinates.map { $0.projected(to: .epsg3857) }))
        #expect(ccw.isClockwise == false)
        #expect(ccw.isCounterClockwise)
    }

    // Tests clockwise detection in EPSG:4978.
    @Test
    func booleanClockwise4978() async throws {
        // Geographic CW ring projected to 4978.
        let cw4326 = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let cw = try #require(Ring(cw4326.coordinates.map { $0.projected(to: .epsg4978) }))
        #expect(cw.isClockwise)
        #expect(cw.isCounterClockwise == false)
    }

    // Tests clockwise detection in noSRID projection.
    @Test
    func booleanClockwiseNoSRID() throws {
        // Raw 2-D shoelace (no antimeridian normalisation).
        let cw = try #require(Ring([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]))
        #expect(cw.isClockwise)
        #expect(cw.isCounterClockwise == false)
    }

}

@testable import GISTools
import Testing

struct BoundingBoxPositionTests {

    @Test func center() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let center = Coordinate3D(latitude: 5.0, longitude: 5.0)

        let position = bbox.position(of: center)
        #expect(position.contains(.center))
        #expect(!position.contains(.outside))
        #expect(!position.contains(.top))
        #expect(!position.contains(.bottom))
        #expect(!position.contains(.left))
        #expect(!position.contains(.right))
    }

    @Test func topRight() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let topRight = Coordinate3D(latitude: 9.0, longitude: 9.0)

        let position = bbox.position(of: topRight)
        #expect(position.contains(.top))
        #expect(position.contains(.right))
        #expect(!position.contains(.outside))
        #expect(!position.contains(.center))
    }

    @Test func bottomLeft() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let bottomLeft = Coordinate3D(latitude: 1.0, longitude: 1.0)

        let position = bbox.position(of: bottomLeft)
        #expect(position.contains(.bottom))
        #expect(position.contains(.left))
        #expect(!position.contains(.outside))
        #expect(!position.contains(.center))
    }

    @Test func outside() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let outside = Coordinate3D(latitude: 20.0, longitude: 20.0)

        let position = bbox.position(of: outside)
        #expect(position.contains(.outside))
        #expect(position.contains(.top))
        #expect(position.contains(.right))
    }

    @Test func pointOverload() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let center = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))

        let position = bbox.position(of: center)
        #expect(position.contains(.center))
    }
    // MARK: - Projections

    @Test
    func boundingBoxPosition3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 100_000.0, y: 100_000.0))
        let center = Coordinate3D(x: 50_000.0, y: 50_000.0)
        let position = bbox.position(of: center)
        #expect(position.contains(.center))
    }

    @Test
    func boundingBoxPosition4978() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 100_000.0, y: 100_000.0, z: 0.0, projection: .epsg4978))
        let center = Coordinate3D(x: 50_000.0, y: 50_000.0, z: 0.0, projection: .epsg4978)
        let position = bbox.position(of: center)
        #expect(position.contains(.center))
    }

    @Test
    func boundingBoxPositionNoSRID() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID))
        let center = Coordinate3D(x: 50.0, y: 50.0, projection: .noSRID)
        let position = bbox.position(of: center)
        #expect(position.contains(.center))
    }

}

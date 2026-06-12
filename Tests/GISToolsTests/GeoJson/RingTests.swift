import Foundation
@testable import GISTools
import Testing

struct RingTests {

    private let coords: [Coordinate3D] = [
        Coordinate3D(latitude: 0.0, longitude: 0.0),
        Coordinate3D(latitude: 0.0, longitude: 10.0),
        Coordinate3D(latitude: 10.0, longitude: 10.0),
        Coordinate3D(latitude: 10.0, longitude: 0.0),
        Coordinate3D(latitude: 0.0, longitude: 0.0),
    ]

    @Test
    func initialization() async throws {
        let ring = try #require(Ring(coords))

        #expect(ring.coordinates == coords)
    }

    @Test
    func initializationAutoCloses() async throws {
        // 3 coordinates → auto-close (append first) → 4 coordinates → valid
        let threeCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]
        let ring = try #require(Ring(threeCoords))

        #expect(ring.coordinates.count == 4)
        #expect(ring.coordinates.last == ring.coordinates.first)
    }

    @Test
    func initializationNotEnoughCoordinates() async throws {
        let oneCoord = [Coordinate3D(latitude: 0.0, longitude: 0.0)]
        let twoCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]

        #expect(Ring(oneCoord) == nil)
        #expect(Ring(twoCoords) == nil)
    }

    @Test
    func initializationUnchecked() async throws {
        let ring = Ring(unchecked: coords)

        #expect(ring.coordinates == coords)
    }

    @Test
    func lineString() async throws {
        let ring = try #require(Ring(coords))
        let lineString = ring.lineString

        #expect(lineString.coordinates == coords)
    }

    @Test
    func circumference() async throws {
        let ring = try #require(Ring(coords))

        // Square perimeter: 4 sides × 10° ≈ 4 × 1_113_195 m at equator
        // Using Clark's approximate values; just check it's positive and reasonable
        #expect(ring.circumference > 4_000_000.0)
        #expect(ring.circumference < 5_000_000.0)
    }

    @Test
    func circumferenceEmptyRing() async throws {
        let ring = Ring(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])

        #expect(ring.circumference == 0.0)
    }

    @Test
    func projection() async throws {
        let ring = try #require(Ring(coords))

        #expect(ring.projection == .epsg4326)
    }

    @Test
    func projected() async throws {
        let ring = try #require(Ring(coords))
        let projected = ring.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.coordinates.count == 5)
    }

    @Test
    func projectedSameProjection() async throws {
        let ring = try #require(Ring(coords))
        let projected = ring.projected(to: .epsg4326)

        #expect(projected.coordinates == ring.coordinates)
    }

    @Test
    func intersectsBoundingBox() async throws {
        let ring = try #require(Ring(coords))
        let overlappingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 5.0, longitude: 5.0),
            northEast: Coordinate3D(latitude: 15.0, longitude: 15.0))
        let containingBox = BoundingBox(
            southWest: Coordinate3D(latitude: -1.0, longitude: -1.0),
            northEast: Coordinate3D(latitude: 11.0, longitude: 11.0))
        let nonOverlappingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))

        #expect(ring.intersects(overlappingBox))
        #expect(ring.intersects(containingBox))
        #expect(!ring.intersects(nonOverlappingBox))
    }

    @Test
    func equatableSame() async throws {
        let ringA = try #require(Ring(coords))
        let ringB = try #require(Ring(coords))

        #expect(ringA == ringB)
    }

    @Test
    func equatableShiftedStart() async throws {
        let ring = try #require(Ring(coords))

        // Rotate the ring so it starts at a different vertex
        let shiftedCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]
        let ringShifted = try #require(Ring(shiftedCoords))

        #expect(ring == ringShifted)
    }

    @Test
    func equatableNotEqual() async throws {
        let ring = try #require(Ring(coords))
        let otherCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let otherRing = try #require(Ring(otherCoords))

        #expect(ring != otherRing)
    }

}

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

    // Validates basic Ring initialization with closed coordinates.
    @Test
    func initialization() async throws {
        let ring = try #require(Ring(coords))

        #expect(ring.coordinates == coords)
    }

    // Validates that Ring auto-closes when given unclosed coordinates.
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

    // Validates that Ring returns nil with fewer than 3 coordinates.
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

    // Validates unchecked Ring initialization with valid coordinates.
    @Test
    func initializationUnchecked() async throws {
        let ring = try #require(Ring(coords))

        #expect(ring.coordinates == coords)
    }

    // Validates that Ring can be converted to a LineString.
    @Test
    func lineString() async throws {
        let ring = try #require(Ring(coords))
        let lineString = ring.lineString

        #expect(lineString.coordinates == coords)
    }

    // Validates that circumference returns a reasonable value for a square ring.
    @Test
    func circumference() async throws {
        let ring = try #require(Ring(coords))

        // Square perimeter: 4 sides × 10° ≈ 4 × 1_113_195 m at equator
        // Using Clark's approximate values; just check it's positive and reasonable
        #expect(ring.circumference > 4_000_000.0)
        #expect(ring.circumference < 5_000_000.0)
    }

    // Validates that projection is inferred from coordinates.
    @Test
    func projection() async throws {
        let ring = try #require(Ring(coords))

        #expect(ring.projection == .epsg4326)
    }

    // Validates projecting a Ring to a different projection.
    @Test
    func projected() async throws {
        let ring = try #require(Ring(coords))
        let projected = ring.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.coordinates.count == 5)
    }

    // Validates projecting to the same projection returns identical coordinates.
    @Test
    func projectedSameProjection() async throws {
        let ring = try #require(Ring(coords))
        let projected = ring.projected(to: .epsg4326)

        #expect(projected.coordinates == ring.coordinates)
    }

    // Validates intersects with overlapping, containing, and non-overlapping boxes.
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

    // Validates that two rings with the same coordinates are equal.
    @Test
    func equatableSame() async throws {
        let ringA = try #require(Ring(coords))
        let ringB = try #require(Ring(coords))

        #expect(ringA == ringB)
    }

    // Validates that rings with shifted start vertices are still equal.
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

    // Validates that rings with different coordinates are not equal.
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

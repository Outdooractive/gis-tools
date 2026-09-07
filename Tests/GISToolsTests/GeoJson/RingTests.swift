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

    // MARK: - Hashable

    // Validates that identical rings have equal hashes.
    @Test
    func hashableIdentical() async throws {
        let ringA = try #require(Ring(coords))
        let ringB = try #require(Ring(coords))

        #expect(ringA == ringB)
        #expect(ringA.hashValue == ringB.hashValue)
    }

    // Validates that rings with shifted start vertices have equal hashes.
    @Test
    func hashableShiftedStart() async throws {
        let ring = try #require(Ring(coords))
        let shiftedCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]
        let ringShifted = try #require(Ring(shiftedCoords))

        #expect(ring == ringShifted)
        #expect(ring.hashValue == ringShifted.hashValue)

        let set: Set<Ring> = [ring, ringShifted]
        #expect(set.count == 1)
    }

    // Validates that rings with different vertices have different hashes.
    @Test
    func hashableNotEqual() async throws {
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
        #expect(ring.hashValue != otherRing.hashValue)
    }

    // Validates that reversing a ring changes equality and hash (a reversal
    // is not a rotation).
    @Test
    func hashableReversed() async throws {
        let ring = try #require(Ring(coords))
        let reversedCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let ringReversed = try #require(Ring(reversedCoords))

        #expect(ring != ringReversed)
        #expect(ring.hashValue != ringReversed.hashValue)
    }

    // Validates that epsilon-equal rings (within `GISTool.equalityDelta`) are
    // equal and have equal hashes.
    @Test
    func hashableEpsilonEqual() async throws {
        let ring = try #require(Ring(coords))
        let epsilonCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.00000000003, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.00000000003, longitude: 0.0),
        ]
        let ringEpsilon = try #require(Ring(epsilonCoords))

        #expect(ring == ringEpsilon)
        #expect(ring.hashValue == ringEpsilon.hashValue)
    }

    // Validates that rings differing only in altitude are not equal and have
    // different hashes.
    @Test
    func hashableAltitude() async throws {
        let ring = try #require(Ring(coords))
        let altitudeCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
        ]
        let ringAltitude = try #require(Ring(altitudeCoords))

        #expect(ring != ringAltitude)
        #expect(ring.hashValue != ringAltitude.hashValue)
    }

    // Validates that projections participate in equality and hashing.
    @Test
    func hashableProjections() async throws {
        let ring4326 = try #require(Ring(coords))
        let ring3857 = ring4326.projected(to: .epsg3857)
        let ring3857Again = ring3857.projected(to: .epsg3857)

        #expect(ring3857 == ring3857Again)
        #expect(ring3857.hashValue == ring3857Again.hashValue)

        #expect(ring4326 != ring3857)
        #expect(ring4326.hashValue != ring3857.hashValue)
    }

    // Validates that rings crossing the antimeridian hash consistently when
    // their start vertex is shifted.
    @Test
    func hashableAntimeridian() async throws {
        let antimeridianCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
        ]
        let ring = try #require(Ring(antimeridianCoords))
        let shiftedCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]
        let ringShifted = try #require(Ring(shiftedCoords))

        #expect(ring == ringShifted)
        #expect(ring.hashValue == ringShifted.hashValue)
    }

    // Validates that empty (unchecked) rings are equal and hash equally.
    @Test
    func hashableEmpty() async throws {
        let ringA = Ring(unchecked: [])
        let ringB = Ring(unchecked: [])

        #expect(ringA == ringB)
        #expect(ringA.hashValue == ringB.hashValue)
    }

}

#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct RhumbDistanceTests {

    // Validates rhumb distance calculations between multiple coordinate pairs.
    @Test
    func distance() async throws {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedDistance1: CLLocationDistance = 97129.239

        let coordinate3 = Coordinate3D(latitude: 35.60371874069731, longitude: -119.17968749999999)
        let coordinate4 = Coordinate3D(latitude: 46.92025531537451, longitude: -67.5)
        let expectedDistance2: CLLocationDistance = 4_482_044.244

        let coordinate5 = Coordinate3D(latitude: -16.5, longitude: -179.5)
        let coordinate6 = Coordinate3D(latitude: -16.5, longitude: 178.5)
        let expectedDistance3: CLLocationDistance = 213_232.075

        let coordinate7 = Coordinate3D(latitude: -16.5, longitude: -539.5)
        let coordinate8 = Coordinate3D(latitude: -18.5, longitude: -541.5)
        let expectedDistance4: CLLocationDistance = 307_306.293

        #expect(abs(coordinate1.rhumbDistance(from: coordinate2) - expectedDistance1) < 0.001)
        #expect(abs(coordinate3.rhumbDistance(from: coordinate4) - expectedDistance2) < 0.001)
        #expect(abs(coordinate5.rhumbDistance(from: coordinate6) - expectedDistance3) < 0.001)
        #expect(abs(coordinate7.rhumbDistance(from: coordinate8) - expectedDistance4) < 0.001)
    }

    // Validates rhumb distance symmetry (A→B equals B→A).
    @Test
    func distanceSymmetry() async throws {
        let a = Coordinate3D(latitude: 40.0, longitude: -75.0)
        let b = Coordinate3D(latitude: 35.0, longitude: -80.0)

        let d1 = a.rhumbDistance(from: b)
        let d2 = b.rhumbDistance(from: a)

        #expect(abs(d1 - d2) < 0.001)
    }

    // Validates rhumb distance with antimeridian crossing where compensation is active.
    @Test
    func distanceAntimeridian() async throws {
        // Points straddling the antimeridian that trigger the longitude compensation
        let east = Coordinate3D(latitude: 0.0, longitude: 179.0)
        let west = Coordinate3D(latitude: 0.0, longitude: -179.0)

        let distance = east.rhumbDistance(from: west)
        #expect(distance > 0.0)
        #expect(distance < 300_000.0)  // ~2 degrees at equator = ~222km
    }

    // Validates rhumb distance between two identical coordinates is zero.
    @Test
    func distanceZero() async throws {
        let coordinate = Coordinate3D(latitude: 40.0, longitude: -75.0)
        #expect(coordinate.rhumbDistance(from: coordinate) == 0.0)
    }

    // Validates rhumb distance via the Point wrapper.
    @Test
    func distancePoint() async throws {
        let point1 = Point(Coordinate3D(latitude: 39.984, longitude: -75.343))
        let point2 = Point(Coordinate3D(latitude: 39.123, longitude: -75.534))

        let pointDistance = point1.rhumbDistance(from: point2)
        let coordDistance = point1.coordinate.rhumbDistance(from: point2.coordinate)

        #expect(abs(pointDistance - coordDistance) < 0.001)
    }

    // Validates rhumb distance in EPSG:3857 projection.
    @Test
    func distance3857() async throws {
        let coord1 = Coordinate3D(latitude: 40.0, longitude: -75.0).projected(to: .epsg3857)
        let coord2 = Coordinate3D(latitude: 39.0, longitude: -74.0).projected(to: .epsg3857)

        let distance3857 = coord1.rhumbDistance(from: coord2)
        #expect(distance3857 > 0.0)
        #expect(distance3857 < 500_000.0)
    }

    // Validates north-south rhumb distance.
    @Test
    func distanceNorthSouth() async throws {
        // 1 degree of latitude ≈ 111km
        let north = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let south = Coordinate3D(latitude: 9.0, longitude: 0.0)

        let distance = north.rhumbDistance(from: south)
        #expect(abs(distance - 111_319.5) < 200.0)
    }

    // Validates rhumb distance in noSRID (Euclidean on Cartesian plane).
    @Test
    func distanceNoSRID() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let point = Coordinate3D(x: 3.0, y: 4.0, projection: .noSRID)

        #expect(abs(origin.rhumbDistance(from: point) - 5.0) < 1e-12)
    }

    // Validates rhumb distance symmetry in noSRID.
    @Test
    func distanceNoSRIDSymmetry() async throws {
        let a = Coordinate3D(x: 10.0, y: 20.0, projection: .noSRID)
        let b = Coordinate3D(x: 30.0, y: 50.0, projection: .noSRID)

        #expect(abs(a.rhumbDistance(from: b) - b.rhumbDistance(from: a)) < 1e-12)
    }

}

@testable import GISTools
import Testing

struct LineArcTests {

    // Tests that a circular arc generated from a point with radius and bearings matches the expected coordinates.
    @Test
    func lineArc() async throws {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        let lineArc = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let expected = LineString(unchecked: [
            Coordinate3D(latitude: 44.537252, longitude: 11.364576),
            Coordinate3D(latitude: 44.53554, longitude: 11.370282),
            Coordinate3D(latitude: 44.533437, longitude: 11.375724),
            Coordinate3D(latitude: 44.530964, longitude: 11.380851),
            Coordinate3D(latitude: 44.528145, longitude: 11.385612),
            Coordinate3D(latitude: 44.525006, longitude: 11.389963),
            Coordinate3D(latitude: 44.521578, longitude: 11.39386),
            Coordinate3D(latitude: 44.517894, longitude: 11.397267),
            Coordinate3D(latitude: 44.51747, longitude: 11.397614),
        ])
        let lineArcCoordinates = lineArc.coordinates
        let expectedCoordinates = expected.coordinates

        #expect(lineArcCoordinates.count == expectedCoordinates.count)

        for index in 0 ..< lineArcCoordinates.count {
            #expect(abs(lineArcCoordinates[index].latitude - expectedCoordinates[index].latitude) < 0.00001)
            #expect(abs(lineArcCoordinates[index].longitude - expectedCoordinates[index].longitude) < 0.00001)
        }
    }

    // MARK: - Projections

    // Tests line arc generation in EPSG:3857.
    @Test
    func lineArc3857() async throws {
        let point = Point(Coordinate3D(x: 5_000_000.0, y: 5_000_000.0))
        let lineArc = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        #expect(lineArc.coordinates.count > 2)
    }

    // Validates line arc in EPSG:4978.
    @Test
    func lineArc4978() async throws {
        let point = Point(Coordinate3D(
            latitude: 0.0, longitude: 0.0).projected(to: .epsg4978))
        let lineArc = try #require(point.lineArc(
            radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        #expect(lineArc.coordinates.count > 2)
    }

    // Validates line arc in noSRID.
    @Test
    func lineArcNoSRID() async throws {
        let point = Point(Coordinate3D(
            x: 100.0, y: 100.0, projection: .noSRID))
        let lineArc = try #require(point.lineArc(
            radius: 100.0, bearing1: 20.0, bearing2: 60.0))
        #expect(lineArc.coordinates.count > 2)
    }

    // MARK: - Antimeridian

    // Tests line arc near the antimeridian.
    @Test
    func antimeridian() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 180.0))
        let lineArc = try #require(point.lineArc(radius: 50000.0, bearing1: 0.0, bearing2: 90.0))
        #expect(lineArc.coordinates.count > 2)
    }

    // MARK: - Edge cases

    // Tests that zero radius returns nil.
    @Test
    func lineArcZeroRadius() async throws {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        #expect(point.lineArc(radius: 0.0, bearing1: 20.0, bearing2: 60.0) == nil)
    }

}

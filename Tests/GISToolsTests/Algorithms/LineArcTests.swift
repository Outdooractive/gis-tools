@testable import GISTools
import Testing

struct LineArcTests {

    // Tests that a circular arc generated from a point with radius and bearings matches the expected coordinates.
    @Test
    func lineArc() async throws {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        let lineArc = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        #expect(lineArc.coordinates.count == 65)
        #expect(abs(lineArc.coordinates[0].latitude - 44.537252) < 0.00001)
        #expect(abs(lineArc.coordinates[0].longitude - 11.364576) < 0.00001)
        #expect(abs(lineArc.coordinates[64].latitude - 44.51747) < 0.00001)
        #expect(abs(lineArc.coordinates[64].longitude - 11.397614) < 0.00001)
    }

    // MARK: - Projections

    // Tests line arc generation in EPSG:3857.
    @Test
    func lineArc3857() async throws {
        let point = Point(Coordinate3D(x: 5_000_000.0, y: 5_000_000.0, projection: .epsg3857))
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

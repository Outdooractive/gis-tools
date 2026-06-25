@testable import GISTools
import Testing

struct LineArcTests {

    // Tests that a circular arc generated from a point with radius and bearings matches the expected coordinates.
    @Test
    func lineArc() async throws {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        let lineArc = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let expected = try TestData.lineString(package: "LineArc", name: "LineArcResult")

        let lineArcCoordinates = lineArc.coordinates
        let expectedCoordinates = expected.coordinates

        #expect(lineArcCoordinates.count == expectedCoordinates.count)

        for index in 0 ..< lineArcCoordinates.count {
            #expect(abs(lineArcCoordinates[index].latitude - expectedCoordinates[index].latitude) < 0.00001)
            #expect(abs(lineArcCoordinates[index].longitude - expectedCoordinates[index].longitude) < 0.00001)
        }
    }

    // MARK: - Projections

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

    @Test
    func antimeridian() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 180.0))
        let lineArc = try #require(point.lineArc(radius: 50000.0, bearing1: 0.0, bearing2: 90.0))
        #expect(lineArc.coordinates.count > 2)
    }

    // MARK: - Edge cases

    @Test
    func lineArcZeroRadius() async throws {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        #expect(point.lineArc(radius: 0.0, bearing1: 20.0, bearing2: 60.0) == nil)
    }

}

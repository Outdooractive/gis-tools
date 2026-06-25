@testable import GISTools
import Testing

struct PointToLineDistanceTests {

    // Verifies that the distance from a point to a line string is correctly computed.
    @Test
    func pointToLineDistance() async throws {
        let coordinate = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let lineString = try #require(LineString([Coordinate3D(latitude: 1.0, longitude: 1.0), Coordinate3D(latitude: 1.0, longitude: -1.0)]))

        #expect(lineString.distanceFrom(coordinate: coordinate) == 111_195.0802335329)
    }

    // MARK: - Grid size

    // Validates that `distanceFrom(coordinate:gridSize:)` matches manual pre-snapping.
    @Test
    func pointToLineDistanceWithGridSize() async throws {
        let coordinate = Coordinate3D(latitude: 0.0001, longitude: 0.0001)
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 1.0001, longitude: 1.0001),
            Coordinate3D(latitude: 1.0001, longitude: -1.0001),
        ]))
        let gridSize = 0.001

        let withParam = lineString.distanceFrom(coordinate: coordinate, gridSize: gridSize)
        let snappedLine = lineString.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coordinate).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedLine.distanceFrom(coordinate: snappedCoord)
        #expect(withParam == manual)
    }

    // MARK: - Projections

    // Verifies distance from point to line string in EPSG:3857.
    @Test
    func pointToLineDistance3857() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
        ]))
        let coordinate = Coordinate3D(x: 500.0, y: 500.0)
        let distance = lineString.distanceFrom(coordinate: coordinate)
        #expect(distance > 0.0)
        #expect(abs(distance - 500.0) < 1.0)
    }

    // Verifies distance from point to line string in EPSG:4978.
    @Test
    func pointToLineDistance4978() throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.009).projected(to: .epsg4978),
        ]))
        let coordinate = Coordinate3D(
            latitude: 0.0045, longitude: 0.0045).projected(to: .epsg4978)
        let distance = lineString.distanceFrom(coordinate: coordinate)
        #expect(distance > 0.0)
    }

    // Verifies distance from point to line string in noSRID.
    @Test
    func pointToLineDistanceNoSRID() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let coordinate = Coordinate3D(x: 50.0, y: 50.0, projection: .noSRID)
        let distance = lineString.distanceFrom(coordinate: coordinate)
        #expect(abs(distance - 50.0) < 1.0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let coordinate = Coordinate3D(latitude: 5.0, longitude: 175.0)
        let distance = lineString.distanceFrom(coordinate: coordinate)
        #expect(distance > 0)
    }

}

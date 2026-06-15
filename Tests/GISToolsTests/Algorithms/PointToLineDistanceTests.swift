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

    // MARK: - gridSize

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

@testable import GISTools
import Testing

struct LineSliceTests {

    // TODO: Test open ended slices

    // Tests that slicing a line string between two points returns the expected sub-line.
    @Test
    func slice() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 22.466878364528448, longitude: -97.88131713867188),
            Coordinate3D(latitude: 22.17596, longitude: -97.820892),
            Coordinate3D(latitude: 21.8704201873689, longitude: -97.6190185546875),
        ]))
        let start = Coordinate3D(latitude: 22.254624, longitude: -97.796173)
        let end = Coordinate3D(latitude: 22.057641, longitude: -97.727508)

        let result = try #require(LineString([
            Coordinate3D(latitude: 22.24644876941306, longitude: -97.835532855256758),
            Coordinate3D(latitude: 22.17596, longitude: -97.820892),
            Coordinate3D(latitude: 22.050645720798983, longitude: -97.738095505915268),
        ]))

        let slice = lineString.slice(start: start, end: end)
        #expect(slice == result)
    }

    // MARK: - gridSize

    // Validates that `slice(start:end:gridSize:)` matches manual pre-snapping.
    @Test
    func sliceWithGridSize() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let start = Coordinate3D(latitude: 2.0001, longitude: 2.0001)
        let end = Coordinate3D(latitude: 8.0001, longitude: 8.0001)
        let gridSize = 0.001

        let withParam = lineString.slice(start: start, end: end, gridSize: gridSize)
        let snappedLine = lineString.snappedToGrid(tolerance: gridSize)
        let snappedStart = Point(start).snappedToGrid(tolerance: gridSize).coordinate
        let snappedEnd = Point(end).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedLine.slice(start: snappedStart, end: snappedEnd)
        #expect(withParam == manual)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let start = Coordinate3D(latitude: 2.0, longitude: 172.0)
        let stop = Coordinate3D(latitude: 8.0, longitude: 177.0)
        let slice = lineString.slice(start: start, end: stop)
        #expect(slice != nil)
    }

}

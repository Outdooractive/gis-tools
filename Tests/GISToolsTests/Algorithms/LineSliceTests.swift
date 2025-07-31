@testable import GISTools
import Testing

struct LineSliceTests {

    // TODO: Test open ended slices

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

}

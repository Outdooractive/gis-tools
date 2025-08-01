@testable import GISTools
import Testing

struct TileCoverTests {

    @Test
    func tileCover1() async throws {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let tileCover = point.tileCover(atZoom: 1)
        #expect(tileCover == [MapTile(x: 1, y: 0, z: 1)])
    }

    @Test
    func tileCover2() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ]))
        let tileCover = lineString.tileCover(atZoom: 2)
        #expect(Set(tileCover) == Set([
            MapTile(x: 1, y: 1, z: 2),
            MapTile(x: 1, y: 2, z: 2),
            MapTile(x: 2, y: 1, z: 2),
            MapTile(x: 2, y: 2, z: 2),
        ]))
    }

}

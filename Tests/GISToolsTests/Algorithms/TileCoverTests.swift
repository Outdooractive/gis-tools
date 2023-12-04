@testable import GISTools
import XCTest

final class TileCoverTests: XCTestCase {

    func testTileCover1() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let tileCover = point.tileCover(atZoom: 1)
        XCTAssertEqual(tileCover, [MapTile(x: 1, y: 0, z: 1)])
    }

    func testTileCover2() {
        let lineString = LineString([
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ])!
        let tileCover = lineString.tileCover(atZoom: 2)
        XCTAssertEqual(Set(tileCover), Set([
            MapTile(x: 1, y: 1, z: 2),
            MapTile(x: 1, y: 2, z: 2),
            MapTile(x: 2, y: 1, z: 2),
            MapTile(x: 2, y: 2, z: 2),
        ]))
    }

}

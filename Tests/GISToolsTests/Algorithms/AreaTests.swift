@testable import GISTools
import XCTest

final class AreaTests: XCTestCase {

    func testArea() throws {
        let polygon1 = try XCTUnwrap(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 0.0)
        ]]))
        let polygon2 = try XCTUnwrap(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 0.0)
        ], [
            Coordinate3D(x: 25.0, y: 25.0),
            Coordinate3D(x: 75.0, y: 25.0),
            Coordinate3D(x: 75.0, y: 75.0),
            Coordinate3D(x: 25.0, y: 75.0),
            Coordinate3D(x: 25.0, y: 25.0)
        ]]))

        XCTAssertEqual(polygon1.area, 10000.0, accuracy: 0.1)
        XCTAssertEqual(polygon2.area, 7500.0, accuracy: 0.1)
    }

}

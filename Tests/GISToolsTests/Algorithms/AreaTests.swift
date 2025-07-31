@testable import GISTools
import Testing

struct AreaTests {

    @Test
    func area() async throws {
        let polygon1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 0.0)
        ]]))
        let polygon2 = try #require(Polygon([[
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

        #expect(abs(polygon1.area - 10000.0) < 0.1)
        #expect(abs(polygon2.area - 7500.0) < 0.1)
    }

}

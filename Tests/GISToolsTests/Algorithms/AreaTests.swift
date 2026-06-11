@testable import GISTools
import Testing

struct AreaTests {

    @Test
    func areaWithNoHoles() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 0.0)
        ]]))
        #expect(abs(polygon.area - 10000.0) < 0.1)
    }

    @Test
    func areaWithSingleHole() async throws {
        let polygon = try #require(Polygon([[
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
        #expect(abs(polygon.area - 7500.0) < 0.1)
    }

    // Two overlapping holes: their union area is less than the sum of individuals.
    @Test
    func areaWithOverlappingHoles() async throws {
        let outerRing = try #require(Ring([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
        ]))
        let hole1 = try #require(Ring([
            Coordinate3D(x: 20.0, y: 20.0),
            Coordinate3D(x: 60.0, y: 20.0),
            Coordinate3D(x: 60.0, y: 60.0),
            Coordinate3D(x: 20.0, y: 60.0),
        ]))
        let hole2 = try #require(Ring([
            Coordinate3D(x: 40.0, y: 40.0),
            Coordinate3D(x: 80.0, y: 40.0),
            Coordinate3D(x: 80.0, y: 80.0),
            Coordinate3D(x: 40.0, y: 80.0),
        ]))
        let polygon = try #require(Polygon([outerRing, hole1, hole2]))

        // Union of holes = (20,20)-(60,60) ∪ (40,40)-(80,80)
        // Overlap region (40,40)-(60,60) has area 400
        // Union area = 1600 + 1600 - 400 = 2800
        // Expected area = 10000 - 2800 = 7200
        #expect(abs(polygon.area - 7200.0) < 0.1)
    }

}

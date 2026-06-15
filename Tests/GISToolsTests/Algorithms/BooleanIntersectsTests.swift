@testable import GISTools
import Testing

struct BooleanIntersectsTests {

    @Test func intersectingGeometries() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let insidePoint = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let overlappingLine = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 12.0, longitude: 12.0),
        ]))

        #expect(polygon.intersects(insidePoint))
        #expect(insidePoint.intersects(polygon))
        #expect(polygon.intersects(overlappingLine))
    }

    @Test func nonIntersectingGeometries() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let outsidePoint = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))

        #expect(!polygon.intersects(outsidePoint))
        #expect(!outsidePoint.intersects(polygon))
    }

    // MARK: - gridSize

    // Validates that `intersects(_:gridSize:)` matches manual pre-snapping.
    @Test
    func intersectingGeometriesWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let point = Point(Coordinate3D(latitude: 5.00005, longitude: 5.00005))
        let gridSize = 0.001

        let withParam = polygon.intersects(point, gridSize: gridSize)
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let snappedPoint = point.snappedToGrid(tolerance: gridSize)
        let manual = snappedPolygon.intersects(snappedPoint)
        #expect(withParam == manual)
    }

    // Validates that `intersects(_:gridSize:)` returns correct result when geometries do not intersect.
    @Test
    func nonIntersectingGeometriesWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let outsidePoint = Point(Coordinate3D(latitude: 20.00005, longitude: 20.00005))
        let gridSize = 0.001

        let withParam = polygon.intersects(outsidePoint, gridSize: gridSize)
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let snappedOther = outsidePoint.snappedToGrid(tolerance: gridSize)
        let manual = snappedPolygon.intersects(snappedOther)
        #expect(withParam == manual)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
        ]))
        #expect(polygon.intersects(line))
    }

}

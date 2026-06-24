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

    // MARK: - Projection tests

    @Test
    func intersectsEPSG3857() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let pointInside = Point(Coordinate3D(x: 500.0, y: 500.0))
        let pointOutside = Point(Coordinate3D(x: 2_000.0, y: 2_000.0))
        let line = LineString(unchecked: [
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 2_000.0, y: 2_000.0),
        ])
        #expect(polygon.intersects(pointInside))
        #expect(!polygon.intersects(pointOutside))
        #expect(polygon.intersects(line))
    }

    @Test
    func intersectsEPSG4978() async throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]])
        let pointInside = Point(Coordinate3D(x: 500.0, y: 500.0, z: 0.0, projection: .epsg4978))
        #expect(polygon.intersects(pointInside))
        #expect(!polygon.intersects(Point(Coordinate3D(x: 2_000.0, y: 2_000.0, z: 0.0, projection: .epsg4978))))
    }

    @Test
    func intersectsLineStringPolygonEPSG4978() async throws {
        let poly4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = poly4326.projected(to: .epsg4978)
        let crossingLine = LineString(unchecked: [
            Coordinate3D(latitude: 0.5, longitude: -0.5).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.5, longitude: 1.5).projected(to: .epsg4978)])
        #expect(polygon.intersects(crossingLine))
        let farLine = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 5.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 6.0, longitude: 6.0).projected(to: .epsg4978)])
        #expect(!polygon.intersects(farLine))
    }

    @Test
    func intersectsNoSRID() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])
        let pointInside = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))
        #expect(polygon.intersects(pointInside))
        #expect(!polygon.intersects(Point(Coordinate3D(x: 2_000.0, y: 2_000.0, projection: .noSRID))))
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

    // MARK: - Empty / degenerate

    @Test
    func emptyGeometriesDoNotIntersect() async throws {
        let emptyPolygon = Polygon()
        let emptyMultiPoint = MultiPoint()
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(emptyPolygon.intersects(point) == false)
        #expect(point.intersects(emptyPolygon) == false)
        #expect(emptyPolygon.intersects(emptyMultiPoint) == false)
        #expect(emptyMultiPoint.intersects(emptyPolygon) == false)
    }

}

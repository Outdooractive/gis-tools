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

}

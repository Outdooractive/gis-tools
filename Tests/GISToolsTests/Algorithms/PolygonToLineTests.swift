@testable import GISTools
import Testing

struct PolygonToLineTests {

    @Test func singlePolygon() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let result = polygon.lineStrings
        #expect(result.count == 1)
        #expect(result[0].lineStrings.count == 1)
        #expect(result[0].lineStrings[0].coordinates.count == polygon.rings[0].coordinates.count)
    }

    @Test func multiPolygon() async throws {
        let polygon1 = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let polygon2 = try #require(Polygon([
            [
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 20.0, longitude: 10.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
            ],
        ]))
        let multiPolygon = try #require(MultiPolygon([polygon1, polygon2]))
        let result = multiPolygon.lineStrings
        #expect(result.count == 2)
        #expect(result[0].lineStrings[0].coordinates.count == polygon1.rings[0].coordinates.count)
        #expect(result[1].lineStrings[0].coordinates.count == polygon2.rings[0].coordinates.count)
    }

    @Test func polygonWithHole() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))
        let result = polygon.lineStrings
        #expect(result.count == 1)
        #expect(result[0].lineStrings.count == 2)
    }
    // MARK: - Projections

    @Test
    func polygonToLine3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let result = polygon.lineStrings
        #expect(result.count == 1)
    }

    @Test
    func polygonToLine4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 100_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 100_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]]))
        let result = polygon.lineStrings
        #expect(result.count == 1)
    }

    @Test
    func polygonToLineNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let result = polygon.lineStrings
        #expect(result.count == 1)
    }

}

@testable import GISTools
import Testing

struct PolygonToLineTests {

    // Verifies converting a single polygon to line strings.
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

    // Verifies converting a multi-polygon to line strings.
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

    // Verifies converting a polygon with a hole to line strings.
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

    // Verifies converting a polygon to line strings in EPSG:3857.
    @Test
    func polygonToLine3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 100_000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 100_000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let result = polygon.lineStrings
        #expect(result.count == 1)
    }

    // Verifies converting a polygon to line strings in EPSG:4978.
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

    // Verifies converting a polygon to line strings with noSRID.
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


    // MARK: - Audit coverage

    @Test
    func exactCoordinatesClosureAndRingOrder() throws {
        let outer: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let hole: [Coordinate3D] = [
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 8.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 8.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]
        let polygon = try #require(Polygon([outer, hole]))
        let result = try #require(polygon.lineStrings.first)

        #expect(result.lineStrings.count == 2)
        #expect(result.lineStrings[0].coordinates == outer)
        #expect(result.lineStrings[1].coordinates == hole)
        #expect(result.lineStrings.allSatisfy { $0.coordinates.first == $0.coordinates.last })
    }


}

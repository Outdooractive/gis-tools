import Foundation
@testable import GISTools
import Testing

struct KinksTests {

    @Test
    func lineStringNoKinks() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let result = ls.kinks()
        #expect(result.points.isEmpty)
    }

    @Test
    func polygonNoKinks() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = polygon.kinks()
        #expect(result.points.isEmpty)
    }

    @Test
    func polygonWithKinks() async throws {
        // Bow-tie polygon: self-intersecting
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = polygon.kinks()
        #expect(result.points.isNotEmpty)
    }

    @Test
    func lineStringWithKinks() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let result = ls.kinks()
        #expect(result.points.isNotEmpty)
    }

    @Test
    func multiLineStringWithKinks() async throws {
        let mls = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
            ],
        ]))
        let result = mls.kinks()
        // The second line crosses the first
        #expect(result.points.isNotEmpty)
    }

    @Test
    func featureKinks() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(polygon)
        let result = feature.kinks()
        #expect(result.points.isNotEmpty)
    }

    @Test
    func unsupportedGeometryKinks() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let result = point.kinks()
        #expect(result.points.isEmpty)
    }

}

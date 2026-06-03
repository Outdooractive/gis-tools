import Foundation
@testable import GISTools
import Testing

struct PointOnFeatureTests {

    @Test
    func pointOnPoint() async throws {
        let p = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let result = try #require(p.coordinateOnFeature)
        #expect(result == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

    @Test
    func pointOnLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let result = try #require(ls.coordinateOnFeature)
        // Centroid is (5,5) which is on the line
        #expect(result == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

    @Test
    func pointOnPolygon() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let result = try #require(polygon.pointOnFeature)
        // Should be on the surface
        #expect(result.coordinate.latitude >= 0.0)
        #expect(result.coordinate.latitude <= 10.0)
    }

    @Test
    func pointOnMultiPolygon() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))
        let result = try #require(mp.pointOnFeature)
        // Should be inside one of the polygons
        #expect(result.coordinate.latitude >= 0.0)
        #expect(result.coordinate.latitude <= 15.0)
    }

    @Test
    func pointOnFeature() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let feature = Feature(point)
        let result = try #require(feature.pointOnFeature)
        #expect(result.coordinate == Coordinate3D(latitude: 5.0, longitude: 5.0))
    }

}

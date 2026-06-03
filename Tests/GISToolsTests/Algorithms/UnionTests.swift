import Foundation
@testable import GISTools
import Testing

struct UnionTests {

    @Test
    func unionDisjointPolygons() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))

        let result = try #require(poly1.union(with: poly2))
        #expect(result is MultiPolygon)

        let mp = result as! MultiPolygon
        #expect(mp.polygons.count == 2)
    }

    @Test
    func unionContainedPolygon() async throws {
        let outer = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let inner = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 7.0),
            Coordinate3D(latitude: 7.0, longitude: 7.0),
            Coordinate3D(latitude: 7.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]]))

        let result = try #require(outer.union(with: inner))
        #expect(result is Polygon)
    }

    @Test
    func unionFeatureCollection() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))

        let fc = FeatureCollection([Feature(poly1), Feature(poly2)])
        let result = try #require(fc.union())
        #expect(result.geometry is MultiPolygon)
    }

    @Test
    func unionFeatureWrapping() async throws {
        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(poly)
        let other = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))

        let result = try #require(feature.union(with: other))
        #expect(result is MultiPolygon)
    }

    @Test
    func unionNotPolygon() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(point.union(with: poly) == nil)
    }

    @Test
    func unionEmpty() async throws {
        let fc = FeatureCollection()
        #expect(fc.union() == nil)
    }

}

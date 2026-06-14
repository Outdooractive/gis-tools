import Foundation
@testable import GISTools
import Testing

struct NearestPointOnFeatureTests {

    // Verifies that the nearest point on a line string from a reference coordinate is correctly computed.
    @Test
    func nearestOnLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let ref = Coordinate3D(latitude: 5.0, longitude: 5.0)

        let result = try #require(ls.nearestCoordinateOnFeature(from: ref))
        // Nearest point on segment is (0, 5)
        #expect(abs(result.coordinate.latitude - 0.0) < 0.001)
        #expect(abs(result.coordinate.longitude - 5.0) < 0.001)
        #expect(result.distance > 0)
    }

    // Verifies that a point inside a polygon returns itself with distance zero as the nearest coordinate.
    @Test
    func nearestOnPolygonInside() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // Point inside polygon → returns the point itself with distance 0
        let ref = Coordinate3D(latitude: 5.0, longitude: 5.0)
        let result = try #require(polygon.nearestCoordinateOnFeature(from: ref))
        #expect(result.coordinate == ref)
        #expect(result.distance == 0.0)
    }

    // Verifies that a point outside a polygon returns a point on the polygon boundary with positive distance.
    @Test
    func nearestOnPolygonOutside() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let ref = Coordinate3D(latitude: 20.0, longitude: 5.0)
        let result = try #require(polygon.nearestCoordinateOnFeature(from: ref))
        // Nearest point is on the top edge of the polygon
        #expect(abs(result.coordinate.latitude - 10.0) < 0.001)
        #expect(result.distance > 0)
    }

    // Verifies that the nearest point on a feature wrapping a line string returns a positive distance.
    @Test
    func nearestOnFeature() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let feature = Feature(ls)
        let ref = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))

        let result = try #require(feature.nearestPointOnFeature(from: ref))
        #expect(result.distance > 0)
    }

    // Verifies that the nearest coordinate on a multi-point from a reference coordinate is correctly identified.
    @Test
    func nearestOnMultiPoint() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let ref = Coordinate3D(latitude: 8.0, longitude: 0.0)
        let result = try #require(mp.nearestCoordinateOnFeature(from: ref))
        #expect(result.coordinate == Coordinate3D(latitude: 10.0, longitude: 0.0))
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let point = Coordinate3D(latitude: 5.0, longitude: 175.0)
        let result = try #require(lineString.nearestCoordinateOnFeature(from: point))
        #expect(result.distance >= 0.0)
        #expect(result.coordinate.latitude.isFinite)
        #expect(result.coordinate.longitude.isFinite)
    }

}

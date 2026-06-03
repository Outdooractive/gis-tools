import Foundation
@testable import GISTools
import Testing

struct ConvexHullTests {

    @Test
    func convexHullSquare() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5) // 4 corners + closing point
        #expect(hull.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
    }

    @Test
    func convexHullTriangle() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 4) // 3 corners + closing
    }

    @Test
    func convexHullWithInteriorPoint() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),  // interior point
        ]))

        let hull = try #require(mp.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5) // 4 corners + closing
    }

    @Test
    func convexHullCollinearTop() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 10.0),
            Coordinate3D(latitude: 7.0, longitude: 10.0),
        ]))

        let hull = try #require(mp.convexHull())
        // Should have 4 points: bottom-left, bottom-right, top-right, top-left
        #expect(hull.outerRing?.coordinates.count == 5)
    }

    @Test
    func convexHullInsufficientPoints() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(mp.convexHull() == nil)
    }

    @Test
    func convexHullLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))

        let hull = try #require(ls.convexHull())
        #expect(hull.outerRing?.coordinates.count == 5)
    }

    @Test
    func convexHullFeature() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let feature = Feature(mp)
        let hull = try #require(feature.convexHull())
        #expect(hull.outerRing?.coordinates.count == 4)
    }

}

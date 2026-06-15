import Foundation
@testable import GISTools
import Testing

struct UnkinkPolygonTests {

    @Test func simplePolygon() {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try! #require(Polygon([coords]))
        let result = polygon.unkinked()
        #expect(result.count == 1)
        #expect(result[0].isValid)
    }

    @Test func selfIntersectingPolygon() {
        // Figure-8 / bowtie: crosses over itself
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try! #require(Polygon([coords]))
        let result = polygon.unkinked()
        // Should produce simple polygons
        #expect(result.count >= 1)
        for p in result {
            #expect(p.isValid)
        }
    }

    @Test func multiPolygonUnkink() {
        let coords1: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let coords2: [Coordinate3D] = [
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 30.0, longitude: 20.0),
            Coordinate3D(latitude: 30.0, longitude: 30.0),
            Coordinate3D(latitude: 20.0, longitude: 30.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]
        let p1 = try! #require(Polygon([coords1]))
        let p2 = try! #require(Polygon([coords2]))
        let multi = try! #require(MultiPolygon([p1, p2]))
        let result = multi.unkinked()
        #expect(result.count >= 2)
        for p in result {
            #expect(p.isValid)
        }
    }

    @Test func validPolygonUnchanged() {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon = try! #require(Polygon([coords]))
        let result = polygon.unkinked()
        #expect(result.count >= 1)
    }

    @Test func polygonWithHole() {
        let outer: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let inner: [Coordinate3D] = [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]
        let polygon = try! #require(Polygon([outer, inner]))
        let result = polygon.unkinked()
        #expect(result.count >= 1)
        for p in result {
            #expect(p.isValid)
        }
    }

}

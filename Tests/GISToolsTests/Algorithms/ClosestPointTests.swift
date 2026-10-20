import Foundation
@testable import GISTools
import Testing

struct ClosestPointTests {

    private func square(projection: Projection = .epsg4326) throws -> Polygon {
        let coordinates: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0, projection: projection),
            Coordinate3D(x: 10.0, y: 0.0, projection: projection),
            Coordinate3D(x: 10.0, y: 10.0, projection: projection),
            Coordinate3D(x: 0.0, y: 10.0, projection: projection),
            Coordinate3D(x: 0.0, y: 0.0, projection: projection),
        ]]
        return try #require(Polygon(unchecked: coordinates, calculateBoundingBox: true))
    }

    // The closest point on a polygon to an outside point is on its edge.
    @Test
    func polygonToPoint() throws {
        let result = try #require(try square().closestPoint(
            to: Point(Coordinate3D(latitude: 5.0, longitude: 20.0))))

        #expect(result.coordinate == Coordinate3D(latitude: 5.0, longitude: 10.0))
        #expect(try square().covers(result))
    }

    // A point inside the polygon is its own closest point.
    @Test
    func polygonContainingPoint() throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let result = try #require(try square().closestPoint(to: point))

        #expect(result == point)
    }

    // The closest point on a point receiver is the receiver itself.
    @Test
    func pointToPolygon() throws {
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 5.0))
        let result = try #require(point.closestPoint(to: try square()))

        #expect(result == point)
    }

    // The closest point on a line to an off-line point is the perpendicular
    // projection.
    @Test
    func lineToPoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let result = try #require(line.closestPoint(
            to: Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))

        #expect(result.coordinate == Coordinate3D(latitude: 0.0, longitude: 5.0))
    }

    // Intersecting geometries return an intersection point.
    @Test
    func intersectingLines() throws {
        let horizontal = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let vertical = try #require(LineString([
            Coordinate3D(latitude: -10.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
        ]))
        let result = try #require(horizontal.closestPoint(to: vertical))

        #expect(result.coordinate == Coordinate3D(latitude: 0.0, longitude: 5.0))
    }

    // The result is in the receiver's projection.
    @Test
    func projection3857() throws {
        let polygon = try square(projection: .epsg3857)
        let point = Point(Coordinate3D(x: 20.0, y: 5.0, projection: .epsg3857))
        let result = try #require(polygon.closestPoint(to: point))

        #expect(result.projection == .epsg3857)
        #expect(result.coordinate == Coordinate3D(x: 10.0, y: 5.0, projection: .epsg3857))
    }

    // The result is in the receiver's projection for EPSG:4978.
    @Test
    func projection4978() throws {
        let polygon = try square().projected(to: .epsg4978)
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 20.0).projected(to: .epsg4978))
        let result = try #require(polygon.closestPoint(to: point))

        #expect(result.projection == .epsg4978)
        #expect(polygon.covers(result))
    }

    // The result is in the receiver's projection for noSRID.
    @Test
    func projectionNoSRID() throws {
        let polygon = try square(projection: .noSRID)
        let point = Point(Coordinate3D(x: 20.0, y: 5.0, projection: .noSRID))
        let result = try #require(polygon.closestPoint(to: point))

        #expect(result.projection == .noSRID)
    }

    // Unlocated geometries have no coordinates and therefore no closest point.
    @Test
    func unlocatedGeometries() throws {
        let polygon = try square()
        let unlocated = Feature(properties: ["name": "none"])

        #expect(Feature(polygon).closestPoint(to: unlocated) == nil)
        #expect(unlocated.closestPoint(to: polygon) == nil)
    }

    // Features and feature collections delegate to their geometries.
    @Test
    func featuresAndCollections() throws {
        let polygon = try square()
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 20.0))
        let feature = Feature(polygon)

        #expect(feature.closestPoint(to: point) != nil)
        #expect(FeatureCollection([feature]).closestPoint(to: point) != nil)
    }

}

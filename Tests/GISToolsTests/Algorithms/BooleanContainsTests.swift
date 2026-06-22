import Foundation
@testable import GISTools
import Testing

struct BooleanContainsTests {

    // MARK: - Point in Point

    @Test
    func pointContainsPoint() async throws {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(point1.contains(point2))
    }

    @Test
    func pointDoesNotContainDifferentPoint() async throws {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 6.0, longitude: 5.0))
        #expect(point1.contains(point2) == false)
    }

    @Test
    func pointDoesNotContainOtherTypes() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let multiPoint = MultiPoint([Coordinate3D(latitude: 5.0, longitude: 5.0)])!
        let line = LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0)])!
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        #expect(point.contains(multiPoint) == false)
        #expect(point.contains(line) == false)
        #expect(point.contains(polygon) == false)
    }

    // MARK: - MultiPoint contains

    @Test
    func multiPointContainsPoint() async throws {
        let multiPoint = MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ])!
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(multiPoint.contains(point))
    }

    @Test
    func multiPointDoesNotContainPoint() async throws {
        let multiPoint = MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ])!
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(multiPoint.contains(point) == false)
    }

    @Test
    func multiPointContainsMultiPoint() async throws {
        let container = MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ])!
        let contained = MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ])!
        #expect(container.contains(contained))
    }

    @Test
    func multiPointDoesNotContainMultiPoint() async throws {
        let container = MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ])!
        let contained = MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])!
        #expect(container.contains(contained) == false)
    }

    // MARK: - LineString contains

    @Test
    func lineStringContainsPoint() async throws {
        let line = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(line.contains(point))
    }

    @Test
    func lineStringDoesNotContainPoint() async throws {
        let line = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 6.0))
        #expect(line.contains(point) == false)
    }

    @Test
    func lineStringContainsLineString() async throws {
        let outer = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let inner = LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])!
        #expect(outer.contains(inner))
    }

    // MARK: - MultiLineString contains

    @Test
    func multiLineStringContainsPoint() async throws {
        let line1 = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])!
        let line2 = LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ])!
        let multiLine = MultiLineString([line1, line2])!
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(multiLine.contains(point))
    }

    @Test
    func multiLineStringDoesNotContainPoint() async throws {
        let line1 = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])!
        let line2 = LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ])!
        let multiLine = MultiLineString([line1, line2])!
        let point = Point(Coordinate3D(latitude: 7.0, longitude: 7.0))
        #expect(multiLine.contains(point) == false)
    }

    // MARK: - Polygon contains

    @Test
    func polygonContainsPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(polygon.contains(point))
    }

    @Test
    func polygonDoesNotContainPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(polygon.contains(point) == false)
    }

    @Test
    func polygonContainsPointOnBoundary() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 5.0))
        #expect(polygon.contains(point))
    }

    @Test
    func polygonContainsMultiPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let multiPoint = MultiPoint([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ])!
        #expect(polygon.contains(multiPoint))
    }

    @Test
    func polygonContainsLineString() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ])!
        #expect(polygon.contains(line))
    }

    @Test
    func polygonDoesNotContainLineStringOutside() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
        ])!
        #expect(polygon.contains(line) == false)
    }

    @Test
    func polygonContainsPolygon() async throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        #expect(outer.contains(inner))
    }

    @Test
    func polygonDoesNotContainPolygonTouching() async throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 20.0, longitude: 10.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 0.0)]]))
        #expect(outer.contains(inner) == false)
    }

    @Test
    func polygonWithHoleContainsPointInHole() async throws {
        // Point is inside the outer ring but inside the hole -> not contained
        let polygon = try #require(Polygon([
            [Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)],
            [Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)],
        ]))
        let pointInHole = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(polygon.contains(pointInHole) == false)
    }

    // MARK: - MultiPolygon contains

    @Test
    func multiPolygonContainsPoint() async throws {
        let polygon1 = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 5.0), Coordinate3D(latitude: 5.0, longitude: 5.0), Coordinate3D(latitude: 5.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let polygon2 = try #require(Polygon([[Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0)]]))
        let multiPolygon = MultiPolygon([polygon1, polygon2])!
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(multiPolygon.contains(point))
    }

    @Test
    func multiPolygonContainsMultiPolygon() async throws {
        let outer1 = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let outer2 = try #require(Polygon([[Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 30.0), Coordinate3D(latitude: 30.0, longitude: 30.0), Coordinate3D(latitude: 30.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0)]]))
        let container = MultiPolygon([outer1, outer2])!

        let inner1 = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        let inner2 = try #require(Polygon([[Coordinate3D(latitude: 22.0, longitude: 22.0), Coordinate3D(latitude: 22.0, longitude: 28.0), Coordinate3D(latitude: 28.0, longitude: 28.0), Coordinate3D(latitude: 28.0, longitude: 22.0), Coordinate3D(latitude: 22.0, longitude: 22.0)]]))
        let contained = MultiPolygon([inner1, inner2])!
        #expect(container.contains(contained))
    }

    // MARK: - isWithin

    @Test
    func pointIsWithinPolygon() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(point.isWithin(polygon))
    }

    @Test
    func pointIsNotWithinPolygon() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(point.isWithin(polygon) == false)
    }

    @Test
    func polygonIsWithinPolygon() async throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        #expect(inner.isWithin(outer))
    }

    // MARK: - Feature and FeatureCollection

    @Test
    func featureContainsPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let feature = Feature(polygon)
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(feature.contains(point))
    }

    @Test
    func featureCollectionContainsPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let featureCollection = FeatureCollection([Feature(polygon)])
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(featureCollection.contains(point))
    }

    @Test
    func featureCollectionDoesNotContainPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let featureCollection = FeatureCollection([Feature(polygon)])
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(featureCollection.contains(point) == false)
    }

    // MARK: - Projection tests

    @Test
    func polygonContainsPoint3857() throws {
        let polygon = try #require(Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let inside = Point(Coordinate3D(x: 500.0, y: 500.0))
        let outside = Point(Coordinate3D(x: 2_000.0, y: 2_000.0))
        #expect(polygon.contains(inside))
        #expect(polygon.contains(outside) == false)
    }

    // MARK: - Bounding box fast-fail

    @Test
    func boundingBoxFastFail() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        // Far away — bounding box check should short-circuit
        let farPolygon = try #require(Polygon([[Coordinate3D(latitude: 100.0, longitude: 100.0), Coordinate3D(latitude: 100.0, longitude: 110.0), Coordinate3D(latitude: 110.0, longitude: 110.0), Coordinate3D(latitude: 110.0, longitude: 100.0), Coordinate3D(latitude: 100.0, longitude: 100.0)]]))
        #expect(polygon.contains(farPolygon) == false)
    }

    // MARK: - Antimeridian

    @Test
    func polygonNearAntimeridianContainsPoint() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 160.0)]]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 165.0))
        #expect(polygon.contains(pointInside))
    }

    @Test
    func polygonNearAntimeridianDoesNotContainFarSide() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 160.0)]]))
        // Point at -165° is on the other side of the antimeridian, well outside the polygon
        let pointOutside = Point(Coordinate3D(latitude: 5.0, longitude: -165.0))
        #expect(polygon.contains(pointOutside) == false)
    }

    @Test
    func pointNearAntimeridianIsWithinPolygon() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 160.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 165.0))
        #expect(point.isWithin(polygon))
    }

    @Test
    func multiPolygonSpanningAntimeridianContainsPoint() async throws {
        let westPolygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 180.0), Coordinate3D(latitude: 10.0, longitude: 180.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 170.0)]]))
        let eastPolygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: -180.0), Coordinate3D(latitude: 0.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: -180.0), Coordinate3D(latitude: 0.0, longitude: -180.0)]]))
        let multiPolygon = MultiPolygon([westPolygon, eastPolygon])!
        let pointWest = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointEast = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(multiPolygon.contains(pointWest))
        #expect(multiPolygon.contains(pointEast))
    }

    @Test
    func lineStringNearAntimeridianContainsPoint() async throws {
        let line = LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 180.0),
        ])!
        let pointOnLine = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOffLine = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(line.contains(pointOnLine))
        #expect(line.contains(pointOffLine) == false)
    }

}

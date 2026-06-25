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
        let multiPoint = try #require(MultiPoint([Coordinate3D(latitude: 5.0, longitude: 5.0)]))
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0)]))
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        #expect(point.contains(multiPoint) == false)
        #expect(point.contains(line) == false)
        #expect(point.contains(polygon) == false)
    }

    // MARK: - MultiPoint contains

    @Test
    func multiPointContainsPoint() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(multiPoint.contains(point))
    }

    @Test
    func multiPointDoesNotContainPoint() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(multiPoint.contains(point) == false)
    }

    @Test
    func multiPointContainsMultiPoint() async throws {
        let container = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        let contained = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        #expect(container.contains(contained))
    }

    @Test
    func multiPointDoesNotContainMultiPoint() async throws {
        let container = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let contained = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        #expect(container.contains(contained) == false)
    }

    // MARK: - LineString contains

    @Test
    func lineStringContainsPoint() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(line.contains(point))
    }

    @Test
    func lineStringDoesNotContainPoint() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 6.0))
        #expect(line.contains(point) == false)
    }

    @Test
    func lineStringContainsLineString() async throws {
        let outer = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let inner = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        #expect(outer.contains(inner))
    }

    // MARK: - MultiLineString contains

    @Test
    func multiLineStringContainsPoint() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let multiLine = try #require(MultiLineString([line1, line2]))
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(multiLine.contains(point))
    }

    @Test
    func multiLineStringDoesNotContainPoint() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let multiLine = try #require(MultiLineString([line1, line2]))
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
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ]))
        #expect(polygon.contains(multiPoint))
    }

    @Test
    func polygonContainsLineString() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ]))
        #expect(polygon.contains(line))
    }

    @Test
    func polygonDoesNotContainLineStringOutside() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
        ]))
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
        let multiPolygon = try #require(MultiPolygon([polygon1, polygon2]))
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(multiPolygon.contains(point))
    }

    @Test
    func multiPolygonContainsMultiPolygon() async throws {
        let outer1 = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let outer2 = try #require(Polygon([[Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 30.0), Coordinate3D(latitude: 30.0, longitude: 30.0), Coordinate3D(latitude: 30.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0)]]))
        let container = try #require(MultiPolygon([outer1, outer2]))

        let inner1 = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        let inner2 = try #require(Polygon([[Coordinate3D(latitude: 22.0, longitude: 22.0), Coordinate3D(latitude: 22.0, longitude: 28.0), Coordinate3D(latitude: 28.0, longitude: 28.0), Coordinate3D(latitude: 28.0, longitude: 22.0), Coordinate3D(latitude: 22.0, longitude: 22.0)]]))
        let contained = try #require(MultiPolygon([inner1, inner2]))
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

    // MARK: - Projections

    @Test
    func containsEPSG3857() throws {
        let polygon = try #require(Polygon([[
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
        #expect(inside.isWithin(polygon))
    }

    @Test
    func containsEPSG4978() async throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = polygon4326.projected(to: .epsg4978)
        let inside = Point(Coordinate3D(latitude: 0.5, longitude: 0.5)).projected(to: .epsg4978)
        let outside = Point(Coordinate3D(latitude: 5.0, longitude: 5.0)).projected(to: .epsg4978)
        #expect(polygon.contains(inside))
        #expect(polygon.contains(outside) == false)
    }

    @Test
    func containsNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let inside = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))
        let outside = Point(Coordinate3D(x: 2_000.0, y: 2_000.0, projection: .noSRID))
        #expect(polygon.contains(inside))
        #expect(polygon.contains(outside) == false)
    }

    // MARK: - Projections for non-Polygon types

    @Test
    func multiPointContainsPointEPSG3857() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0)]))
        #expect(mp.contains(Point(Coordinate3D(x: 0.0, y: 0.0))))
        #expect(mp.contains(Point(Coordinate3D(x: 1_000.0, y: 1_000.0))))
        #expect(mp.contains(Point(Coordinate3D(x: 500.0, y: 500.0))) == false)
    }

    @Test
    func multiPointContainsPointEPSG4978() async throws {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let b = Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978)
        let mp = try #require(MultiPoint([a, b]))
        #expect(mp.contains(Point(a)))
        #expect(mp.contains(Point(b)))
        #expect(mp.contains(Point(Coordinate3D(latitude: 5.0, longitude: 5.0).projected(to: .epsg4978))) == false)
    }

    @Test
    func multiPointContainsPointNoSRID() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID)]))
        #expect(mp.contains(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID))))
        #expect(mp.contains(Point(Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID))))
        #expect(mp.contains(Point(Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID))) == false)
    }

    @Test
    func lineStringContainsPointEPSG3857() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0)]))
        #expect(line.contains(Point(Coordinate3D(x: 500.0, y: 500.0))))
        #expect(line.contains(Point(Coordinate3D(x: 600.0, y: 500.0))) == false)
    }

    @Test
    func lineStringContainsPointEPSG4978() async throws {
        // Short ECEF segment at Z=0 so 2D XY check is exact.
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 100.0, z: 0.0, projection: .epsg4978)]))
        #expect(line.contains(Point(Coordinate3D(x: 50.0, y: 50.0, z: 0.0, projection: .epsg4978))))
        #expect(line.contains(Point(Coordinate3D(x: 50.0, y: 60.0, z: 0.0, projection: .epsg4978))) == false)
    }

    @Test
    func lineStringContainsPointNoSRID() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID)]))
        #expect(line.contains(Point(Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID))))
        #expect(line.contains(Point(Coordinate3D(x: 5.0, y: 6.0, projection: .noSRID))) == false)
    }

    @Test
    func multiLineStringContainsPointEPSG3857() throws {
        let ml1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500.0, y: 500.0)
        ]))
        let ml2 = try #require(LineString([
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_500.0, y: 500.0)
        ]))
        let ml = try #require(MultiLineString([
            ml1,
            ml2,
        ]))
        #expect(ml.contains(Point(Coordinate3D(x: 250.0, y: 250.0))))
        #expect(ml.contains(Point(Coordinate3D(x: 1_250.0, y: 250.0))))
        #expect(ml.contains(Point(Coordinate3D(x: 750.0, y: 750.0))) == false)
    }

    @Test
    func multiLineStringContainsPointEPSG4978() async throws {
        let ml1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 100.0, z: 0.0, projection: .epsg4978)
        ]))
        let ml2 = try #require(LineString([
            Coordinate3D(x: 200.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 300.0, y: 100.0, z: 0.0, projection: .epsg4978)
        ]))
        let ml = try #require(MultiLineString([
            ml1,
            ml2,
        ]))
        #expect(ml.contains(Point(Coordinate3D(x: 50.0, y: 50.0, z: 0.0, projection: .epsg4978))))
        #expect(ml.contains(Point(Coordinate3D(x: 250.0, y: 50.0, z: 0.0, projection: .epsg4978))))
        #expect(ml.contains(Point(Coordinate3D(x: 150.0, y: 150.0, z: 0.0, projection: .epsg4978))) == false)
    }

    @Test
    func multiLineStringContainsPointNoSRID() throws {
        let ml1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID)
        ]))
        let ml2 = try #require(LineString([
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 15.0, y: 5.0, projection: .noSRID)
        ]))
        let ml = try #require(MultiLineString([
            ml1,
            ml2,
        ]))
        #expect(ml.contains(Point(Coordinate3D(x: 2.5, y: 2.5, projection: .noSRID))))
        #expect(ml.contains(Point(Coordinate3D(x: 12.5, y: 2.5, projection: .noSRID))))
        #expect(ml.contains(Point(Coordinate3D(x: 7.5, y: 7.5, projection: .noSRID))) == false)
    }

    // MARK: - Polygon × MultiLineString / MultiPolygon

    @Test
    func polygonContainsMultiLineString() async throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let insideLine = try #require(LineString([Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 5.0, longitude: 5.0)]))
        let outsideLine = try #require(LineString([Coordinate3D(latitude: 5.0, longitude: 5.0), Coordinate3D(latitude: 15.0, longitude: 15.0)]))
        let mlInside = try #require(MultiLineString([insideLine]))
        let mlOutside = try #require(MultiLineString([outsideLine]))
        #expect(polygon.contains(mlInside))
        #expect(polygon.contains(mlOutside) == false)
    }

    @Test
    func polygonContainsMultiPolygon() async throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner1 = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        let inner2 = try #require(Polygon([[Coordinate3D(latitude: 12.0, longitude: 12.0), Coordinate3D(latitude: 12.0, longitude: 18.0), Coordinate3D(latitude: 18.0, longitude: 18.0), Coordinate3D(latitude: 18.0, longitude: 12.0), Coordinate3D(latitude: 12.0, longitude: 12.0)]]))
        let mp = try #require(MultiPolygon([inner1, inner2]))
        #expect(outer.contains(mp))
    }

    // MARK: - Feature / FeatureCollection with non-4326 projections

    @Test
    func featureContainsPointEPSG3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        #expect(Feature(polygon).contains(Point(Coordinate3D(x: 500.0, y: 500.0))))
    }

    @Test
    func featureContainsPointEPSG4978() async throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(Feature(polygon4326.projected(to: .epsg4978)).contains(Point(Coordinate3D(latitude: 0.5, longitude: 0.5).projected(to: .epsg4978))))
    }

    @Test
    func featureContainsPointNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        #expect(Feature(polygon).contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))))
    }

    @Test
    func featureCollectionContainsPointEPSG3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        #expect(FeatureCollection([Feature(polygon)]).contains(Point(Coordinate3D(x: 500.0, y: 500.0))))
    }

    @Test
    func featureCollectionContainsPointEPSG4978() async throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(FeatureCollection([Feature(polygon4326.projected(to: .epsg4978))]).contains(Point(Coordinate3D(latitude: 0.5, longitude: 0.5).projected(to: .epsg4978))))
    }

    @Test
    func featureCollectionContainsPointNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        #expect(FeatureCollection([Feature(polygon)]).contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))))
    }

    // MARK: - GeometryCollection contains

    @Test
    func geometryCollectionContainsPoint() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let gc = GeometryCollection([polygon])
        #expect(gc.contains(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))
        #expect(gc.contains(Point(Coordinate3D(latitude: 20.0, longitude: 20.0))) == false)
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
        let multiPolygon = try #require(MultiPolygon([westPolygon, eastPolygon]))
        let pointWest = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointEast = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(multiPolygon.contains(pointWest))
        #expect(multiPolygon.contains(pointEast))
    }

    @Test
    func lineStringNearAntimeridianContainsPoint() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 180.0),
        ]))
        let pointOnLine = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOffLine = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(line.contains(pointOnLine))
        #expect(line.contains(pointOffLine) == false)
    }

    // MARK: - Empty / degenerate

    @Test
    func emptyPolygonDoesNotContain() async throws {
        let emptyPolygon = Polygon()
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(emptyPolygon.contains(point) == false)
    }

    @Test
    func singlePointLineStringContainsItsPoint() throws {
        let degenerateLine = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 10.0)
        ])
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 10.0))
        #expect(degenerateLine.contains(point) == false)
    }

    @Test
    func emptyMultiPointContainsNothing() {
        let emptyMultiPoint = MultiPoint()
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 2.0))
        #expect(emptyMultiPoint.contains(point) == false)
    }

}

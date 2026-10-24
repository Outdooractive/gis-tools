import Foundation
@testable import GISTools
import Testing

struct BooleanContainsTests {

    // MARK: - Point in Point

    /// Point contains identical point.
    @Test
    func pointContainsPoint() {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(point1.contains(point2))
    }

    /// Point does not contain a different point.
    @Test
    func pointDoesNotContainDifferentPoint() {
        let point1 = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let point2 = Point(Coordinate3D(latitude: 6.0, longitude: 5.0))
        #expect(point1.contains(point2) == false)
    }

    /// A point does not contain geometries with points outside it. An equal
    /// MultiPoint is contained, since OGC contains is reflexive for equal
    /// (point) geometries.
    @Test
    func pointContainsOtherTypes() throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let multiPoint = try #require(MultiPoint([Coordinate3D(latitude: 5.0, longitude: 5.0)]))
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0)]))
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        #expect(point.contains(multiPoint))
        #expect(point.contains(line) == false)
        #expect(point.contains(polygon) == false)
    }

    // MARK: - MultiPoint contains

    /// MultiPoint contains a member point.
    @Test
    func multiPointContainsPoint() throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(multiPoint.contains(point))
    }

    /// MultiPoint does not contain a non-member point.
    @Test
    func multiPointDoesNotContainPoint() throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(multiPoint.contains(point) == false)
    }

    /// MultiPoint contains a subset MultiPoint.
    @Test
    func multiPointContainsMultiPoint() throws {
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

    /// MultiPoint does not contain a non-subset MultiPoint.
    @Test
    func multiPointDoesNotContainMultiPoint() throws {
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

    /// LineString contains a point on it.
    @Test
    func lineStringContainsPoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(line.contains(point))
    }

    /// LineString does not contain an off-line point.
    @Test
    func lineStringDoesNotContainPoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 6.0))
        #expect(line.contains(point) == false)
    }

    /// LineString contains a sub-line.
    @Test
    func lineStringContainsLineString() throws {
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

    /// LineString does not contain its boundary endpoints (OGC contains), but
    /// covers them.
    @Test
    func lineStringContainsEndpoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let start = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let middle = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))

        #expect(line.contains(start) == false)
        #expect(line.covers(start))
        #expect(line.contains(middle))
    }

    // MARK: - MultiLineString contains

    /// MultiLineString contains a point on one segment.
    @Test
    func multiLineStringContainsPoint() throws {
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

    /// MultiLineString does not contain a point between segments.
    @Test
    func multiLineStringDoesNotContainPoint() throws {
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

    /// Polygon contains an interior point.
    @Test
    func polygonContainsPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(polygon.contains(point))
    }

    /// Polygon does not contain an exterior point.
    @Test
    func polygonDoesNotContainPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(polygon.contains(point) == false)
    }

    /// A polygon does not contain a boundary point (OGC contains), but covers it.
    @Test
    func polygonContainsPointOnBoundary() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 5.0))

        #expect(polygon.contains(point) == false)
        #expect(polygon.covers(point))
        #expect(polygon.locate(point) == .boundary)
    }

    /// Polygon contains a MultiPoint of interior points.
    @Test
    func polygonContainsMultiPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ]))
        #expect(polygon.contains(multiPoint))
    }

    /// Polygon contains a fully interior LineString.
    @Test
    func polygonContainsLineString() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ]))
        #expect(polygon.contains(line))
    }

    /// Polygon does not contain a LineString that exits it.
    @Test
    func polygonDoesNotContainLineStringOutside() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
        ]))
        #expect(polygon.contains(line) == false)
    }

    /// Polygon contains a smaller interior polygon.
    @Test
    func polygonContainsPolygon() throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        #expect(outer.contains(inner))
    }

    /// Polygon does not contain a polygon that only touches it.
    @Test
    func polygonDoesNotContainPolygonTouching() throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 20.0, longitude: 10.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 10.0, longitude: 0.0)]]))
        #expect(outer.contains(inner) == false)
    }

    /// Polygon with hole does not contain a point inside the hole.
    @Test
    func polygonWithHoleContainsPointInHole() throws {
        // Point is inside the outer ring but inside the hole -> not contained
        let polygon = try #require(Polygon([
            [Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)],
            [Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)],
        ]))
        let pointInHole = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(polygon.contains(pointInHole) == false)
    }

    /// Polygon contains a chord whose endpoints lie on its boundary.
    @Test
    func polygonContainsChord() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let chord = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))

        #expect(polygon.covers(chord))
        #expect(polygon.contains(chord))
    }

    /// A polygon does not contain a line that lies entirely on its boundary.
    @Test
    func polygonDoesNotContainBoundaryLine() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let boundaryLine = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))

        #expect(polygon.covers(boundaryLine))
        #expect(polygon.contains(boundaryLine) == false)
    }

    /// A polygon does not cover a polygon that fills one of its holes.
    @Test
    func polygonDoesNotCoverPolygonAroundHole() throws {
        let polygon = try #require(Polygon([
            [Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)],
            [Coordinate3D(latitude: 4.0, longitude: 4.0), Coordinate3D(latitude: 4.0, longitude: 6.0), Coordinate3D(latitude: 6.0, longitude: 6.0), Coordinate3D(latitude: 6.0, longitude: 4.0), Coordinate3D(latitude: 4.0, longitude: 4.0)],
        ]))
        let aroundHole = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 7.0),
            Coordinate3D(latitude: 7.0, longitude: 7.0),
            Coordinate3D(latitude: 7.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]]))

        #expect(polygon.covers(aroundHole) == false)
        #expect(polygon.contains(aroundHole) == false)
    }

    /// A polygon does not contain a MultiPoint that lies entirely on its boundary.
    @Test
    func polygonDoesNotContainBoundaryMultiPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let boundaryPoints = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))

        #expect(polygon.covers(boundaryPoints))
        #expect(polygon.contains(boundaryPoints) == false)
    }

    // MARK: - MultiPolygon contains

    /// MultiPolygon contains a point in one of its polygons.
    @Test
    func multiPolygonContainsPoint() throws {
        let polygon1 = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 5.0), Coordinate3D(latitude: 5.0, longitude: 5.0), Coordinate3D(latitude: 5.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let polygon2 = try #require(Polygon([[Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0)]]))
        let multiPolygon = try #require(MultiPolygon([polygon1, polygon2]))
        let point = Point(Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(multiPolygon.contains(point))
    }

    /// MultiPolygon contains a smaller MultiPolygon.
    @Test
    func multiPolygonContainsMultiPolygon() throws {
        let outer1 = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let outer2 = try #require(Polygon([[Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 30.0), Coordinate3D(latitude: 30.0, longitude: 30.0), Coordinate3D(latitude: 30.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0)]]))
        let container = try #require(MultiPolygon([outer1, outer2]))

        let inner1 = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        let inner2 = try #require(Polygon([[Coordinate3D(latitude: 22.0, longitude: 22.0), Coordinate3D(latitude: 22.0, longitude: 28.0), Coordinate3D(latitude: 28.0, longitude: 28.0), Coordinate3D(latitude: 28.0, longitude: 22.0), Coordinate3D(latitude: 22.0, longitude: 22.0)]]))
        let contained = try #require(MultiPolygon([inner1, inner2]))
        #expect(container.contains(contained))
    }

    // MARK: - isWithin

    /// Point isWithin a polygon.
    @Test
    func pointIsWithinPolygon() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(point.isWithin(polygon))
    }

    /// Point is notWithin a polygon.
    @Test
    func pointIsNotWithinPolygon() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(point.isWithin(polygon) == false)
    }

    /// Inner polygon isWithin outer polygon.
    @Test
    func polygonIsWithinPolygon() throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        #expect(inner.isWithin(outer))
    }

    // MARK: - Feature and FeatureCollection

    /// Feature contains a point.
    @Test
    func featureContainsPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let feature = Feature(polygon)
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(feature.contains(point))
    }

    /// FeatureCollection contains a point.
    @Test
    func featureCollectionContainsPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let featureCollection = FeatureCollection([Feature(polygon)])
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(featureCollection.contains(point))
    }

    /// FeatureCollection does not contain an exterior point.
    @Test
    func featureCollectionDoesNotContainPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let featureCollection = FeatureCollection([Feature(polygon)])
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(featureCollection.contains(point) == false)
    }

    // MARK: - Projections

    /// Contains check in EPSG:3857.
    @Test
    func containsEPSG3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let inside = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))
        let outside = Point(Coordinate3D(x: 2000.0, y: 2000.0, projection: .epsg3857))
        #expect(polygon.contains(inside))
        #expect(polygon.contains(outside) == false)
        #expect(inside.isWithin(polygon))
    }

    /// Contains check in EPSG:4978.
    @Test
    func containsEPSG4978() throws {
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

    /// Contains check in noSRID projection.
    @Test
    func containsNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let inside = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))
        let outside = Point(Coordinate3D(x: 2000.0, y: 2000.0, projection: .noSRID))
        #expect(polygon.contains(inside))
        #expect(polygon.contains(outside) == false)
    }

    // MARK: - Projections for non-Polygon types

    /// MultiPoint contains point in EPSG:3857.
    @Test
    func multiPointContainsPointEPSG3857() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
        ]))
        #expect(mp.contains(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857))))
        #expect(mp.contains(Point(Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857))))
        #expect(mp.contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))) == false)
    }

    /// MultiPoint contains point in EPSG:4978.
    @Test
    func multiPointContainsPointEPSG4978() throws {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let b = Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978)
        let mp = try #require(MultiPoint([a, b]))
        #expect(mp.contains(Point(a)))
        #expect(mp.contains(Point(b)))
        #expect(mp.contains(Point(Coordinate3D(latitude: 5.0, longitude: 5.0).projected(to: .epsg4978))) == false)
    }

    /// MultiPoint contains point in noSRID.
    @Test
    func multiPointContainsPointNoSRID() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
        ]))
        #expect(mp.contains(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID))))
        #expect(mp.contains(Point(Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID))))
        #expect(mp.contains(Point(Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID))) == false)
    }

    /// LineString contains point in EPSG:3857.
    @Test
    func lineStringContainsPointEPSG3857() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
        ]))
        #expect(line.contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))))
        #expect(line.contains(Point(Coordinate3D(x: 600.0, y: 500.0, projection: .epsg3857))) == false)
    }

    /// LineString contains point in EPSG:4978.
    @Test
    func lineStringContainsPointEPSG4978() throws {
        // Short ECEF segment at Z=0 so the 2D XY check is exact.
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 100.0, z: 0.0, projection: .epsg4978),
        ]))
        #expect(line.contains(Point(Coordinate3D(x: 50.0, y: 50.0, z: 0.0, projection: .epsg4978))))
        #expect(line.contains(Point(Coordinate3D(x: 50.0, y: 60.0, z: 0.0, projection: .epsg4978))) == false)
        #expect(line.contains(Point(Coordinate3D(x: 50.0, y: 60.0, z: 0.0, projection: .epsg4978))) == false)
    }

    /// LineString contains point in noSRID.
    @Test
    func lineStringContainsPointNoSRID() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
        ]))
        #expect(line.contains(Point(Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID))))
        #expect(line.contains(Point(Coordinate3D(x: 5.0, y: 6.0, projection: .noSRID))) == false)
    }

    /// MultiLineString contains point in EPSG:3857.
    @Test
    func multiLineStringContainsPointEPSG3857() throws {
        let ml1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857),
        ]))
        let ml2 = try #require(LineString([
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1500.0, y: 500.0, projection: .epsg3857),
        ]))
        let ml = try #require(MultiLineString([
            ml1,
            ml2,
        ]))
        #expect(ml.contains(Point(Coordinate3D(x: 250.0, y: 250.0, projection: .epsg3857))))
        #expect(ml.contains(Point(Coordinate3D(x: 1250.0, y: 250.0, projection: .epsg3857))))
        #expect(ml.contains(Point(Coordinate3D(x: 750.0, y: 750.0, projection: .epsg3857))) == false)
    }

    /// MultiLineString contains point in EPSG:4978.
    @Test
    func multiLineStringContainsPointEPSG4978() throws {
        let ml1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 100.0, z: 0.0, projection: .epsg4978),
        ]))
        let ml2 = try #require(LineString([
            Coordinate3D(x: 200.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 300.0, y: 100.0, z: 0.0, projection: .epsg4978),
        ]))
        let ml = try #require(MultiLineString([
            ml1,
            ml2,
        ]))
        #expect(ml.contains(Point(Coordinate3D(x: 50.0, y: 50.0, z: 0.0, projection: .epsg4978))))
        #expect(ml.contains(Point(Coordinate3D(x: 250.0, y: 50.0, z: 0.0, projection: .epsg4978))))
        #expect(ml.contains(Point(Coordinate3D(x: 150.0, y: 150.0, z: 0.0, projection: .epsg4978))) == false)
    }

    /// MultiLineString contains point in noSRID.
    @Test
    func multiLineStringContainsPointNoSRID() throws {
        let ml1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
        ]))
        let ml2 = try #require(LineString([
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 15.0, y: 5.0, projection: .noSRID),
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

    /// Polygon contains MultiLineString.
    @Test
    func polygonContainsMultiLineString() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let insideLine = try #require(LineString([Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 5.0, longitude: 5.0)]))
        let outsideLine = try #require(LineString([Coordinate3D(latitude: 5.0, longitude: 5.0), Coordinate3D(latitude: 15.0, longitude: 15.0)]))
        let mlInside = try #require(MultiLineString([insideLine]))
        let mlOutside = try #require(MultiLineString([outsideLine]))
        #expect(polygon.contains(mlInside))
        #expect(polygon.contains(mlOutside) == false)
    }

    /// Polygon contains MultiPolygon.
    @Test
    func polygonContainsMultiPolygon() throws {
        let outer = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 20.0), Coordinate3D(latitude: 20.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        let inner1 = try #require(Polygon([[Coordinate3D(latitude: 2.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 8.0), Coordinate3D(latitude: 8.0, longitude: 2.0), Coordinate3D(latitude: 2.0, longitude: 2.0)]]))
        let inner2 = try #require(Polygon([[Coordinate3D(latitude: 12.0, longitude: 12.0), Coordinate3D(latitude: 12.0, longitude: 18.0), Coordinate3D(latitude: 18.0, longitude: 18.0), Coordinate3D(latitude: 18.0, longitude: 12.0), Coordinate3D(latitude: 12.0, longitude: 12.0)]]))
        let mp = try #require(MultiPolygon([inner1, inner2]))
        #expect(outer.contains(mp))
    }

    // MARK: - Feature / FeatureCollection with non-4326 projections

    /// Feature contains point in EPSG:3857.
    @Test
    func featureContainsPointEPSG3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        #expect(Feature(polygon).contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))))
    }

    /// Feature contains point in EPSG:4978.
    @Test
    func featureContainsPointEPSG4978() throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(Feature(polygon4326.projected(to: .epsg4978)).contains(Point(Coordinate3D(latitude: 0.5, longitude: 0.5).projected(to: .epsg4978))))
    }

    /// Feature contains point in noSRID.
    @Test
    func featureContainsPointNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        #expect(Feature(polygon).contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))))
    }

    /// FeatureCollection contains point in EPSG:3857.
    @Test
    func featureCollectionContainsPointEPSG3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        #expect(FeatureCollection([Feature(polygon)]).contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))))
    }

    /// FeatureCollection contains point in EPSG:4978.
    @Test
    func featureCollectionContainsPointEPSG4978() throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(FeatureCollection([Feature(polygon4326.projected(to: .epsg4978))]).contains(Point(Coordinate3D(latitude: 0.5, longitude: 0.5).projected(to: .epsg4978))))
    }

    /// FeatureCollection contains point in noSRID.
    @Test
    func featureCollectionContainsPointNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        #expect(FeatureCollection([Feature(polygon)]).contains(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))))
    }

    // MARK: - GeometryCollection contains

    /// GeometryCollection contains point.
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

    /// Bounding box fast-fail for distant polygons.
    @Test
    func boundingBoxFastFail() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 10.0), Coordinate3D(latitude: 10.0, longitude: 0.0), Coordinate3D(latitude: 0.0, longitude: 0.0)]]))
        // Far away — bounding box check should short-circuit
        let farPolygon = try #require(Polygon([[Coordinate3D(latitude: 100.0, longitude: 100.0), Coordinate3D(latitude: 100.0, longitude: 110.0), Coordinate3D(latitude: 110.0, longitude: 110.0), Coordinate3D(latitude: 110.0, longitude: 100.0), Coordinate3D(latitude: 100.0, longitude: 100.0)]]))
        #expect(polygon.contains(farPolygon) == false)
    }

    // MARK: - Antimeridian

    /// Polygon near antimeridian contains an interior point.
    @Test
    func polygonNearAntimeridianContainsPoint() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 160.0)]]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 165.0))
        #expect(polygon.contains(pointInside))
    }

    /// Polygon near antimeridian does not contain far-side point.
    @Test
    func polygonNearAntimeridianDoesNotContainFarSide() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 160.0)]]))
        // Point at -165° is on the other side of the antimeridian, well outside the polygon
        let pointOutside = Point(Coordinate3D(latitude: 5.0, longitude: -165.0))
        #expect(polygon.contains(pointOutside) == false)
    }

    /// Point near antimeridian isWithin polygon.
    @Test
    func pointNearAntimeridianIsWithinPolygon() throws {
        let polygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 10.0, longitude: 160.0), Coordinate3D(latitude: 0.0, longitude: 160.0)]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 165.0))
        #expect(point.isWithin(polygon))
    }

    /// MultiPolygon spanning antimeridian contains points on both sides.
    @Test
    func multiPolygonSpanningAntimeridianContainsPoint() throws {
        let westPolygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 180.0), Coordinate3D(latitude: 10.0, longitude: 180.0), Coordinate3D(latitude: 10.0, longitude: 170.0), Coordinate3D(latitude: 0.0, longitude: 170.0)]]))
        let eastPolygon = try #require(Polygon([[Coordinate3D(latitude: 0.0, longitude: -180.0), Coordinate3D(latitude: 0.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: -170.0), Coordinate3D(latitude: 10.0, longitude: -180.0), Coordinate3D(latitude: 0.0, longitude: -180.0)]]))
        let multiPolygon = try #require(MultiPolygon([westPolygon, eastPolygon]))
        let pointWest = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointEast = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(multiPolygon.contains(pointWest))
        #expect(multiPolygon.contains(pointEast))
    }

    /// LineString near antimeridian contains a point on it.
    @Test
    func lineStringNearAntimeridianContainsPoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 180.0),
        ]))
        let pointOnLine = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        let pointOffLine = Point(Coordinate3D(latitude: 5.0, longitude: -175.0))
        #expect(line.contains(pointOnLine))
        #expect(line.contains(pointOffLine) == false)
    }

    /// Line endpoint containment in EPSG:3857.
    @Test
    func lineStringContainsEndpoint3857() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
        ]))
        let start = Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857))
        let middle = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))

        #expect(line.covers(start))
        #expect(line.contains(start) == false)
        #expect(line.contains(middle))
    }

    /// Line endpoint containment in EPSG:4978.
    @Test
    func lineStringContainsEndpoint4978() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 100.0, z: 0.0, projection: .epsg4978),
        ]))
        let start = Point(Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978))
        let middle = Point(Coordinate3D(x: 50.0, y: 50.0, z: 0.0, projection: .epsg4978))

        #expect(line.covers(start))
        #expect(line.contains(start) == false)
        #expect(line.contains(middle))
    }

    /// Polygon contains a chord in noSRID.
    @Test
    func polygonContainsChordNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let chord = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
        ]))

        #expect(polygon.covers(chord))
        #expect(polygon.contains(chord))
    }

    /// Antimeridian-crossing container with an antimeridian-crossing hole.
    @Test
    func antimeridianPolygonWithHoleContains() throws {
        let container = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: 175.0),
            ],
        ]))
        let aboveHole = try #require(Polygon([[
            Coordinate3D(latitude: 16.0, longitude: 176.0),
            Coordinate3D(latitude: 16.0, longitude: -176.0),
            Coordinate3D(latitude: 19.0, longitude: -176.0),
            Coordinate3D(latitude: 19.0, longitude: 176.0),
            Coordinate3D(latitude: 16.0, longitude: 176.0),
        ]]))
        let aroundHole = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 173.0),
            Coordinate3D(latitude: 3.0, longitude: -173.0),
            Coordinate3D(latitude: 17.0, longitude: -173.0),
            Coordinate3D(latitude: 17.0, longitude: 173.0),
            Coordinate3D(latitude: 3.0, longitude: 173.0),
        ]]))
        let throughHole = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 172.0),
            Coordinate3D(latitude: 10.0, longitude: -172.0),
        ]))

        #expect(container.contains(aboveHole))
        #expect(container.contains(aroundHole) == false)
        #expect(container.covers(throughHole) == false)
        #expect(container.contains(throughHole) == false)
    }

    // MARK: - Empty / degenerate

    /// Empty polygon contains nothing.
    @Test
    func emptyPolygonDoesNotContain() {
        let emptyPolygon = Polygon()
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(emptyPolygon.contains(point) == false)
    }

    /// Single-point LineString does not contain its point.
    @Test
    func singlePointLineStringContainsItsPoint() {
        let degenerateLine = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ])
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 10.0))
        #expect(degenerateLine.contains(point) == false)
    }

    /// Empty MultiPoint contains nothing.
    @Test
    func emptyMultiPointContainsNothing() {
        let emptyMultiPoint = MultiPoint()
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 2.0))
        #expect(emptyMultiPoint.contains(point) == false)
    }

    private func square(
        minX: Double,
        minY: Double,
        maxX: Double,
        maxY: Double,
        projection: Projection = .epsg4326,
    ) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: minX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: minY, projection: projection),
        ]])
    }

    // MARK: - containsProperly

    @Test
    func containsProperly() {
        let container = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
        let inner = square(minX: 2.0, minY: 2.0, maxX: 8.0, maxY: 8.0)
        let touching = square(minX: 10.0, minY: 2.0, maxX: 15.0, maxY: 8.0)

        #expect(container.containsProperly(inner))
        #expect(container.containsProperly(container) == false)
        #expect(container.containsProperly(touching) == false)
        #expect(container.containsProperly(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))
        #expect(container.containsProperly(Point(Coordinate3D(latitude: 0.0, longitude: 5.0))) == false)
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func containsProperlyAcrossProjections(projection: Projection) {
        let polygon: Polygon
        let inner: Polygon

        switch projection {
        case .epsg4326:
            polygon = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
            inner = square(minX: 2.0, minY: 2.0, maxX: 8.0, maxY: 8.0)

        case .epsg4978:
            polygon = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
                .projected(to: .epsg4978)
            inner = square(minX: 2.0, minY: 2.0, maxX: 8.0, maxY: 8.0)
                .projected(to: .epsg4978)

        default:
            polygon = square(minX: 0.0, minY: 0.0, maxX: 1000.0, maxY: 1000.0, projection: projection)
            inner = square(minX: 200.0, minY: 200.0, maxX: 800.0, maxY: 800.0, projection: projection)
        }

        #expect(polygon.containsProperly(inner))
    }

}

// MARK: - Projection and collection regressions

extension BooleanContainsTests {

    @Test
    func containsPolygonIn3857And4978() throws {
        let polygon3857 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let inner3857 = try #require(Polygon([[
            Coordinate3D(x: 100.0, y: 100.0, projection: .epsg3857),
            Coordinate3D(x: 900.0, y: 100.0, projection: .epsg3857),
            Coordinate3D(x: 900.0, y: 900.0, projection: .epsg3857),
            Coordinate3D(x: 100.0, y: 900.0, projection: .epsg3857),
            Coordinate3D(x: 100.0, y: 100.0, projection: .epsg3857),
        ]]))
        #expect(polygon3857.contains(inner3857))

        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.1),
            Coordinate3D(latitude: 0.1, longitude: 0.1),
            Coordinate3D(latitude: 0.1, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon4978 = polygon4326.projected(to: .epsg4978)
        let inner4978 = try #require(Polygon([[
            Coordinate3D(latitude: 0.02, longitude: 0.02),
            Coordinate3D(latitude: 0.02, longitude: 0.08),
            Coordinate3D(latitude: 0.08, longitude: 0.08),
            Coordinate3D(latitude: 0.08, longitude: 0.02),
            Coordinate3D(latitude: 0.02, longitude: 0.02),
        ]])).projected(to: .epsg4978)
        #expect(polygon4978.contains(inner4978))
    }

    @Test
    func featureCollectionRequiresAllFeatures() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let inside = FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 2.0, longitude: 2.0))),
            Feature(Point(Coordinate3D(latitude: 8.0, longitude: 8.0))),
        ])
        let mixed = FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 2.0, longitude: 2.0))),
            Feature(Point(Coordinate3D(latitude: 20.0, longitude: 20.0))),
        ])

        #expect(polygon.contains(inside))
        #expect(!polygon.contains(mixed))
        #expect(polygon.covers(inside))
        #expect(!polygon.covers(mixed))
    }

    @Test
    func containsProperlyAcrossCollectionReceivers() throws {
        let square = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let inner = try #require(Polygon([[
            Coordinate3D(x: 2.0, y: 2.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 4.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 4.0, y: 2.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 2.0, projection: .noSRID),
        ]]))
        let touching = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 2.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 4.0, projection: .noSRID),
            Coordinate3D(x: 2.0, y: 2.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 2.0, projection: .noSRID),
        ]]))

        let multiPolygon = try #require(MultiPolygon([square]))
        #expect(multiPolygon.containsProperly(inner))
        #expect(!multiPolygon.containsProperly(touching))

        let geometryCollection = GeometryCollection([square])
        #expect(geometryCollection.containsProperly(inner))
        #expect(!geometryCollection.containsProperly(touching))

        let feature = Feature(square)
        #expect(feature.containsProperly(inner))
        #expect(!feature.containsProperly(touching))

        let featureCollection = FeatureCollection([feature])
        #expect(featureCollection.containsProperly(inner))
        #expect(!featureCollection.containsProperly(touching))
    }

    @Test
    func containsProperlyForPointLineAndMultiPoint() throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
        ]))
        #expect(multiPoint.containsProperly(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID))))

        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]))
        #expect(line.containsProperly(Point(Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID))))
        #expect(!line.containsProperly(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID))))
    }

}

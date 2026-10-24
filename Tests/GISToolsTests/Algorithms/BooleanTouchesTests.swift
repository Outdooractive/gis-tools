import Foundation
@testable import GISTools
import Testing

struct BooleanTouchesTests {

    // MARK: - Point × LineString — true

    /// Point touches LineString at start endpoint.
    @Test
    func pointTouchesLineStringAtStart() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(point.touches(line))
        #expect(line.touches(point))
    }

    /// Point touches LineString at end endpoint.
    @Test
    func pointTouchesLineStringAtEnd() throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(point.touches(line))
    }

    // MARK: - Point × LineString — false

    /// Point on line interior does not touch.
    @Test
    func pointOnLineInteriorDoesNotTouch() throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(point.touches(line) == false)
    }

    /// Point off line does not touch.
    @Test
    func pointOffLineDoesNotTouch() throws {
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(point.touches(line) == false)
    }

    // MARK: - Point × MultiLineString

    /// Point touches MultiLineString at endpoint.
    @Test
    func pointTouchesMultiLineString() throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let mls = try #require(MultiLineString([line1, line2]))
        #expect(point.touches(mls))
        #expect(mls.touches(point))
    }

    // MARK: - Point × Polygon

    /// Point on polygon ring touches.
    @Test
    func pointOnPolygonRingTouches() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(point.touches(polygon))
        #expect(polygon.touches(point))
    }

    /// Point inside polygon does not touch.
    @Test
    func pointInsidePolygonDoesNotTouch() throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // Point is strictly inside — interiors intersect
        #expect(point.touches(polygon) == false)
    }

    /// Point outside polygon does not touch.
    @Test
    func pointOutsidePolygonDoesNotTouch() throws {
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(point.touches(polygon) == false)
    }

    // MARK: - MultiPoint × LineString

    /// MultiPoint touches LineString at endpoint.
    @Test
    func multiPointTouchesLineStringAtEndpoint() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        // One point on endpoint, other outside → touches
        #expect(mp.touches(line))
        #expect(line.touches(mp))
    }

    /// MultiPoint on line interior does not touch.
    @Test
    func multiPointOnLineInteriorDoesNotTouch() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        // One point on interior → interiors intersect → not touching
        #expect(mp.touches(line) == false)
    }

    // MARK: - MultiPoint × Polygon

    /// MultiPoint touches polygon on boundary.
    @Test
    func multiPointTouchesPolygonOnBoundary() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(mp.touches(polygon))
        #expect(polygon.touches(mp))
    }

    /// MultiPoint inside polygon does not touch.
    @Test
    func multiPointInsidePolygonDoesNotTouch() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(mp.touches(polygon) == false)
    }

    /// MultiPoint partially inside polygon does not touch.
    @Test
    func multiPointPartialInsidePolygonDoesNotTouch() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // One point strictly inside → interiors intersect
        #expect(mp.touches(polygon) == false)
    }

    // MARK: - LineString × LineString

    /// LineStrings touch at shared endpoint.
    @Test
    func lineStringsTouchAtEndpoint() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        // Share endpoint at (5, 5), no interior overlap
        #expect(line1.touches(line2))
        #expect(line2.touches(line1))
    }

    /// Crossing LineStrings do not touch.
    @Test
    func lineStringsCrossingDoNotTouch() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ]))
        // Cross at interior point (5, 5) → interiors intersect
        #expect(line1.touches(line2) == false)
        #expect(line2.touches(line1) == false)
    }

    /// Overlapping LineStrings do not touch.
    @Test
    func lineStringsOverlappingDoNotTouch() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
        ]))
        // Overlap at interior points
        #expect(line1.touches(line2) == false)
    }

    /// Disjoint LineStrings do not touch.
    @Test
    func lineStringsDisjointDoNotTouch() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
        ]))
        #expect(line1.touches(line2) == false)
    }

    // MARK: - LineString × Polygon

    /// LineString touches polygon at vertex.
    @Test
    func lineStringTouchesPolygonAtVertex() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // Endpoint at (0,0) on polygon boundary, rest outside
        #expect(line.touches(polygon))
        #expect(polygon.touches(line))
    }

    /// LineString inside polygon does not touch.
    @Test
    func lineStringInsidePolygonDoesNotTouch() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // Entire line inside → interiors intersect
        #expect(line.touches(polygon) == false)
    }

    // MARK: - Polygon × Polygon

    /// Polygons touch at shared vertex.
    @Test
    func polygonsTouchAtVertex() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]]))
        // Touch at the single point (5, 5)
        #expect(poly1.touches(poly2))
        #expect(poly2.touches(poly1))
    }

    /// Overlapping polygons do not touch.
    @Test
    func polygonsOverlapDoNotTouch() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 8.0, longitude: 0.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 0.0, longitude: 8.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 12.0, longitude: 4.0),
            Coordinate3D(latitude: 12.0, longitude: 12.0),
            Coordinate3D(latitude: 4.0, longitude: 12.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ]]))
        // Overlapping area → interiors intersect
        #expect(poly1.touches(poly2) == false)
    }

    /// Disjoint polygons do not touch.
    @Test
    func polygonsDisjointDoNotTouch() throws {
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
        #expect(poly1.touches(poly2) == false)
    }

    // MARK: - Polygon × MultiPolygon

    /// Polygon touches MultiPolygon at vertex.
    @Test
    func polygonTouchesMultiPolygon() throws {
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
        let poly3 = try #require(Polygon([[
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]]))
        let mp = try #require(MultiPolygon([poly2, poly3]))
        // poly1 touches poly3 at the shared vertex (5, 5)
        #expect(poly1.touches(mp))
        #expect(mp.touches(poly1))
    }

    // MARK: - MultiLineString × Polygon

    /// MultiLineString touches polygon at endpoint.
    @Test
    func multiLineStringTouchesPolygon() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ]))
        let mls = try #require(MultiLineString([line1, line2]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // line2 endpoint at (0,0) on polygon boundary
        #expect(mls.touches(polygon))
        #expect(polygon.touches(mls))
    }

    // MARK: - FeatureCollection

    /// FeatureCollection touches via unwrapped geometry.
    @Test
    func featureCollectionTouches() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let fc = FeatureCollection([Feature(point)])
        #expect(fc.touches(line))
        #expect(line.touches(fc))
    }

    /// FeatureCollection does not touch distant geometry.
    @Test
    func featureCollectionDoesNotTouch() throws {
        let point = Point(Coordinate3D(latitude: 20.0, longitude: 20.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let fc = FeatureCollection([Feature(point)])
        #expect(fc.touches(line) == false)
    }

    // MARK: - GeometryCollection

    /// GeometryCollection touches via unwrapped geometry.
    @Test
    func geometryCollectionTouches() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let gc = GeometryCollection([point])
        #expect(gc.touches(line))
    }

    // MARK: - Unsupported combinations return false

    /// Point–Point never touches (unsupported).
    @Test
    func pointPointDoesNotTouch() {
        let p1 = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        let p2 = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        #expect(p1.touches(p2) == false)
    }

    /// MultiPoint–MultiPoint never touches (unsupported).
    @Test
    func multiPointMultiPointDoesNotTouch() throws {
        let mp1 = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let mp2 = try #require(MultiPoint([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        #expect(mp1.touches(mp2) == false)
    }

    // MARK: - Commutativity

    /// Touches is commutative.
    @Test
    func touchesIsCommutative() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        #expect(line1.touches(line2) == line2.touches(line1))
    }

    // MARK: - Grid size

    /// Validates that `touches(_:gridSize:)` matches manual pre-snapping.
    @Test
    func touchesWithGridSize() throws {
        let point = Point(Coordinate3D(latitude: 0.0001, longitude: 0.0001))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let gridSize = 0.001

        let withParam = point.touches(line, gridSize: gridSize)
        let snappedPoint = point.snappedToGrid(tolerance: gridSize)
        let snappedLine = line.snappedToGrid(tolerance: gridSize)
        let manual = snappedPoint.touches(snappedLine)
        #expect(withParam == manual)
    }

    // MARK: - Projections

    /// Touches check in EPSG:3857.
    @Test
    func touchesEPSG3857() throws {
        // Two squares touching at a single vertex in EPSG:3857.
        let poly1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 2000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 2000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
        ]]))
        #expect(poly1.touches(poly2))
        #expect(poly2.touches(poly1))
    }

    /// Touches check in EPSG:4978.
    @Test
    func touchesEPSG4978() throws {
        // Two squares touching at the 1° meridian near the equator, in 4978 (ECEF).
        let s1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let s2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]]))
        let p1 = s1.projected(to: .epsg4978)
        let p2 = s2.projected(to: .epsg4978)
        #expect(p1.touches(p2))
    }

    /// Touches check in noSRID.
    @Test
    func touchesNoSRID() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 2000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 2000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
        ]]))
        #expect(poly1.touches(poly2))
    }

    // MARK: - Antimeridian

    /// Line touches polygon near antimeridian.
    @Test
    func antimeridian() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        #expect(polygon.touches(line))
    }

    // MARK: - Empty / degenerate

    /// Empty polygon does not touch anything.
    @Test
    func emptyPolygonDoesNotTouch() throws {
        let emptyPolygon = Polygon()
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(emptyPolygon.touches(point) == false)
        #expect(point.touches(emptyPolygon) == false)
        #expect(emptyPolygon.touches(line) == false)
    }

    /// Single-point LineString touches its only coordinate.
    @Test
    func singlePointLineStringDoesNotTouch() {
        let degenerateLine = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ])
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 10.0))
        // A single-point degenerate line touches the point at its only coordinate
        #expect(degenerateLine.touches(point))
        #expect(point.touches(degenerateLine))
    }

}

// MARK: - Audit regressions

extension BooleanTouchesTests {

    private func polygonWithHole() -> Polygon {
        Polygon(unchecked: [
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
            ],
        ])
    }

    @Test
    func lineTouchingHoleBoundaryTouches() throws {
        let polygon = polygonWithHole()
        let line = try #require(LineString([
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 6.0),
        ]))

        #expect(line.touches(polygon))
        #expect(polygon.touches(line))
    }

    @Test
    func tJunctionLineTouches() throws {
        let horizontal = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let vertical = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))

        #expect(horizontal.touches(vertical))
        #expect(vertical.touches(horizontal))
    }

    @Test
    func polygonVertexOnEdgeTouchesSymmetrically() throws {
        let square = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let triangle = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: -1.0, longitude: 5.0),
            Coordinate3D(latitude: -1.0, longitude: 6.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]]))

        #expect(square.touches(triangle))
        #expect(triangle.touches(square))
    }

    @Test
    func sharedMultiLineEndpointIsNotBoundary() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
        ]))
        let multi = try #require(MultiLineString([line1, line2]))
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 1.0))

        #expect(!point.touches(multi))
        #expect(!multi.touches(point))
    }

    @Test
    func pointOnPolygonHoleBoundaryTouches() {
        let polygon = polygonWithHole()
        let point = Point(Coordinate3D(latitude: 4.0, longitude: 5.0))

        #expect(point.touches(polygon))
        #expect(polygon.touches(point))
    }

    @Test
    func pointOnMultiPolygonHoleBoundaryTouches() throws {
        let multiPolygon = try #require(MultiPolygon([polygonWithHole()]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 4.0))

        #expect(point.touches(multiPolygon))
        #expect(multiPolygon.touches(point))
    }

    @Test
    func lineStringTouchesMultiLineStringAtEndpoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]))
        let multi = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
            ],
            [
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
            ],
        ]))

        #expect(line.touches(multi))
        #expect(multi.touches(line))
    }

    @Test
    func pointAndMultiPointAreNotSupportedTouches() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        #expect(!point.touches(multiPoint))
        #expect(!multiPoint.touches(point))
    }

}

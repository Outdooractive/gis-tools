@testable import GISTools
import Testing

struct BooleanDisjointTests {

    // Tests that spatially separated geometries are correctly identified as disjoint.
    @Test
    func isTrue() async throws {
        let point1 = try TestData.point(package: "BooleanDisjoint", name: "Point1")
        let point2 = try TestData.point(package: "BooleanDisjoint", name: "Point2")
        let multiPoint1 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint1")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint2")
        let multiPoint3 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint3")
        let lineString1 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString1")
        let lineString2 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString2")
        let polygon1 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon1")
        let polygon2 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon2")
        let multiPolygon1 = try TestData.multiPolygon(package: "BooleanDisjoint", name: "MultiPolygon1")

        #expect(point1.isDisjoint(with: point2))
        #expect(point1.isDisjoint(with: multiPoint2))
        #expect(point1.isDisjoint(with: lineString2))
        #expect(point2.isDisjoint(with: point1))
        #expect(point2.isDisjoint(with: polygon1))
        #expect(point2.isDisjoint(with: multiPolygon1))

        #expect(multiPoint1.isDisjoint(with: multiPoint2))
        #expect(multiPoint2.isDisjoint(with: point1))
        #expect(multiPoint2.isDisjoint(with: multiPoint1))
        #expect(multiPoint3.isDisjoint(with: polygon1))

        #expect(lineString1.isDisjoint(with: lineString2))
        #expect(lineString1.isDisjoint(with: polygon1))
        #expect(lineString2.isDisjoint(with: point1))
        #expect(lineString2.isDisjoint(with: multiPoint1))
        #expect(lineString2.isDisjoint(with: lineString1))

        #expect(polygon1.isDisjoint(with: point2))
        #expect(polygon1.isDisjoint(with: multiPoint3))
        #expect(polygon1.isDisjoint(with: lineString1))
        #expect(polygon1.isDisjoint(with: polygon2))
        #expect(polygon2.isDisjoint(with: multiPolygon1))
        #expect(polygon2.isDisjoint(with: polygon1))

        #expect(multiPolygon1.isDisjoint(with: polygon2))
        #expect(multiPolygon1.isDisjoint(with: point2))
    }

    // Tests that intersecting geometries are correctly identified as not disjoint.
    @Test
    func isFalse() async throws {
        let point3 = try TestData.point(package: "BooleanDisjoint", name: "Point3")
        let point4 = try TestData.point(package: "BooleanDisjoint", name: "Point4")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint2")
        let multiPoint4 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint4")
        let multiPoint5 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint5")
        let lineString2 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString2")
        let lineString3 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString3")
        let lineString4 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString4")
        let polygon1 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon1")
        let polygon3 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon3")
        let multiPolygon1 = try TestData.multiPolygon(package: "BooleanDisjoint", name: "MultiPolygon1")

        #expect(point3.isDisjoint(with: lineString2) == false)
        #expect(point4.isDisjoint(with: lineString2) == false)

        #expect(multiPoint2.isDisjoint(with: multiPoint4) == false)
        #expect(multiPoint4.isDisjoint(with: lineString2) == false)
        #expect(multiPoint5.isDisjoint(with: polygon1) == false)

        #expect(lineString2.isDisjoint(with: point3) == false)
        #expect(lineString2.isDisjoint(with: point4) == false)
        #expect(lineString2.isDisjoint(with: lineString3) == false)
        #expect(lineString2.isDisjoint(with: multiPoint4) == false)
        #expect(lineString3.isDisjoint(with: lineString2) == false)
        #expect(lineString3.isDisjoint(with: polygon1) == false)
        #expect(lineString4.isDisjoint(with: polygon1) == false)

        #expect(polygon1.isDisjoint(with: multiPoint5) == false)
        #expect(polygon1.isDisjoint(with: lineString3) == false)
        #expect(polygon1.isDisjoint(with: lineString4) == false)
        #expect(polygon3.isDisjoint(with: multiPolygon1) == false)

        #expect(multiPolygon1.isDisjoint(with: polygon3) == false)
    }

    // MARK: - Grid size

    // Validates that `isDisjoint(with:gridSize:)` matches manual pre-snapping.
    @Test
    func disjointWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let point = Point(Coordinate3D(latitude: 5.00005, longitude: 5.00005))
        let outside = Point(Coordinate3D(latitude: 20.00005, longitude: 20.00005))
        let gridSize = 0.001

        let withParam = polygon.isDisjoint(with: point, gridSize: gridSize)
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let snappedPoint = point.snappedToGrid(tolerance: gridSize)
        let manual = snappedPolygon.isDisjoint(with: snappedPoint)
        #expect(withParam == manual)

        let withParamOutside = polygon.isDisjoint(with: outside, gridSize: gridSize)
        let snappedOutside = outside.snappedToGrid(tolerance: gridSize)
        let manualOutside = snappedPolygon.isDisjoint(with: snappedOutside)
        #expect(withParamOutside == manualOutside)
    }

    // MARK: - Projections

    // Disjoint check in EPSG:3857.
    @Test
    func isDisjointEPSG3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let pointInside = Point(Coordinate3D(x: 500.0, y: 500.0))
        let pointOutside = Point(Coordinate3D(x: 2_000.0, y: 2_000.0))
        #expect(!polygon.isDisjoint(with: pointInside))
        #expect(polygon.isDisjoint(with: pointOutside))
    }

    // Disjoint check in EPSG:4978.
    @Test
    func isDisjointEPSG4978() async throws {
        let poly4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = poly4326.projected(to: .epsg4978)
        let inside = Point(Coordinate3D(latitude: 0.5, longitude: 0.5)).projected(to: .epsg4978)
        let outside = Point(Coordinate3D(latitude: 5.0, longitude: 5.0)).projected(to: .epsg4978)
        #expect(!polygon.isDisjoint(with: inside))
        #expect(polygon.isDisjoint(with: outside))
    }

    // MultiPoint–Polygon disjoint in EPSG:3857.
    @Test
    func disjointMultiPointPolygonEPSG3857() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 2_000.0, y: 2_000.0)]))
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        #expect(!mp.isDisjoint(with: polygon))
    }

    // MultiPoint–Polygon disjoint in EPSG:4978.
    @Test
    func disjointMultiPointPolygonEPSG4978() async throws {
        let poly4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = poly4326.projected(to: .epsg4978)
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.5, longitude: 0.5).projected(to: .epsg4978),
            Coordinate3D(latitude: 5.0, longitude: 5.0).projected(to: .epsg4978)]))
        #expect(!mp.isDisjoint(with: polygon))
    }

    // Disjoint check in noSRID.
    @Test
    func isDisjointNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let pointInside = Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))
        let pointOutside = Point(Coordinate3D(x: 2_000.0, y: 2_000.0, projection: .noSRID))
        #expect(!polygon.isDisjoint(with: pointInside))
        #expect(polygon.isDisjoint(with: pointOutside))
    }

    // MARK: - Antimeridian

    // Polygon near antimeridian is not disjoint from interior point.
    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 175.0))
        #expect(!polygon.isDisjoint(with: point))
    }

    // MARK: - Empty / degenerate

    // Empty geometries are disjoint from everything.
    @Test
    func emptyGeometriesAreDisjointFromEverything() async throws {
        let emptyPolygon = Polygon()
        let emptyMultiPoint = MultiPoint()
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(emptyPolygon.isDisjoint(with: point))
        #expect(point.isDisjoint(with: emptyPolygon))
        #expect(emptyPolygon.isDisjoint(with: emptyMultiPoint))
        #expect(emptyMultiPoint.isDisjoint(with: emptyPolygon))
        #expect(emptyMultiPoint.isDisjoint(with: emptyMultiPoint))
    }

}

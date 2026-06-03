import Foundation
@testable import GISTools
import Testing

struct BooleanCrossesTests {

    // MARK: - LineString × LineString — true

    @Test
    func lineStringLineStringCrosses() async throws {
        // Vertical line at lon=2, from lat=1 to lat=4
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 2.0),
        ]))
        // Horizontal line at lat=2, from lon=1 to lon=4
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
        ]))
        // Intersects at (lat=2, lon=2) — not an endpoint of either
        #expect(line1.crosses(line2))
        #expect(line2.crosses(line1))
    }

    @Test
    func lineStringLineStringCrossesDiagonal() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: -2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: -1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 3.0),
        ]))
        #expect(line1.crosses(line2))
    }

    // MARK: - LineString × LineString — false

    @Test
    func lineStringLineStringDoesNotCross() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 4.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 5.0),
        ]))
        // Parallel lines, no intersection
        #expect(line1.crosses(line2) == false)
    }

    @Test
    func lineStringLineStringEndpointTouching() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
        ]))
        // Touch only at endpoint — not a crossing
        #expect(line1.crosses(line2) == false)
    }

    // MARK: - MultiPoint × LineString

    @Test
    func multiPointLineStringCrosses() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0),
            Coordinate3D(latitude: 4.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 5.0),  // exterior
        ]))
        let ls = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 4.0, longitude: 1.0),
        ]))
        #expect(mp.crosses(ls))
    }

    @Test
    func multiPointLineStringDoesNotCross() async throws {
        // Points on the interior of the line (not at endpoints)
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0),
        ]))
        let ls = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 4.0, longitude: 1.0),
        ]))
        // All points on the line — no exterior points
        #expect(mp.crosses(ls) == false)
    }

    // MARK: - MultiPoint × Polygon

    @Test
    func multiPointPolygonCrosses() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 10.0),  // exterior
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(mp.crosses(polygon))
    }

    @Test
    func multiPointPolygonDoesNotCross() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.5, longitude: 1.5),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // All points inside polygon — no exterior points
        #expect(mp.crosses(polygon) == false)
    }

    // MARK: - LineString × Polygon

    @Test
    func lineStringPolygonCrosses() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: -1.0, longitude: -1.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(ls.crosses(polygon))
    }

    @Test
    func lineStringPolygonDoesNotCross() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        // Line entirely outside polygon
        #expect(ls.crosses(polygon) == false)
    }

    // MARK: - LineString × MultiPolygon

    @Test
    func lineStringMultiPolygonCrosses() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: -1.0, longitude: 5.0),
            Coordinate3D(latitude: 3.0, longitude: 7.0),
        ]))
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 12.0, longitude: 0.0),
            Coordinate3D(latitude: 12.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))
        // Line crosses first polygon's boundary
        #expect(ls.crosses(mp))
    }

    // MARK: - Feature unwrapping

    @Test
    func featureCrosses() async throws {
        // Vertical line at lon=2
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 2.0),
        ]))
        // Horizontal line at lat=2
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
        ]))
        let feature1 = Feature(line1)
        let feature2 = Feature(line2)
        #expect(feature1.crosses(feature2))
    }

    // MARK: - Unsupported combinations

    @Test
    func unsupportedCombinationsReturnFalse() async throws {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        // Point × Point — not supported
        #expect(point.crosses(point) == false)
        // Point × LineString — not supported
        #expect(point.crosses(line) == false)
        // LineString × Point — not supported
        #expect(line.crosses(point) == false)
        // Polygon × Polygon — not supported
        #expect(polygon.crosses(polygon) == false)
        // MultiPoint × Point — not supported
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        #expect(mp.crosses(point) == false)
    }

    // MARK: - FeatureCollection

    @Test
    func featureCollectionCrosses() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 2.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
        ]))
        let fc = FeatureCollection([Feature(line1)])

        // FeatureCollection with a crossing feature
        #expect(fc.crosses(line2))
        #expect(line2.crosses(fc))
    }

    @Test
    func featureCollectionDoesNotCross() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
        ]))
        let fc = FeatureCollection([Feature(line1)])

        // No feature crosses
        #expect(fc.crosses(line2) == false)
    }

    // MARK: - Commutativity

    @Test
    func crossesIsCommutative() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 2.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
        ]))
        #expect(line1.crosses(line2) == line2.crosses(line1))
    }

}

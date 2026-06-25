import Foundation
@testable import GISTools
import Testing

struct BooleanCrossesTests {

    // MARK: - LineString × LineString — true

    // Tests that two LineStrings intersecting at an interior point are detected as crossing.
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

    // Tests that diagonally crossing LineStrings are detected as crossing.
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

    // Tests that parallel non-intersecting LineStrings do not cross.
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

    // Tests that LineStrings touching only at endpoints are not considered to cross.
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

    // Tests that a MultiPoint with points both on and off a LineString is detected as crossing.
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

    // Tests that a MultiPoint entirely on a LineString does not cross it.
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

    // Tests that a MultiPoint with points both inside and outside a Polygon is detected as crossing.
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

    // Tests that a MultiPoint entirely inside a Polygon does not cross it.
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

    // Tests that a LineString crossing a Polygon boundary is detected as crossing.
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

    // Tests that a LineString entirely outside a Polygon does not cross it.
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

    // Tests that a LineString crossing one polygon in a MultiPolygon is detected as crossing.
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

    // Tests that crossing detection works through Feature geometry unwrapping.
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

    // Tests that unsupported geometry type combinations return false for crosses.
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

    // Tests that crossing detection works through FeatureCollection geometry unwrapping.
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

    // Tests that a FeatureCollection with no crossing features returns false for crosses.
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

    // Tests that crossing detection is commutative (a.crosses(b) == b.crosses(a)).
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

    // MARK: - Grid size

    // Validates that `crosses(_:gridSize:)` matches manual pre-snapping.
    @Test
    func crossesWithGridSize() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 1.0001, longitude: 2.0001),
            Coordinate3D(latitude: 4.0001, longitude: 2.0001),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 2.0001, longitude: 1.0001),
            Coordinate3D(latitude: 2.0001, longitude: 4.0001),
        ]))
        let gridSize = 0.001

        let withParam = line1.crosses(line2, gridSize: gridSize)
        let snapped1 = line1.snappedToGrid(tolerance: gridSize)
        let snapped2 = line2.snappedToGrid(tolerance: gridSize)
        let manual = snapped1.crosses(snapped2)
        #expect(withParam == manual)
    }

    // MARK: - Projections

    @Test
    func crossesEPSG3857() throws {
        // Diagonal crossing in EPSG:3857.
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
        ]))
        #expect(line1.crosses(line2))
        #expect(line2.crosses(line1))
    }

    @Test
    func crossesEPSG4978() throws {
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        #expect(line1.crosses(line2))
        #expect(line2.crosses(line1))
    }

    @Test
    func crossesNoSRID() throws {
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
        ]))
        #expect(line1.crosses(line2))
        #expect(line2.crosses(line1))
    }

    @Test
    func crossesMultiPointLineStringEPSG3857() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 2_000.0, y: 2_000.0)]))
        let line = try #require(LineString([
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 1_500.0, y: 1_500.0)]))
        #expect(mp.crosses(line))
    }

    @Test
    func crossesMultiPointLineStringEPSG4978() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 500.0, y: 500.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 2_000.0, y: 2_000.0, z: 0.0, projection: .epsg4978)]))
        let line = try #require(LineString([
            Coordinate3D(x: 500.0, y: 500.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_500.0, y: 1_500.0, z: 0.0, projection: .epsg4978)]))
        #expect(mp.crosses(line))
    }

    @Test
    func crossesLineStringPolygonEPSG3857() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 500.0, y: -500.0),
            Coordinate3D(x: 500.0, y: 1_500.0)]))
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        #expect(line.crosses(polygon))
    }

    @Test
    func crossesLineStringPolygonEPSG4978() async throws {
        let poly4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = poly4326.projected(to: .epsg4978)
        // Line crossing the polygon diagonally
        let line = try #require(LineString([
            Coordinate3D(latitude: -0.5, longitude: 0.5).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.5, longitude: 0.5).projected(to: .epsg4978)]))
        #expect(line.crosses(polygon))
    }

    @Test
    func crossesMultiPointPolygonEPSG3857() throws {
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
        #expect(mp.crosses(polygon))
    }

    @Test
    func crossesMultiPointPolygonEPSG4978() async throws {
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
        #expect(mp.crosses(polygon))
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let line = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 165.0),
            Coordinate3D(latitude: 5.0, longitude: 180.0),
        ]))
        #expect(line.crosses(polygon))
    }

    // MARK: - Empty / degenerate

    @Test
    func singlePointLineStringDoesNotCross() throws {
        let degenerateLine = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 10.0)
        ])
        let crossingLine = try #require(LineString([
            Coordinate3D(latitude: 4.0, longitude: 8.0),
            Coordinate3D(latitude: 6.0, longitude: 12.0),
        ]))
        #expect(degenerateLine.crosses(crossingLine) == false)
        #expect(crossingLine.crosses(degenerateLine) == false)
    }

}

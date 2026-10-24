@testable import GISTools
import Testing

struct PolygonizeTests {

    /// Two separate closed LineStrings form two separate polygons.
    @Test
    func twoSeparateSquares() async throws {
        let square1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let square2 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let multiLine = try #require(MultiLineString([square1, square2]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 2)
    }

    /// A single closed LineString produces one Polygon.
    @Test
    func singleSquare() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let result = line.polygonized()
        #expect(result.features.count == 1)
    }

    /// A closed LineString via the `polygonize()` shortcut.
    @Test
    func polygonizeShortcut() async throws {
        let square = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        var fc = FeatureCollection([Feature(square)])
        fc.polygonize()
        #expect(fc.features.count == 1)
    }

    /// A triangle formed by three connected LineStrings produces one Polygon.
    @Test
    func triangle() async throws {
        let side1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let side2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 2.5, longitude: 5.0),
        ]))
        let side3 = try #require(LineString([
            Coordinate3D(latitude: 2.5, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let multiLine = try #require(MultiLineString([side1, side2, side3]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 1)
    }

    /// Two adjacent squares sharing an edge should produce both squares.
    @Test
    func adjacentSquares() async throws {
        // Left square: (0,0)→(5,0)→(5,5)→(0,5)→(0,0)
        // Right square: (5,0)→(10,0)→(10,5)→(5,5)→(5,0)
        // Shared edge: (5,0)→(5,5)
        let leftSquare = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let rightSquare = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let multiLine = try #require(MultiLineString([leftSquare, rightSquare]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 2)
    }

    /// Empty input produces no polygons.
    @Test
    func emptyInput() async throws {
        let fc = FeatureCollection()
        let result = fc.polygonized()
        #expect(result.features.isEmpty)
    }

    // MARK: - Projections

    /// A closed LineString in EPSG:3857 forms one polygon.
    @Test
    func polygonize3857() async throws {
        let square = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]))
        let multiLine = try #require(MultiLineString([square]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 1)
        let polygon = try #require(result.features[0].geometry as? Polygon)
        #expect(polygon.area > 0.0)
        #expect(polygon.projection == .epsg3857)
    }

    /// A closed LineString in EPSG:4978 forms one polygon.
    @Test
    func polygonize4978() async throws {
        let c00 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let c10 = Coordinate3D(latitude: 0.009, longitude: 0.0).projected(to: .epsg4978)
        let c11 = Coordinate3D(latitude: 0.009, longitude: 0.009).projected(to: .epsg4978)
        let c01 = Coordinate3D(latitude: 0.0, longitude: 0.009).projected(to: .epsg4978)
        let square = try #require(LineString([c00, c10, c11, c01, c00]))
        let multiLine = try #require(MultiLineString([square]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 1)
        let polygon = try #require(result.features[0].geometry as? Polygon)
        #expect(polygon.projection == .epsg4978)
    }


    // Verifies polygonize with noSRID.
    @Test
    func polygonizeNoSRID() async throws {
        let square = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]))
        let result = square.polygonized()
        #expect(result.features.count == 1)
        let polygon = try #require(result.features[0].geometry as? Polygon)
        #expect(polygon.projection == .noSRID)
    }

    /// A square crossing the antimeridian formed by four connected LineStrings.
    /// The square spans lon=179 to -179 across the date line near the equator.
    @Test
    func antimeridianSquare() async throws {
        // A 10°×2° rectangle crossing the date line at the equator.
        // The short path goes across the date line (2° wide at lon ~180).
        let top = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
        ]))
        let right = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: -179.0),
        ]))
        let bottom = try #require(LineString([
            Coordinate3D(latitude: -5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: 179.0),
        ]))
        let left = try #require(LineString([
            Coordinate3D(latitude: -5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
        ]))
        let multiLine = try #require(MultiLineString([top, right, bottom, left]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 1)
        let polygon = try #require(result.features[0].geometry as? Polygon)
        let outerRing = try #require(polygon.outerRing)
        // The rectangle should span ~2° across the date line (short path)
        #expect(abs(outerRing.circumference - (2.0 + 10.0) * 2.0 * 111_000.0) < 50_000.0)
    }

}

// MARK: - Audit regressions

extension PolygonizeTests {

    @Test
    func squareHasCounterClockwiseShell() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let result = line.polygonized()
        let polygon = try #require((result.features.first?.geometry as? Polygon))

        #expect(polygon.outerRing?.isCounterClockwise == true)
    }


    private func squareLine(
        _ minX: Double, _ minY: Double,
        _ maxX: Double, _ maxY: Double,
        projection: Projection,
        clockwise: Bool = false
    ) throws -> LineString {
        var coordinates = [
            Coordinate3D(latitude: minY, longitude: minX),
            Coordinate3D(latitude: minY, longitude: maxX),
            Coordinate3D(latitude: maxY, longitude: maxX),
            Coordinate3D(latitude: maxY, longitude: minX),
        ]
        if projection != .epsg4326 {
            coordinates = coordinates.map { $0.projected(to: projection) }
        }
        if clockwise {
            coordinates.reverse()
        }
        coordinates.append(coordinates[0])
        return try #require(LineString(coordinates))
    }

    /// A dangling spur is recursively pruned and does not become part of the
    /// polygon or create an extra feature.
    @Test
    func danglingSpurIsPruned() throws {
        let square = try squareLine(0.0, 0.0, 5.0, 5.0, projection: .epsg4326)
        let spur = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: -2.0, longitude: -2.0),
        ]))

        let multiLine = try #require(MultiLineString([square, spur]))
        let result = multiLine.polygonized()
        #expect(result.features.count == 1)
        guard let polygon = result.features.first?.geometry as? Polygon else {
            Issue.record("Expected a polygon")
            return
        }
        #expect(polygon.outerRing?.coordinates.count == 5)
    }

    /// A cut edge/bridge between two squares is removed; both faces remain.
    @Test
    func cutEdgeIsPruned() throws {
        let left = try squareLine(0.0, 0.0, 5.0, 5.0, projection: .epsg4326)
        let right = try squareLine(5.0, 0.0, 10.0, 5.0, projection: .epsg4326)
        // The shared side already exists; add a bridge from an interior corner
        // of each square to force cut-edge pruning.
        let bridge = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))

        let multiLine = try #require(MultiLineString([left, right, bridge]))
        let result = multiLine.polygonized()
        #expect(result.features.count == 2)
    }

    /// Duplicate and collinear overlapping edges are noded and deduplicated;
    /// the square must be emitted exactly once.
    @Test
    func collinearDuplicateEdgesProduceOneFace() throws {
        let square = try squareLine(0.0, 0.0, 5.0, 5.0, projection: .epsg4326)
        let duplicateSide = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]))
        let reversedSide = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))

        let multiLine = try #require(MultiLineString([square, duplicateSide, reversedSide]))
        let result = multiLine.polygonized()
        #expect(result.features.count == 1)
        guard let polygon = result.features.first?.geometry as? Polygon else {
            Issue.record("Expected a polygon")
            return
        }
        #expect(polygon.outerRing?.coordinates.count == 5)
    }

    /// A separate inner ring becomes a hole, not a second shell.
    @Test
    func innerRingBecomesHole() throws {
        let outer = try squareLine(0.0, 0.0, 10.0, 10.0, projection: .noSRID)
        let inner = try squareLine(3.0, 3.0, 7.0, 7.0, projection: .noSRID)

        let multiLine = try #require(MultiLineString([outer, inner]))
        let result = multiLine.polygonized()
        #expect(result.features.count == 1)
        guard let polygon = result.features.first?.geometry as? Polygon else {
            Issue.record("Expected a polygon")
            return
        }
        #expect(polygon.outerRing?.isCounterClockwise == true)
        #expect(polygon.innerRings?.count == 1)
        #expect(polygon.innerRings?.first?.isClockwise == true)
        #expect(abs(polygon.area - 84.0) < 0.000001, "Area \(polygon.area) != 84")
    }

    /// Polygonize must be independent of line input order.
    @Test
    func inputOrderDoesNotChangeFaces() throws {
        let sides = [
            try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
            ])),
            try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ])),
            try #require(LineString([
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ])),
            try #require(LineString([
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ])),
        ]

        for order in [sides, sides.reversed(), [sides[2], sides[0], sides[3], sides[1]]] {
            let multiLine = try #require(MultiLineString(order))
            let result = multiLine.polygonized()
            #expect(result.features.count == 1)
            guard let polygon = result.features.first?.geometry as? Polygon else {
                Issue.record("Expected a polygon")
                continue
            }
            #expect(polygon.outerRing?.coordinates.count == 5)
            let expectedArea = 25.0 * 111_000.0 * 111_000.0
            let actualArea = abs(polygon.area)
            #expect(abs(actualArea - expectedArea) < expectedArea * 0.01)
        }
    }

    /// Outer + hole in every supported projection.
    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func holeAcrossProjections(projection: Projection) throws {
        let outer = try squareLine(0.0, 0.0, 10.0, 10.0, projection: projection)
        let inner = try squareLine(3.0, 3.0, 7.0, 7.0, projection: projection)

        let multiLine = try #require(MultiLineString([outer, inner]))
        let result = multiLine.polygonized()
        #expect(result.features.count == 1)
        guard let polygon = result.features.first?.geometry as? Polygon else {
            Issue.record("Expected a polygon")
            return
        }
        #expect(polygon.projection == projection)
        #expect(polygon.innerRings?.count == 1)
    }


}

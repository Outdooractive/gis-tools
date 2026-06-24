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
        let square = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])
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

    /// A closed LineString in EPSG:3857 forms one polygon.
    @Test
    func polygonize3857() async throws {
        let square = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ])
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
        let square = LineString(unchecked: [c00, c10, c11, c01, c00])
        let multiLine = try #require(MultiLineString([square]))
        let result = multiLine.polygonized()

        #expect(result.features.count == 1)
        let polygon = try #require(result.features[0].geometry as? Polygon)
        #expect(polygon.projection == .epsg4978)
    }

    // MARK: - noSRID

    @Test
    func polygonizeNoSRID() async throws {
        let square = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ])
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

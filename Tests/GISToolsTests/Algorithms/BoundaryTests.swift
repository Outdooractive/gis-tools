@testable import GISTools
import Testing

struct BoundaryTests {

    // MARK: - Point

    @Test
    func pointBoundary() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let boundary = point.boundary
        #expect(boundary.geometries.isEmpty)
    }

    // MARK: - MultiPoint

    @Test
    func multiPointBoundary() async throws {
        let multiPoint = MultiPoint(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ])
        let boundary = multiPoint.boundary
        #expect(boundary.geometries.isEmpty)
    }

    // MARK: - LineString

    @Test
    func openLineStringBoundary() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let boundary = line.boundary
        #expect(boundary.coordinates.count == 2)
        #expect(boundary.coordinates[0] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(boundary.coordinates[1] == Coordinate3D(latitude: 2.0, longitude: 2.0))
    }

    @Test
    func closedLineStringBoundary() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let boundary = line.boundary
        #expect(boundary.coordinates.isEmpty)
    }

    // MARK: - MultiLineString

    @Test
    func multiLineStringBoundary() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let multiLine = try #require(MultiLineString([line1, line2]))
        let boundary = multiLine.boundary
        // (0,0) appears once, (2,2) appears once — both are odd
        // (1,1) appears twice (as end of line1 and start of line2) — even
        #expect(boundary.coordinates.count == 2)
        #expect(boundary.coordinates.contains(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        #expect(boundary.coordinates.contains(Coordinate3D(latitude: 2.0, longitude: 2.0)))
    }

    @Test
    func multiLineStringClosedLoop() async throws {
        // A closed loop of 3 segments: all endpoints appear twice (even)
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        let line3 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let multiLine = try #require(MultiLineString([line1, line2, line3]))
        let boundary = multiLine.boundary
        #expect(boundary.coordinates.isEmpty)
    }

    // MARK: - Polygon

    @Test
    func polygonBoundary() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let boundary = try #require(polygon.boundary)
        #expect(boundary.coordinates.first == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(boundary.isClosed)
    }

    // MARK: - MultiPolygon

    @Test
    func multiPolygonBoundary() async throws {
        let poly1 = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let poly2 = try #require(Polygon([
            [
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 5.0, longitude: 3.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 3.0, longitude: 5.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
            ],
        ]))
        let multiPolygon = try #require(MultiPolygon([poly1, poly2]))
        let boundary = try #require(multiPolygon.boundary)
        #expect(boundary.lineStrings.count == 2)
    }

    // MARK: - GeometryCollection

    @Test
    func geometryCollectionEmptyBoundary() async throws {
        let collection = GeometryCollection([])
        #expect(collection.boundary == nil)
    }

    @Test
    func geometryCollectionBoundary() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let collection = GeometryCollection([line, polygon])
        let boundary = try #require(collection.boundary)
        #expect(boundary.geometries.count == 2)
    }

    // MARK: - Feature

    @Test
    func featurePointBoundary() async throws {
        let feature = Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        let boundary = try #require(feature.boundary as? GeometryCollection)
        #expect(boundary.geometries.isEmpty)
    }

    @Test
    func featureLineBoundary() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let feature = Feature(line)
        let boundary = try #require(feature.boundary as? MultiPoint)
        #expect(boundary.coordinates.count == 2)
    }

    // MARK: - FeatureCollection

    @Test
    func featureCollectionBoundary() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 0.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 2.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let fc = FeatureCollection([Feature(line), Feature(polygon)])
        let boundary = try #require(fc.boundary)
        #expect(boundary.geometries.count == 2)
    }

    // MARK: - EPSG:3857

    @Test
    func boundary3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let boundary = try #require(polygon.boundary)
        #expect(boundary.isClosed)
    }

    @Test
    func boundary4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 100_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 100_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]]))
        let boundary = try #require(polygon.boundary)
        #expect(boundary.isClosed)
    }

    // MARK: - Antimeridian

    /// A LineString crossing the antimeridian: boundary is still its two endpoints.
    @Test
    func antimeridianLineString() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
        ]))
        let boundary = line.boundary
        #expect(boundary.coordinates.count == 2)
        #expect(boundary.coordinates[0] == Coordinate3D(latitude: 0.0, longitude: 179.0))
        #expect(boundary.coordinates[1] == Coordinate3D(latitude: 5.0, longitude: -179.0))
    }

    /// A Polygon crossing the antimeridian: boundary is its outer ring.
    @Test
    func antimeridianPolygon() async throws {
        let polygon = Polygon(unchecked: [
            [
                Coordinate3D(latitude: 0.0, longitude: 179.0),
                Coordinate3D(latitude: 5.0, longitude: 179.0),
                Coordinate3D(latitude: 5.0, longitude: -179.0),
                Coordinate3D(latitude: 0.0, longitude: -179.0),
                Coordinate3D(latitude: 0.0, longitude: 179.0),
            ],
        ])
        let boundary = try #require(polygon.boundary)
        #expect(boundary.isClosed)
        #expect(boundary.coordinates.count == 5)
        #expect(boundary.coordinates.first == Coordinate3D(latitude: 0.0, longitude: 179.0))
    }

    /// A closed MultiLineString crossing the antimeridian: shared endpoints cancel out.
    @Test
    func antimeridianMultiLineString() async throws {
        let seg1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
        ]))
        let seg2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]))
        let multiLine = try #require(MultiLineString([seg1, seg2]))
        let boundary = multiLine.boundary
        // Both endpoints appear twice → empty boundary
        #expect(boundary.coordinates.isEmpty)
    }

}

@testable import GISTools
import Testing

struct BooleanConcaveTests {

    // MARK: - Convex polygons — false

    // Triangle is convex.
    @Test
    func triangle() async throws {
        let triangle = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]]))
        #expect(!triangle.isConcave())
    }

    // Square is convex.
    @Test
    func square() async throws {
        let square = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]))
        #expect(!square.isConcave())
    }

    // Convex pentagon is not concave.
    @Test
    func convexPentagon() async throws {
        let pentagon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.5, longitude: 0.5),
            Coordinate3D(latitude: 0.5, longitude: 1.0),
            Coordinate3D(latitude: -0.5, longitude: 0.5),
        ]]))
        #expect(!pentagon.isConcave())
    }

    // MARK: - Concave polygons — true

    // L-shape is concave.
    @Test
    func lShape() async throws {
        let lShape = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
        ]]))
        #expect(lShape.isConcave())
    }

    // Simple concave polygon.
    @Test
    func simpleConcave() async throws {
        let concave = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 3.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 3.0, longitude: 0.0),
        ]]))
        #expect(concave.isConcave())
    }

    // MARK: - MultiPolygon

    // MultiPolygon with all convex polygons.
    @Test
    func multiPolygonAllConvex() async throws {
        let square1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]))
        let square2 = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 2.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([square1, square2]))
        #expect(!multiPolygon.isConcave())
    }

    // MultiPolygon with one concave polygon.
    @Test
    func multiPolygonOneConcave() async throws {
        let square = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]))
        let lShape = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([square, lShape]))
        #expect(multiPolygon.isConcave())
    }

    // MARK: - Feature / FeatureCollection wrapping

    // Concave polygon wrapped in Feature.
    @Test
    func featureWrapping() async throws {
        let lShape = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
        ]]))
        let feature = Feature(lShape)
        #expect(feature.isConcave())
    }

    // FeatureCollection with one concave polygon.
    @Test
    func featureCollectionWrapping() async throws {
        let lShape = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
        ]]))
        let square = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]))
        let fc = FeatureCollection([Feature(lShape), Feature(square)])
        #expect(fc.isConcave())
    }

    // FeatureCollection with all convex polygons.
    @Test
    func featureCollectionAllConvex() async throws {
        let square1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]))
        let square2 = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 2.0),
        ]]))
        let fc = FeatureCollection([Feature(square1), Feature(square2)])
        #expect(!fc.isConcave())
    }

    // MARK: - Grid size

    // Validates that `isConcave(gridSize:)` matches manual pre-snapping.
    @Test
    func concaveWithGridSize() async throws {
        let lShape = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 2.0001),
            Coordinate3D(latitude: 1.0001, longitude: 2.0001),
            Coordinate3D(latitude: 1.0001, longitude: 1.0001),
            Coordinate3D(latitude: 2.0001, longitude: 1.0001),
            Coordinate3D(latitude: 2.0001, longitude: 0.0001),
        ]]))
        let gridSize = 0.001

        let withParam = lShape.isConcave(gridSize: gridSize)
        let snapped = lShape.snappedToGrid(tolerance: gridSize)
        let manual = snapped.isConcave()
        #expect(withParam == manual)
    }

    // MARK: - Projections

    // Concave polygon in EPSG:3857.
    @Test
    func concavePolygon3857() async throws {
        // L-shape concave polygon in 4326, projected to 3857.
        let concave4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon3857 = try #require(Polygon([concave4326.outerRing!.coordinates.map { $0.projected(to: .epsg3857) }]))
        #expect(polygon3857.isConcave())

        // Convex square in 4326, projected to 3857.
        let convex4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon3857b = try #require(Polygon([convex4326.outerRing!.coordinates.map { $0.projected(to: .epsg3857) }]))
        #expect(!polygon3857b.isConcave())
    }

    // Concave polygon in EPSG:4978.
    @Test
    func concavePolygon4978() async throws {
        let concave4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon4978 = try #require(Polygon([concave4326.outerRing!.coordinates.map { $0.projected(to: .epsg4978) }]))
        #expect(polygon4978.isConcave())
    }

    // MARK: - Antimeridian crossing

    // Convex polygon crossing antimeridian.
    @Test
    func convexCrossingAntimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 40.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: 170.0),
        ]]))
        #expect(polygon.crossesAntimeridian)
        #expect(!polygon.isConcave())
    }

    // Concave polygon crossing antimeridian.
    @Test
    func concaveCrossingAntimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 40.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: 170.0),
            Coordinate3D(latitude: 45.0, longitude: 175.0),
            Coordinate3D(latitude: 50.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: 170.0),
        ]]))
        #expect(polygon.crossesAntimeridian)
        #expect(polygon.isConcave())
    }

    // MARK: - Non-polygon geometries — false

    // Point returns false for isConcave.
    @Test
    func pointReturnsFalse() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(!point.isConcave())
    }

    // LineString returns false for isConcave.
    @Test
    func lineStringReturnsFalse() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        #expect(!lineString.isConcave())
    }

}

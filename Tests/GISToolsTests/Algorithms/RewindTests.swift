@testable import GISTools
import Testing

struct RewindTests {

    private static let lineStringClockwise = LineString([
        Coordinate3D(latitude: -20.0, longitude: 122.0),
        Coordinate3D(latitude: -15.0, longitude: 126.0),
        Coordinate3D(latitude: -14.0, longitude: 129.0),
        Coordinate3D(latitude: -15.0, longitude: 134.0),
        Coordinate3D(latitude: -20.0, longitude: 138.0),
        Coordinate3D(latitude: -25.0, longitude: 139.0),
        Coordinate3D(latitude: -30.0, longitude: 134.0),
        Coordinate3D(latitude: -30.0, longitude: 131.0),
        Coordinate3D(latitude: -29.0, longitude: 128.0),
        Coordinate3D(latitude: -27.0, longitude: 124.0),
    ])!

    private static let lineStringCounterClockwise = LineString([
        Coordinate3D(latitude: -27.0, longitude: 124.0),
        Coordinate3D(latitude: -29.0, longitude: 128.0),
        Coordinate3D(latitude: -30.0, longitude: 131.0),
        Coordinate3D(latitude: -30.0, longitude: 134.0),
        Coordinate3D(latitude: -25.0, longitude: 139.0),
        Coordinate3D(latitude: -20.0, longitude: 138.0),
        Coordinate3D(latitude: -15.0, longitude: 134.0),
        Coordinate3D(latitude: -14.0, longitude: 129.0),
        Coordinate3D(latitude: -15.0, longitude: 126.0),
        Coordinate3D(latitude: -20.0, longitude: 122.0),
    ])!

    private static let polygonClockwise = Polygon([[
        Coordinate3D(latitude: 0.0, longitude: 0.0),
        Coordinate3D(latitude: 1.0, longitude: 1.0),
        Coordinate3D(latitude: 0.0, longitude: 1.0),
        Coordinate3D(latitude: 0.0, longitude: 0.0),
    ]])!

    private static let polygonCounterClockwise = Polygon([[
        Coordinate3D(latitude: 0.0, longitude: 0.0),
        Coordinate3D(latitude: 0.0, longitude: 1.0),
        Coordinate3D(latitude: 1.0, longitude: 1.0),
        Coordinate3D(latitude: 0.0, longitude: 0.0),
    ]])!

    // MARK: -

    // Tests that a clockwise LineString remains unchanged after rewinding.
    @Test
    func lineStringClockwise() async throws {
        let lineStringRewinded = RewindTests.lineStringClockwise.rewinded
        #expect(lineStringRewinded == RewindTests.lineStringClockwise)
    }

    // Tests that a counter-clockwise LineString is rewound to clockwise order.
    @Test
    func lineStringCounterClockwise() async throws {
        let lineStringRewinded = RewindTests.lineStringCounterClockwise.rewinded
        #expect(lineStringRewinded.allCoordinates == RewindTests.lineStringClockwise.allCoordinates)
    }

    // Tests that a clockwise Polygon is rewound to counter-clockwise order.
    @Test
    func polygonClockwise() async throws {
        let polygonRewinded = RewindTests.polygonClockwise.rewinded
        #expect(polygonRewinded.allCoordinates == RewindTests.polygonCounterClockwise.allCoordinates)
    }

    // Tests that a counter-clockwise Polygon remains unchanged after rewinding.
    @Test
    func polygonCounterClockwise() async throws {
        let polygonRewinded = RewindTests.polygonCounterClockwise.rewinded
        #expect(polygonRewinded == RewindTests.polygonCounterClockwise)
    }

    // Tests rewinding the geometry inside a Feature.
    @Test
    func feature() async throws {
        let featureRewinded = Feature(RewindTests.lineStringCounterClockwise).rewinded
        let result = Feature(RewindTests.lineStringClockwise)
        #expect(featureRewinded == result)
    }

    // Tests rewinding all geometries within a FeatureCollection.
    @Test
    func featureCollection() async throws {
        let featureCollectionRewinded = FeatureCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringCounterClockwise,
            RewindTests.polygonClockwise,
            RewindTests.polygonCounterClockwise,
        ]).rewinded
        let result = FeatureCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringClockwise,
            RewindTests.polygonCounterClockwise,
            RewindTests.polygonCounterClockwise,
        ])
        #expect(featureCollectionRewinded == result)
    }

    // Tests rewinding all geometries within a GeometryCollection.
    @Test
    func geometryCollection() async throws {
        let geometryCollectionRewinded = GeometryCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringCounterClockwise,
            RewindTests.polygonClockwise,
            RewindTests.polygonCounterClockwise,
        ]).rewinded
        let result = GeometryCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringClockwise,
            RewindTests.polygonCounterClockwise,
            RewindTests.polygonCounterClockwise,
        ])
        #expect(geometryCollectionRewinded == result)
    }

    // MARK: - EPSG:3857

    @Test
    func rewind3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let rewinded = polygon.rewinded
        #expect(rewinded.outerRing?.coordinates.count == 5)
        #expect(rewinded.projection == .epsg3857)
    }

    @Test
    func rewindNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let rewinded = polygon.rewinded
        #expect(rewinded.outerRing?.coordinates.count == 5)
        #expect(rewinded.projection == .noSRID)
    }

    // MARK: - EPSG:4978

    @Test
    func rewind4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
        ]]))
        let rewinded = polygon.rewinded
        #expect(rewinded.outerRing?.coordinates.count == 5)
        #expect(rewinded.projection == .epsg4978)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        // Outer ring should be clockwise (winding inward)
        let ring = try #require(polygon.outerRing)
        #expect(ring.isClockwise)

        let rewinded = polygon.rewinded
        // After rewinding, the ring should be counter-clockwise
        let rewindedRing = try #require(rewinded.outerRing)
        #expect(!rewindedRing.isClockwise)
        #expect(rewinded.outerRing?.coordinates.count == 5)
        #expect(rewinded.projection == polygon.projection)
    }

}

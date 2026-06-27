@testable import GISTools
import Testing

struct FlipTests {

    // Validates flipping a Point swaps latitude and longitude.
    @Test
    func flipPoint() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let flipped = point.flipped()
        #expect(flipped.coordinate.latitude == 20.0)
        #expect(flipped.coordinate.longitude == 10.0)
    }

    // Validates flipping a LineString swaps all coordinates.
    @Test
    func flipLineString() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 3.0),
        ]))
        let flipped = line.flipped()
        #expect(flipped.coordinates[0].latitude == 1.0)
        #expect(flipped.coordinates[0].longitude == 0.0)
        #expect(flipped.coordinates[1].latitude == 3.0)
        #expect(flipped.coordinates[1].longitude == 2.0)
    }

    // Validates flipping a MultiPolygon swaps all coordinates.
    @Test
    func flipMultiPolygon() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 3.0),
            Coordinate3D(latitude: 4.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        let poly = try #require(Polygon([ring]))
        let multi = try #require(MultiPolygon([poly]))
        let flipped = multi.flipped()
        let flippedRing = flipped.polygons[0].rings[0]
        #expect(flippedRing.coordinates[0].latitude == 1.0)
        #expect(flippedRing.coordinates[0].longitude == 0.0)
    }

    // Validates the mutating flip() method.
    @Test
    func flipMutating() async throws {
        var point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        point.flip()
        #expect(point.coordinate.latitude == 20.0)
        #expect(point.coordinate.longitude == 10.0)
    }

    // MARK: - Altitude / Z

    // Tests that flipping preserves altitude and M values.
    @Test
    func flipPointPreservesAltitudeAndM() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0, altitude: 500.0, m: 42.0))
        let flipped = point.flipped()
        #expect(flipped.coordinate.latitude == 20.0)
        #expect(flipped.coordinate.longitude == 10.0)
        #expect(flipped.coordinate.altitude == 500.0)
        #expect(flipped.coordinate.m == 42.0)
    }

    // MARK: - Feature / FeatureCollection

    // Tests flipping a Feature preserves properties.
    @Test
    func flipFeature() async throws {
        var feature = Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        feature.properties = ["name": "test"]
        let flipped = feature.flipped()
        let flippedPoint = try #require(flipped.geometry as? Point)
        #expect(flippedPoint.coordinate.latitude == 20.0)
        #expect(flippedPoint.coordinate.longitude == 10.0)
        #expect(flipped.properties["name"] as? String == "test")
    }

    // MARK: - Projections

    // Tests flipping in EPSG:3857.
    @Test
    func flip3857() async throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 200_000.0, y: 0.0),
        ]))
        let flipped = line.flipped()
        #expect(flipped.coordinates.count == 3)
    }

    // Validates flip in EPSG:4978.
    @Test
    func flip4978() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 2.0, longitude: 0.0).projected(to: .epsg4978),
        ]))
        let flipped = line.flipped()
        #expect(flipped.coordinates.count == 3)
    }

    // Validates flip in noSRID.
    @Test
    func flipNoSRID() throws {
        let point = Point(Coordinate3D(x: 10.0, y: 20.0, projection: .noSRID))
        let flipped = point.flipped()
        #expect(flipped.coordinate.projection == .noSRID)
        #expect(flipped.coordinate.x == 20.0)
        #expect(flipped.coordinate.y == 10.0)
    }

    // Validates flip preserves the input projection.
    @Test
    func flipPointPreservesProjection() throws {
        let point3857 = Point(Coordinate3D(x: 10.0, y: 20.0))
        #expect(point3857.flipped().coordinate.projection == .epsg3857)

        let point4978 = Point(Coordinate3D(x: 10.0, y: 20.0, z: 0.0, projection: .epsg4978))
        #expect(point4978.flipped().coordinate.projection == .epsg4978)
    }

}

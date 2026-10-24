@testable import GISTools
import Testing

struct TruncateTests {

    // Validates coordinate precision truncation and altitude removal for a Point.
    @Test
    func point() async throws {
        let point = Point(
            Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
            calculateBoundingBox: true)

        let truncated = point.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinate.latitude == 123.46)
        #expect(truncated.coordinate.longitude == 123.46)
        #expect(truncated.coordinate.altitude == nil)
        #expect(truncated.boundingBox != nil)
    }

    // Validates truncation for MultiPoint.
    @Test
    func multiPoint() async throws {
        let multiPoint = try #require(MultiPoint(
            [
                Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
                Coordinate3D(latitude: 9.1234567, longitude: 9.1234567),
            ],
            calculateBoundingBox: true))

        let truncated = multiPoint.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinates[0].latitude == 123.46)
        #expect(truncated.coordinates[0].longitude == 123.46)
        #expect(truncated.coordinates[0].altitude == nil)
        #expect(truncated.coordinates[1].latitude == 9.12)
        #expect(truncated.coordinates[1].longitude == 9.12)
        #expect(truncated.coordinates[1].altitude == nil)
        #expect(truncated.boundingBox != nil)
    }

    // Validates truncation for LineString.
    @Test
    func lineString() async throws {
        let lineString = try #require(LineString(
            [
                Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
                Coordinate3D(latitude: 9.1234567, longitude: 9.1234567),
            ],
            calculateBoundingBox: true))

        let truncated = lineString.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinates[0].latitude == 123.46)
        #expect(truncated.coordinates[0].longitude == 123.46)
        #expect(truncated.coordinates[0].altitude == nil)
        #expect(truncated.coordinates[1].latitude == 9.12)
        #expect(truncated.coordinates[1].longitude == 9.12)
        #expect(truncated.coordinates[1].altitude == nil)
        #expect(truncated.boundingBox != nil)
    }

    // Validates truncation for MultiLineString.
    @Test
    func multiLineString() async throws {
        let multiLineString = try #require(MultiLineString(
            [
                [
                    Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
                    Coordinate3D(latitude: 1.0, longitude: 101.0, altitude: 100.0),
                ],
                [
                    Coordinate3D(latitude: 9.1234567, longitude: 9.1234567),
                    Coordinate3D(latitude: 3.0, longitude: 103.0),
                ],
            ],
            calculateBoundingBox: true))

        let truncated = multiLineString.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinates[0][0].latitude == 123.46)
        #expect(truncated.coordinates[0][0].longitude == 123.46)
        #expect(truncated.coordinates[0][0].altitude == nil)
        #expect(truncated.coordinates[0][1].latitude == 1.0)
        #expect(truncated.coordinates[0][1].longitude == 101.0)
        #expect(truncated.coordinates[0][1].altitude == nil)
        #expect(truncated.coordinates[1][0].latitude == 9.12)
        #expect(truncated.coordinates[1][0].longitude == 9.12)
        #expect(truncated.coordinates[1][0].altitude == nil)
        #expect(truncated.boundingBox != nil)
    }

    // MARK: - Projections

    // Validates truncation in EPSG:3857.
    @Test
    func truncate3857() async throws {
        let lineString = try #require(LineString(
            [
                Coordinate3D(x: 100_000.123456, y: 200_000.654321, projection: .epsg3857),
                Coordinate3D(x: 300_000.987654, y: 400_000.111111, projection: .epsg3857),
            ],
            calculateBoundingBox: true))

        let truncated = lineString.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinates[0].x == 100_000.12)
        #expect(truncated.coordinates[0].y == 200_000.65)
        #expect(truncated.coordinates[1].x == 300_000.99)
        #expect(truncated.coordinates[1].y == 400_000.11)
        #expect(truncated.boundingBox != nil)
    }

    // Validates truncation in EPSG:4978.
    @Test
    func truncate4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 100_000.123456, y: 200_000.654321, projection: .epsg4978),
            Coordinate3D(x: 300_000.987654, y: 400_000.111111, projection: .epsg4978),
        ]))
        let truncated = lineString.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinates[0].x == 100_000.12)
        #expect(truncated.coordinates[0].y == 200_000.65)
    }

    // Validates truncation in noSRID.
    @Test
    func truncateNoSRID() async throws {
        let lineString = try #require(LineString(
            [
                Coordinate3D(x: 100_000.123456, y: 200_000.654321, projection: .noSRID),
                Coordinate3D(x: 300_000.987654, y: 400_000.111111, projection: .noSRID),
            ],
            calculateBoundingBox: true))

        let truncated = lineString.truncated(precision: 2, removeAltitude: true)
        #expect(truncated.coordinates[0].x == 100_000.12)
        #expect(truncated.coordinates[0].y == 200_000.65)
        #expect(truncated.coordinates[1].x == 300_000.99)
        #expect(truncated.coordinates[1].y == 400_000.11)
    }


    // MARK: - Audit coverage

    @Test
    func polygonMultiPolygonGeometryCollectionAndRemoveM() throws {
        let ring: [Coordinate3D] = [
            Coordinate3D(latitude: 0.1234567, longitude: 0.1234567, altitude: 1.234567, m: 9.87654),
            Coordinate3D(latitude: 0.1234567, longitude: 1.9876543, altitude: 2.345678, m: 9.87654),
            Coordinate3D(latitude: 1.9876543, longitude: 1.9876543, altitude: 3.456789, m: 9.87654),
            Coordinate3D(latitude: 0.1234567, longitude: 0.1234567, altitude: 1.234567, m: 9.87654),
        ]
        let polygon = try #require(Polygon([ring], calculateBoundingBox: true))
        let truncatedPolygon = polygon.truncated(precision: 2, removeM: true)
        #expect(truncatedPolygon.coordinates[0][0].x == 0.12)
        #expect(truncatedPolygon.coordinates[0][0].m == nil)
        #expect(truncatedPolygon.boundingBox?.southWest.x == 0.12)
        #expect(truncatedPolygon.boundingBox != nil)

        let multiPolygon = try #require(MultiPolygon([polygon]))
        let truncatedMulti = multiPolygon.truncated(precision: 2, removeM: true)
        #expect(truncatedMulti.polygons.count == 1)
        #expect(truncatedMulti.polygons[0].coordinates[0][0].m == nil)

        let collection = GeometryCollection([Point(ring[0]), polygon])
        let truncatedCollection = collection.truncated(precision: 2, removeM: true)
        #expect(truncatedCollection.geometries.count == 2)

        let feature = Feature(polygon, id: .string("p"), properties: ["name": "P"], calculateBoundingBox: true)
        let truncatedFeature = feature.truncated(precision: 2, removeM: true)
        #expect(truncatedFeature.id == .string("p"))
        #expect(truncatedFeature.boundingBox != nil)

        let featureCollection = FeatureCollection([feature])
        let truncatedFC = featureCollection.truncated(precision: 2, removeM: true)
        #expect(truncatedFC.features.count == 1)
    }


}

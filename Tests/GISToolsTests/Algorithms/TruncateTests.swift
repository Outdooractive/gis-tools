@testable import GISTools
import Testing

struct TruncateTests {

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

    @Test
    func polygon() async throws {
        // TODO:
    }

    @Test
    func multiPolygon() async throws {
        // TODO:
    }

    @Test
    func geometryCollection() async throws {
        // TODO:
    }

    @Test
    func feature() async throws {
        // TODO:
    }

    @Test
    func featureCollection() async throws {
        // TODO:
    }

}

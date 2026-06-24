@testable import GISTools
import Testing

struct TransformTranslateTests {

    // Validates translating a point east and west using rhumb distance.
    @Test
    func translatePointEastWest() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0))
        let result1 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let result2 = Point(Coordinate3D(latitude: 10.0, longitude: -10.0))

        let distance = point.coordinate.rhumbDistance(from: result1.coordinate)
        let translated1 = point.translated(distance: distance, direction: 90.0)
        let translated2 = point.translated(distance: distance, direction: 270.0)

        #expect(translated1 == result1)
        #expect(translated2 == result2)
    }

    // Validates translating a point west using a negative direction.
    @Test
    func translatePointNegativeDirection() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0))
        let result = Point(Coordinate3D(latitude: 10.0, longitude: -10.0))

        let distance = point.coordinate.rhumbDistance(from: result.coordinate)
        let translated = point.translated(distance: distance, direction: -90.0)

        #expect(translated == result)
    }

    // Validates that translating with direction 0 (north) changes latitude.
    @Test
    func translatePointNorth() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0))
        let distance = 111_319.5  // ~1 degree at equator
        let translated = point.translated(distance: distance, direction: 0.0)

        #expect(translated.coordinate.latitude > 10.0)
        #expect(abs(translated.coordinate.longitude) < 0.001)
    }

    // Validates translating a LineString.
    @Test
    func translateLineString() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let distance = 111_319.5  // ~1 degree at equator
        let translated = line.translated(distance: distance, direction: 90.0)

        let coords = translated.allCoordinates
        #expect(coords.count == 2)
        #expect(abs(coords[0].longitude - 1.0) < 0.01)
        #expect(abs(coords[1].longitude - 1.0) < 0.01)
    }

    // Validates translating a Polygon.
    @Test
    func translatePolygon() async throws {
        let polygon = try #require(Polygon([
            [Coordinate3D(latitude: 0.0, longitude: 0.0),
             Coordinate3D(latitude: 0.0, longitude: 1.0),
             Coordinate3D(latitude: 1.0, longitude: 1.0),
             Coordinate3D(latitude: 0.0, longitude: 0.0)],
        ]))
        let distance = 111_319.5  // ~1 degree at equator
        let translated = polygon.translated(distance: distance, direction: 90.0)

        let coords = translated.allCoordinates
        for coord in coords {
            #expect(abs(coord.longitude - 1.0) < 0.01 || abs(coord.longitude - 2.0) < 0.01)
        }
    }

    // Validates translating a MultiPoint.
    @Test
    func translateMultiPoint() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let distance = 111_319.5  // ~1 degree at equator
        let translated = multiPoint.translated(distance: distance, direction: 90.0)

        let coords = translated.allCoordinates
        #expect(coords.count == 2)
        #expect(abs(coords[0].longitude - 1.0) < 0.01)
        #expect(abs(coords[1].longitude - 2.0) < 0.01)
    }

    // Validates the mutating translate method.
    @Test
    func translateMutating() async throws {
        var point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0))
        let result = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let distance = point.coordinate.rhumbDistance(from: result.coordinate)

        point.translate(distance: distance, direction: 90.0)

        #expect(point == result)
    }

    // Validates translating a point east with an altitude adjustment.
    @Test
    func translateAltitude() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 500.0))
        let result = Point(Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 750.0))

        let distance = point.coordinate.rhumbDistance(from: result.coordinate)
        let translated = point.translated(distance: distance, direction: 90.0, zTranslation: 250.0)

        #expect(translated == result)
    }

    // Validates that zero distance returns the original geometry unchanged.
    @Test
    func translateZeroDistance() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let translated = point.translated(distance: 0.0, direction: 90.0)
        #expect(translated == point)
    }

    // Validates that zero translation with only zTranslation still moves vertically.
    @Test
    func translateOnlyZ() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0, altitude: 500.0))
        let translated = point.translated(distance: 0.0, direction: 0.0, zTranslation: 100.0)
        #expect(translated.coordinate.altitude == 600.0)
    }

    // Validates translating a Feature with properties.
    @Test
    func translateFeature() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let feature = Feature(line)
        let distance = 111_319.5
        let translated = feature.translated(distance: distance, direction: 90.0)

        #expect(translated.geometry is LineString)
        if let translatedLine = translated.geometry as? LineString {
            let coords = translatedLine.allCoordinates
            #expect(abs(coords[0].longitude - 1.0) < 0.01)
        }
    }

    // MARK: - EPSG:3857

    @Test
    func transformTranslate3857() async throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
        ]))
        let result = line.translated(distance: 500.0, direction: 90.0)
        #expect(result.allCoordinates.count == 2)
        #expect(result.projection == .epsg3857)
    }

    // MARK: - EPSG:4978

    @Test
    func transformTranslate4978() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.009, longitude: 0.009).projected(to: .epsg4978),
        ]))
        let result = line.translated(distance: 500.0, direction: 90.0)
        #expect(result.allCoordinates.count == 2)
        #expect(result.projection == .epsg4978)
    }

    // MARK: - noSRID

    @Test
    func transformTranslateNoSRID() async throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let result = line.translated(distance: 500.0, direction: 90.0)
        #expect(result.allCoordinates.count == 2)
        #expect(result.projection == .noSRID)
    }

    @Test
    func antimeridian() async throws {
        // coordinates straddling the date line
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0)
        ]]))
        let result = polygon.translated(distance: 1000.0, direction: 90.0)
        #expect(result != polygon)
        for coord in result.allCoordinates {
            #expect(abs(coord.longitude) > 150.0)
        }
    }

}

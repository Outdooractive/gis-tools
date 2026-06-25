import Foundation
@testable import GISTools
import Testing

struct GreatCircleTests {

    // Validates a great circle line between two points in the same hemisphere produces a LineString with 100 coordinates.
    @Test
    func greatCircleSameHemisphere() async throws {
        let start = Coordinate3D(latitude: 48.0, longitude: -122.0)
        let end = Coordinate3D(latitude: 39.0, longitude: -77.0)

        let result = start.greatCircle(to: end)
        #expect(result is LineString)

        let ls = result as! LineString
        #expect(ls.coordinates.count == 100)
        #expect(ls.coordinates.first == start)
        #expect(ls.coordinates.last == end)
    }

    // Validates a great circle with a custom number of waypoints produces the expected coordinate count.
    @Test
    func greatCircleCustomNpoints() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let end = Coordinate3D(latitude: 10.0, longitude: 10.0)

        let result = start.greatCircle(to: end, npoints: 10)
        #expect(result is LineString)

        let ls = result as! LineString
        #expect(ls.coordinates.count == 10)
    }

    // Validates a great circle along the equator keeps all points near the equator.
    @Test
    func greatCircleEquator() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let end = Coordinate3D(latitude: 0.0, longitude: 180.0)

        let result = start.greatCircle(to: end, npoints: 50)
        #expect(result is LineString)

        let ls = result as! LineString
        for coord in ls.coordinates {
            #expect(abs(coord.latitude) < 1.0)
        }
    }

    // Validates a great circle from north to south along the prime meridian keeps longitude near zero.
    @Test
    func greatCircleNorthSouth() async throws {
        let start = Coordinate3D(latitude: 80.0, longitude: 0.0)
        let end = Coordinate3D(latitude: -80.0, longitude: 0.0)

        let result = start.greatCircle(to: end, npoints: 50)
        #expect(result is LineString)

        let ls = result as! LineString
        for coord in ls.coordinates {
            #expect(abs(coord.longitude) < 1.0)
        }
    }

    // MARK: - Projections

    @Test
    func greatCircle3857() async throws {
        let start = Coordinate3D(x: 0.0, y: 0.0)
        let end = Coordinate3D(x: 111_319.5, y: 111_319.5)
        let result = start.greatCircle(to: end)
        #expect(result is LineString)
        if let line = result as? LineString {
            #expect(line.coordinates[0].projection == .epsg4326)
        }
    }

    // Validates great circle with EPSG:4978 input (result in 4326).
    @Test
    func greatCircle4978() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let end = Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978)
        let result = start.greatCircle(to: end)
        #expect(result is LineString)
    }

    // Validates great circle with noSRID input (result in 4326).
    @Test
    func greatCircleNoSRID() async throws {
        let start = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let end = Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID)
        let result = start.greatCircle(to: end)
        #expect(result is LineString)
        if let line = result as? LineString {
            #expect(line.projection == .epsg4326)
        }
    }

    // MARK: - Antimeridian

    // Validates a great circle crossing the antimeridian produces a MultiLineString.
    @Test
    func greatCircleCrossingAntimeridian() async throws {
        let start = Coordinate3D(latitude: 45.0, longitude: 170.0)
        let end = Coordinate3D(latitude: 45.0, longitude: -170.0)

        let result = start.greatCircle(to: end)
        #expect(result is MultiLineString)
    }

    // MARK: - Edge cases

    // Validates a great circle from a point to itself returns a LineString with all identical coordinates.
    @Test
    func greatCircleSamePoint() async throws {
        let point = Coordinate3D(latitude: 40.0, longitude: -73.0)
        let result = point.greatCircle(to: point, npoints: 5)

        #expect(result is LineString)
        let ls = result as! LineString
        #expect(ls.coordinates.count == 5)
        for coord in ls.coordinates {
            #expect(coord == point)
        }
    }

    // Validates requesting fewer than 2 waypoints falls back to a 2-point LineString.
    @Test
    func greatCircleMinPoints() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let end = Coordinate3D(latitude: 10.0, longitude: 10.0)

        let result = start.greatCircle(to: end, npoints: 1)
        #expect(result is LineString)
        let ls = result as! LineString
        #expect(ls.coordinates.count == 2)
    }

}

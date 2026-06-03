import Foundation
@testable import GISTools
import Testing

struct GreatCircleTests {

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

    @Test
    func greatCircleCrossingAntimeridian() async throws {
        let start = Coordinate3D(latitude: 45.0, longitude: 170.0)
        let end = Coordinate3D(latitude: 45.0, longitude: -170.0)

        let result = start.greatCircle(to: end)
        // Should be a MultiLineString (crosses the date line)
        #expect(result is MultiLineString)
    }

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

    @Test
    func greatCircleCustomNpoints() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let end = Coordinate3D(latitude: 10.0, longitude: 10.0)

        let result = start.greatCircle(to: end, npoints: 10)
        #expect(result is LineString)

        let ls = result as! LineString
        #expect(ls.coordinates.count == 10)
    }

    @Test
    func greatCircleEquator() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let end = Coordinate3D(latitude: 0.0, longitude: 180.0)

        let result = start.greatCircle(to: end, npoints: 50)
        #expect(result is LineString)

        let ls = result as! LineString
        // All points should be near the equator
        for coord in ls.coordinates {
            #expect(abs(coord.latitude) < 1.0)
        }
    }

    @Test
    func greatCircleNorthSouth() async throws {
        let start = Coordinate3D(latitude: 80.0, longitude: 0.0)
        let end = Coordinate3D(latitude: -80.0, longitude: 0.0)

        let result = start.greatCircle(to: end, npoints: 50)
        #expect(result is LineString)

        let ls = result as! LineString
        // Longitude should stay near 0
        for coord in ls.coordinates {
            #expect(abs(coord.longitude) < 1.0)
        }
    }

    @Test
    func greatCircleMinPoints() async throws {
        let start = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let end = Coordinate3D(latitude: 10.0, longitude: 10.0)

        let result = start.greatCircle(to: end, npoints: 1)
        // Falls back to a 2-point line
        #expect(result is LineString)
        let ls = result as! LineString
        #expect(ls.coordinates.count == 2)
    }

}

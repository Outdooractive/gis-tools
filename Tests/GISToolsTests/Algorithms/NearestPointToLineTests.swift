import Foundation
@testable import GISTools
import Testing

struct NearestPointToLineTests {

    // Verifies that the nearest coordinate to a line is selected from a list of candidates.
    @Test
    func nearestCoordinateFrom() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let candidates = [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]
        let result = try #require(ls.nearestCoordinate(from: candidates))
        // (0, 1) is closest to the line (which runs along lon=0)
        #expect(result.coordinate == Coordinate3D(latitude: 0.0, longitude: 1.0))
    }

    // Verifies that the nearest point with distance to a line is selected from a list of candidate points.
    @Test
    func nearestPointAndDistance() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let candidates = [
            Point(Coordinate3D(latitude: 5.0, longitude: 5.0)),
            Point(Coordinate3D(latitude: 0.0, longitude: 2.0)),
        ]
        let result = try #require(ls.nearestPointAndDistance(from: candidates))
        #expect(result.point.coordinate == Coordinate3D(latitude: 0.0, longitude: 2.0))
    }

    // Verifies that an empty candidate list returns nil when querying the nearest coordinate.
    @Test
    func nearestCoordinateFromEmpty() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        #expect(ls.nearestCoordinate(from: []) == nil)
    }

    // MARK: - Projections

    // Verifies nearest coordinate to a line in EPSG:3857.
    @Test
    func nearestCoordinateFrom3857() async throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
        ]))
        let candidates = [
            Coordinate3D(x: 50_000.0, y: 50_000.0),
            Coordinate3D(x: 0.0, y: 10_000.0),
        ]
        let result = try #require(ls.nearestCoordinate(from: candidates))
        #expect(result.coordinate == Coordinate3D(x: 0.0, y: 10_000.0))
    }

    // Verifies nearest coordinate to a line in EPSG:4978.
    @Test
    func nearestCoordinateFrom4978() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.09).projected(to: .epsg4978),
        ]))
        let candidates = [
            Coordinate3D(latitude: 0.045, longitude: 0.045).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.009).projected(to: .epsg4978),
        ]
        let result = try #require(ls.nearestCoordinate(from: candidates))
        #expect(result.coordinate.projection == .epsg4978)
        #expect(result.distance >= 0.0)
    }

    // Verifies nearest coordinate to a line with noSRID.
    @Test
    func nearestCoordinateFromNoSRID() async throws {
        let ls = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
        ]))
        let candidates = [
            Coordinate3D(x: 50.0, y: 50.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
        ]
        let result = try #require(ls.nearestCoordinate(from: candidates))
        #expect(result.coordinate == Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID))
        #expect(result.coordinate.projection == .noSRID)
    }

    // MARK: - Antimeridian

    // Verifies nearest coordinate on a line near the antimeridian.
    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let point = Coordinate3D(latitude: 5.0, longitude: 175.0)
        let result = try #require(lineString.nearestCoordinateOnLine(from: point))
        #expect(result.distance > 0.0)
        #expect(result.coordinate.latitude.isFinite)
        #expect(result.coordinate.longitude.isFinite)
    }

}

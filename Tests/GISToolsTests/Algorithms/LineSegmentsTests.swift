@testable import GISTools
import Testing

struct LineSegmentsTests {

    // Tests that a line string is correctly decomposed into its constituent line segments with proper indices.
    @Test
    func lineSegments() async throws {
        let coordinates = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let lineSegments = [
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 0.0),
                        second: Coordinate3D(latitude: 10.0, longitude: 0.0)),
            LineSegment(first: Coordinate3D(latitude: 10.0, longitude: 0.0),
                        second: Coordinate3D(latitude: 10.0, longitude: 10.0)),
            LineSegment(first: Coordinate3D(latitude: 10.0, longitude: 10.0),
                        second: Coordinate3D(latitude: 0.0, longitude: 10.0)),
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 10.0),
                        second: Coordinate3D(latitude: 0.0, longitude: 0.0)),
        ]
        let lineString = try #require(LineString(coordinates))

        #expect(lineString.lineSegments == lineSegments)
        #expect(lineString.lineSegments.map(\.index) == [0, 1, 2, 3])
    }

    // MARK: - Projections

    @Test
    func lineSegments3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 200_000.0, y: 0.0),
        ]))
        let segments = lineString.lineSegments
        #expect(segments.count == 2)
        #expect(segments[0].first == Coordinate3D(x: 0.0, y: 0.0))
    }

    // Validates line segment decomposition in EPSG:4978.
    @Test
    func lineSegments4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 10_000.0, y: 10_000.0, z: 0.0, projection: .epsg4978),
        ]))
        let segments = lineString.lineSegments
        #expect(segments.count == 1)
    }

    // Validates line segment decomposition in noSRID.
    @Test
    func lineSegmentsNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        #expect(lineString.lineSegments.count == 2)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let segments = lineString.lineSegments
        #expect(segments.count > 0)
        for segment in segments {
            #expect(segment.first.longitude >= 170.0)
            #expect(segment.second.longitude <= 179.0)
        }
    }

}

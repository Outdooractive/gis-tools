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

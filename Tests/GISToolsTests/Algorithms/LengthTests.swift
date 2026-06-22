#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct LengthTests {

    // Tests that the haversine distance between two coordinates is calculated correctly.
    @Test
    func length() async throws {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedLength: CLLocationDistance = 97129.22118967835

        let lineSegment = LineSegment(
            first: coordinate1,
            second: coordinate2,
            index: 0)

        #expect(abs(lineSegment.length - expectedLength) < 0.000001)
        #expect(lineSegment.index == 0)
    }

    // MARK: - Projection tests

    // Verifies segment length for EPSG:3857 (Euclidean in projected meters).
    @Test
    func lengthSegment3857() throws {
        let c1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let c2 = Coordinate3D(latitude: 39.123, longitude: -75.534)

        let segment = LineSegment(
            first: c1.projected(to: .epsg3857),
            second: c2.projected(to: .epsg3857),
            index: 0)
        // 3857 distance is Euclidean in projected meters (Mercator-distorted at mid-latitudes)
        #expect(segment.length > 0.0)
        #expect(segment.length.isFinite)
        #expect(segment.index == 0)
    }

    // Verifies segment length for EPSG:4978 (ECEF straight-line 3D distance).
    @Test
    func lengthSegment4978() throws {
        let c1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let c2 = Coordinate3D(latitude: 39.123, longitude: -75.534)

        let segment = LineSegment(
            first: c1.projected(to: .epsg4978),
            second: c2.projected(to: .epsg4978),
            index: 0)
        // 4978 ECEF distance is straight-line through space (shorter than surface distance)
        #expect(segment.length > 0.0)
        #expect(segment.length.isFinite)
    }

    // Verifies LineString length in EPSG:3857.
    @Test
    func lengthLineString3857() throws {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: 10.0).projected(to: .epsg3857),
        ])
        let length = line.length
        #expect(length > 1_000_000.0)
        #expect(length < 1_200_000.0)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        #expect(lineString.length > 2_000_000.0 && lineString.length < 2_500_000.0)
    }

}

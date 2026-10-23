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

    // MARK: - Projections

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
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: 10.0).projected(to: .epsg3857),
        ]))
        let length = line.length
        #expect(abs(length - 1_113_194.9079327357) < 0.001)
    }

    // MARK: - Antimeridian

    // Tests length calculation across the antimeridian.
    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        #expect(abs(lineString.length - 2_223_901.604670658) < 0.001)
    }

}

    // MARK: - Unit conversion

    // Converts segment and geometry lengths through GISTool.convert.
    @Test
    func lengthInUnits() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 0.0, longitude: 1.0))

        let kilometers = try #require(segment.length(in: .kilometers))
        let miles = try #require(segment.length(in: .miles))
        #expect(abs(kilometers - (segment.length / 1_000.0)) < 0.000001)
        #expect(abs(miles - GISTool.convert(length: segment.length, from: .meters, to: .miles)!) < 0.000001)
        #expect(segment.length(in: .acres) == nil)

        let lineString = try #require(LineString([segment.first, segment.second]))
        #expect(abs(try #require(lineString.length(in: .kilometers)) - (lineString.length / 1_000.0)) < 0.000001)

        let polygon = try #require(Polygon([[
            segment.first,
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            segment.first,
        ]]))
        #expect(abs(try #require(polygon.length(in: .kilometers)) - (polygon.length / 1_000.0)) < 0.000001)
        let degrees = GISTool.convert(length: polygon.length, from: .meters, to: .degrees)!
        #expect(abs(try #require(polygon.length(in: .degrees)) - degrees) < 0.000001)
    }

    // Length conversion preserves the receiver's projection semantics.
    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func lengthInUnitsAcrossProjections(projection: Projection) throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: projection),
            Coordinate3D(x: 10.0, y: 0.0, projection: projection),
        ]))

        if projection == .noSRID {
            #expect(lineString.length(in: .meters) == nil)
            #expect(lineString.length(in: .kilometers) == nil)
        }
        else {
            #expect(abs(try #require(lineString.length(in: .meters)) - lineString.length) < 0.000001)
            #expect(abs(try #require(lineString.length(in: .kilometers)) - (lineString.length / 1_000.0)) < 0.000001)
        }
    }

// MARK: - Audit regressions

extension LengthTests {

    @Test
    func planarAntimeridianLengthIsShort() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg3857),
        ]))

        #expect(abs(line.length - 2_226_389.8158654715) < 0.001)
    }

    @Test
    func noSRIDLengthUnitsAreUndefined() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]))

        #expect(line.length == 10.0)
        #expect(line.length(in: .meters) == nil)
        #expect(line.length(in: .kilometers) == nil)
    }

}

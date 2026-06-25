#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct LineOffsetTests {

    // MARK: - Horizontal line

    @Test
    func lineOffsetHorizontal() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
        ]))
        let offset = try #require(line.offset(by: 50_000))

        // 50 km offset right (south) of a horizontal line at equator
        #expect(abs(offset.coordinates[0].longitude - 10.0) < 0.001)
        #expect(abs(offset.coordinates[0].latitude - (-0.4497)) < 0.001)
        #expect(abs(offset.coordinates[1].longitude - 20.0) < 0.001)
        #expect(abs(offset.coordinates[1].latitude - (-0.4497)) < 0.001)
    }

    // MARK: - Vertical single segment

    @Test
    func lineOffsetSingleSegment() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 10.0, longitude: 1.0),
        ]))
        let offset = try #require(line.offset(by: 50_000))

        // 50 km offset right (east) of a vertical line
        #expect(abs(offset.coordinates[0].longitude - 1.4497) < 0.001)
        #expect(abs(offset.coordinates[0].latitude - 1.0) < 0.001)
        #expect(abs(offset.coordinates[1].longitude - 1.4497) < 0.001)
        #expect(abs(offset.coordinates[1].latitude - 10.0) < 0.001)
    }

    // MARK: - Straight line (3 points)

    @Test
    func lineOffsetStraight() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: -10.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 10.0, longitude: 1.0),
        ]))
        let offset = try #require(line.offset(by: 50_000))

        // All three points should be offset east uniformly (collinear)
        #expect(offset.coordinates.count == 3)
        for coord in offset.coordinates {
            #expect(abs(coord.longitude - 1.4497) < 0.001)
        }
        #expect(abs(offset.coordinates[0].latitude - (-10.0)) < 0.001)
        #expect(abs(offset.coordinates[1].latitude - 1.0) < 0.001)
        #expect(abs(offset.coordinates[2].latitude - 10.0) < 0.001)
    }

    // MARK: - Concave line

    @Test
    func lineOffsetConcave() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 21.69826549685252, longitude: 0.9667968749999999),
            Coordinate3D(latitude: 24.44714958973082, longitude: -2.5927734375),
            Coordinate3D(latitude: 29.726222319395504, longitude: 0.3955078125),
            Coordinate3D(latitude: 29.916852233070173, longitude: 7.207031249999999),
            Coordinate3D(latitude: 23.079731762449878, longitude: 11.337890625),
            Coordinate3D(latitude: 21.04349121680354, longitude: 3.2080078125),
        ]))
        // 150 miles in meters
        let offset = try #require(line.offset(by: 150 * 1609.344))

        // Verify the offset has the expected number of coordinates
        #expect(offset.coordinates.count == line.coordinates.count)

        // Verify the result is offset from the original (not identical)
        let first = offset.coordinates[0]
        #expect(abs(first.longitude - 2.2937) < 0.01)
        #expect(abs(first.latitude - 23.4165) < 0.01)

        let last = offset.coordinates[offset.coordinates.count - 1]
        #expect(abs(last.longitude - 2.6806) < 0.01)
        #expect(abs(last.latitude - 23.1494) < 0.01)
    }

    // MARK: - MultiLineString

    @Test
    func lineOffsetMultiLineString() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 25.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
        ]))
        let multiLine = try #require(MultiLineString([line1, line2]))
        let offset = try #require(multiLine.offset(by: 50_000))

        #expect(offset.lineStrings.count == 2)
        #expect(offset.lineStrings[0].coordinates.count == 3)
        #expect(offset.lineStrings[1].coordinates.count == 3)
    }

    // MARK: - Negative distance

    @Test
    func lineOffsetNegativeDistance() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
        ]))
        let offset = try #require(line.offset(by: -50_000))

        // Negative offset should go north (left side of eastward horizontal line)
        #expect(abs(offset.coordinates[0].latitude - 0.4497) < 0.001)
    }

    // MARK: - Zero distance

    @Test
    func lineOffsetZeroDistance() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
        ]))
        let offset = line.offset(by: 0.0)

        // Line should be returned unchanged
        #expect(offset == line)
    }

    // MARK: - Degenerate line (zero-length segment)

    @Test
    func lineOffsetDegenerateLine() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ]))
        let offset = try #require(line.offset(by: 50_000))
        #expect(offset.coordinates.count == 2)
    }

    // MARK: - Projections projection

    @Test
    func lineOffset3857() async throws {
        let line3857 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 0.0),
        ]))
        let offset3857 = try #require(line3857.offset(by: 50_000))
        #expect(offset3857.projection == .epsg3857)
        #expect(offset3857.coordinates.count == 2)
    }

    // MARK: - Antimeridian

    @Test
    func lineOffsetAntimeridian() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
        ]))
        let offset = try #require(line.offset(by: 50_000))
        #expect(offset.coordinates.count == 2)

        for coord in offset.coordinates {
            #expect(coord.latitude.isFinite)
            #expect(coord.longitude.isFinite)
        }
    }

}

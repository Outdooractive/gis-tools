@testable import GISTools
import Testing

struct LineSplitTests {

    /// Splitting a line at a point in the middle produces 2 segments.
    @Test
    func splitByPoint() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let splitter = Point(Coordinate3D(latitude: 5.0, longitude: 0.0))
        let result = line.lineSplit(with: splitter)
        #expect(result.features.count == 2)
    }

    /// A line split by a MultiPoint should produce segments at each split point.
    @Test
    func splitByMultiPoint() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let splitter = MultiPoint(unchecked: [
            Coordinate3D(latitude: 3.0, longitude: 0.0),
            Coordinate3D(latitude: 7.0, longitude: 0.0),
        ])
        let result = line.lineSplit(with: splitter)
        #expect(result.features.count == 3)
    }

    /// A line with no intersections returns the original line as a single segment.
    @Test
    func noIntersections() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let splitter = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let result = line.lineSplit(with: splitter)
        #expect(result.features.count == 1)
    }

    /// A line split by another crossing LineString.
    @Test
    func splitByLine() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])
        let splitter = LineString(unchecked: [
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ])
        let result = line.lineSplit(with: splitter)
        // Two crossing lines split each other into 2 segments each
        #expect(result.features.count == 2)
    }

    // MARK: - EPSG:3857

    @Test
    func lineSplit3857() async throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let splitter = Point(Coordinate3D(x: 500_000.0, y: 0.0))
        let result = line.lineSplit(with: splitter)
        #expect(result.features.count == 2)
    }

    @Test
    func lineSplit4978() async throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let splitter = Point(Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978))
        let result = line.lineSplit(with: splitter)
        #expect(result.features.count == 2)
    }

    @Test
    func lineSplitNoSRID() async throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let splitter = Point(Coordinate3D(x: 50.0, y: 0.0, projection: .noSRID))
        let result = line.lineSplit(with: splitter)
        #expect(result.features.count == 2)
    }

    /// Grid-size snapping for noise reduction.
    @Test
    func withGridSize() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let splitter = Point(Coordinate3D(latitude: 5.001, longitude: 0.0))
        // Without snapping, this might miss
        let result = line.lineSplit(with: splitter, gridSize: 0.1)
        #expect(result.features.count == 2)
    }

}

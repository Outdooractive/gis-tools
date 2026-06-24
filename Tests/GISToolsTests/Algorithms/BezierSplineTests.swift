@testable import GISTools
import Testing

struct BezierSplineTests {

    /// A simple 2-point line returns an interpolated spline with `steps` + 1 points.
    @Test
    func twoPoints() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])
        let spline = line.bezierSpline(steps: 10)
        #expect(spline != nil)
        if let spline {
            #expect(spline.coordinates.count == 11)  // steps + 1 for the start
        }
    }

    /// A 3-point line produces more points than the input.
    @Test
    func threePoints() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let spline = line.bezierSpline()
        #expect(spline != nil)
        if let spline {
            #expect(spline.coordinates.count > 3)
        }
    }

    /// The spline starts at the first control point and ends at the last.
    @Test
    func endpointsMatch() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let spline = line.bezierSpline(steps: 20)
        #expect(spline != nil)
        if let spline {
            #expect(spline.coordinates.first == Coordinate3D(latitude: 0.0, longitude: 0.0))
            #expect(spline.coordinates.last == Coordinate3D(latitude: 10.0, longitude: 0.0))
        }
    }

    /// Single-point line returns itself.
    @Test
    func singlePoint() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])
        #expect(line.bezierSpline() == nil)
    }

    /// MultiLineString concatenation produces a single smooth spline.
    @Test
    func multiLine() {
        let line1 = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])
        let line2 = LineString(unchecked: [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let multiLine = MultiLineString(unchecked: [line1, line2])
        let spline = multiLine.bezierSpline(steps: 10)
        #expect(spline != nil)
        if let spline {
            // 3 segments (shared endpoint creates 4 control points) × 9 + start + end = 29
            #expect(spline.coordinates.count == 29)
            #expect(spline.coordinates.first == Coordinate3D(latitude: 0.0, longitude: 0.0))
            #expect(spline.coordinates.last == Coordinate3D(latitude: 10.0, longitude: 0.0))
        }
    }

    /// A line crossing the antimeridian should still produce a smooth spline.
    @Test
    func antimeridian() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ])
        let spline = line.bezierSpline(steps: 10)
        #expect(spline != nil)
        if let spline {
            #expect(spline.coordinates.count > 10)
            #expect(spline.coordinates.first == Coordinate3D(latitude: 0.0, longitude: 179.0))
            #expect(spline.coordinates.last == Coordinate3D(latitude: 10.0, longitude: 179.0))
        }
    }

    /// Grid-size snapping works.
    @Test
    func withGridSize() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])
        let spline = line.bezierSpline(steps: 5, gridSize: 0.5)
        #expect(spline != nil)
        if let spline {
            #expect(spline.coordinates.count == 6)
        }
    }
    // MARK: - EPSG:3857

    @Test
    func bezierSpline3857() async throws {
        let line = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ])
        let spline = line.bezierSpline()
        #expect(spline != nil)
        if let spline {
            #expect(spline.coordinates.count > 3)
        }
    }

    @Test
    func bezierSpline4978() async throws {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 3.0, longitude: 3.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 6.0, longitude: 0.0).projected(to: .epsg4978),
        ])
        // 4978 is supported (2D spline in ECEF XY plane).
        let spline = try #require(line.bezierSpline())
        #expect(spline.coordinates.count > 3)
    }

    // MARK: - 3D

    // All coordinates have altitude → full 3D spline.
    @Test
    func bezierSpline3D() async throws {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0, altitude: 500.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
        ])
        let spline = try #require(line.bezierSpline(steps: 10))
        #expect(spline.coordinates.count == 20) // 2 segments × 9 + start + end
        // All output coordinates should carry altitude.
        #expect(spline.coordinates.allSatisfy({ $0.altitude != nil }))
        #expect(spline.coordinates.first!.altitude == 100.0)
        #expect(spline.coordinates.last!.altitude == 200.0)
    }

    // Not all coordinates have altitude → stays 2D (altitude = nil in output).
    @Test
    func bezierSplineMixedAltitude() async throws {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0), // no altitude
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
        ])
        let spline = try #require(line.bezierSpline(steps: 10))
        #expect(spline.coordinates.allSatisfy({ $0.altitude == nil }))
    }

    // ECEF 3D: all coordinates have altitude/Z → 3D spline.
    @Test
    func bezierSpline49783D() async throws {
        let line = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0, z: 100.0, projection: .epsg4978),
            Coordinate3D(x: 500_000.0, y: 500_000.0, z: 500.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 0.0, z: 200.0, projection: .epsg4978),
        ])
        let spline = try #require(line.bezierSpline(steps: 10))
        #expect(spline.coordinates.allSatisfy({ $0.altitude != nil }))
        #expect(spline.coordinates.count > 3)
    }

}

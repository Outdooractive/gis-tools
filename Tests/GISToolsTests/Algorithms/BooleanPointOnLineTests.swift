import Foundation
@testable import GISTools
import Testing

struct BooleanPointOnLineTests {

    // MARK: - LineSegment.checkIsOnSegment

    // Validates that `LineSegment.checkIsOnSegment` returns true for the midpoint.
    @Test
    func segmentOnSegmentMidpoint() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 5.0, longitude: 5.0)))
    }

    // Validates that `LineSegment.checkIsOnSegment` returns true for both endpoints.
    @Test
    func segmentOnSegmentEndpoint() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        // Endpoints are on the segment
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 10.0, longitude: 10.0)))
    }

    // Validates that `LineSegment.checkIsOnSegment` returns false for a point not on the segment.
    @Test
    func segmentNotOnSegment() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 5.0, longitude: 10.0)) == false)
    }

    // Validates that `LineSegment.checkIsOnSegment` returns false for collinear points beyond the segment.
    @Test
    func segmentOnSegmentCollinearOutside() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        // Collinear but beyond the segment
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 15.0, longitude: 15.0)) == false)
    }

    // Validates that `LineSegment.checkIsOnSegment` works correctly with a `Point` instance.
    @Test
    func segmentPointOnSegment() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.checkIsOnSegment(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))
    }

    // MARK: - LineString.checkIsOnLine

    // Validates that `LineString.checkIsOnLine` returns true for points on any segment of the line.
    @Test
    func lineStringOnLine() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        // On first segment
        #expect(ls.checkIsOnLine(Coordinate3D(latitude: 0.0, longitude: 5.0)))
        // On second segment
        #expect(ls.checkIsOnLine(Coordinate3D(latitude: 5.0, longitude: 10.0)))
        // At vertex
        #expect(ls.checkIsOnLine(Coordinate3D(latitude: 0.0, longitude: 10.0)))
    }

    // Validates that `LineString.checkIsOnLine` returns false for points not on the line.
    @Test
    func lineStringNotOnLine() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(ls.checkIsOnLine(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
    }

    // Validates that `LineString.checkIsOnLine` works correctly with a `Point` instance.
    @Test
    func lineStringPointOnLine() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        #expect(ls.checkIsOnLine(Point(Coordinate3D(latitude: 0.0, longitude: 5.0))))
    }

    // MARK: - MultiLineString.checkIsOnLine

    // Validates that `MultiLineString.checkIsOnLine` returns correct results across multiple line segments.
    @Test
    func multiLineStringOnLine() async throws {
        let mls = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
            ],
        ]))
        // On first line
        #expect(mls.checkIsOnLine(Coordinate3D(latitude: 0.0, longitude: 2.0)))
        // On second line
        #expect(mls.checkIsOnLine(Coordinate3D(latitude: 5.0, longitude: 7.0)))
        // Off both lines
        #expect(mls.checkIsOnLine(Coordinate3D(latitude: 2.0, longitude: 2.0)) == false)
    }

    // MARK: - Grid size

    // Validates that `checkIsOnLine(_:gridSize:)` and `checkIsOnSegment(_:gridSize:)` match manual pre-snapping.
    @Test
    func pointOnLineWithGridSize() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let onPoint = Coordinate3D(latitude: 0.0001, longitude: 5.0001)
        let offPoint = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParamOn = ls.checkIsOnLine(onPoint, gridSize: gridSize)
        let snappedLine = ls.snappedToGrid(tolerance: gridSize)
        let snappedOn = Point(onPoint).snappedToGrid(tolerance: gridSize).coordinate
        let manualOn = snappedLine.checkIsOnLine(snappedOn)
        #expect(withParamOn == manualOn)

        let withParamOff = ls.checkIsOnLine(offPoint, gridSize: gridSize)
        let snappedOff = Point(offPoint).snappedToGrid(tolerance: gridSize).coordinate
        let manualOff = snappedLine.checkIsOnLine(snappedOff)
        #expect(withParamOff == manualOff)
    }

    // MARK: - Projections

    // Point on line in EPSG:3857.
    @Test
    func pointOnLine3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let point = Point(Coordinate3D(x: 500.0, y: 500.0))
        #expect(polygon.contains(point))
    }

    // Point on line in EPSG:4978.
    @Test
    func pointOnLine4978() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let point = Point(Coordinate3D(x: 500.0, y: 0.0, z: 0.0, projection: .epsg4978))
        #expect(line.checkIsOnLine(point))
    }

    // MARK: - Antimeridian

    // Point on line near antimeridian.
    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        #expect(lineString.checkIsOnLine(Coordinate3D(latitude: 5.0, longitude: 174.5)))
        #expect(lineString.checkIsOnLine(Coordinate3D(latitude: 0.0, longitude: 175.0)) == false)
    }

}

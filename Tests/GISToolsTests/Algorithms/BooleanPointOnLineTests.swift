import Foundation
@testable import GISTools
import Testing

struct BooleanPointOnLineTests {

    // MARK: - LineSegment.checkIsOnSegment

    @Test
    func segmentOnSegmentMidpoint() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 5.0, longitude: 5.0)))
    }

    @Test
    func segmentOnSegmentEndpoint() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        // Endpoints are on the segment
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 10.0, longitude: 10.0)))
    }

    @Test
    func segmentNotOnSegment() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 5.0, longitude: 10.0)) == false)
    }

    @Test
    func segmentOnSegmentCollinearOutside() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        // Collinear but beyond the segment
        #expect(segment.checkIsOnSegment(Coordinate3D(latitude: 15.0, longitude: 15.0)) == false)
    }

    @Test
    func segmentPointOnSegment() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.checkIsOnSegment(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))
    }

    // MARK: - LineString.checkIsOnLine

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

    @Test
    func lineStringNotOnLine() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(ls.checkIsOnLine(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
    }

    @Test
    func lineStringPointOnLine() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        #expect(ls.checkIsOnLine(Point(Coordinate3D(latitude: 0.0, longitude: 5.0))))
    }

    // MARK: - MultiLineString.checkIsOnLine

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

}

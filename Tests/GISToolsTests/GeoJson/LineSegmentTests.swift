#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

struct LineSegmentTests {

    private let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
    private let b = Coordinate3D(latitude: 10.0, longitude: 10.0)

    @Test
    func initialization() async throws {
        let segment = LineSegment(first: a, second: b)

        #expect(segment.first == a)
        #expect(segment.second == b)
        #expect(segment.index == nil)
        #expect(segment.boundingBox == nil)
    }

    @Test
    func initializationWithIndex() async throws {
        let segment = LineSegment(first: a, second: b, index: 3)

        #expect(segment.index == 3)
    }

    @Test
    func initializationWithBoundingBox() async throws {
        let segment = LineSegment(first: a, second: b, calculateBoundingBox: true)

        let expectedBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment.boundingBox == expectedBox)
    }

    @Test
    func coordinates() async throws {
        let segment = LineSegment(first: a, second: b)

        #expect(segment.coordinates == [a, b])
    }

    @Test
    func projection() async throws {
        let segment = LineSegment(first: a, second: b)

        #expect(segment.projection == .epsg4326)
    }

    @Test
    func projection3857() async throws {
        let a3857 = Coordinate3D(x: 0.0, y: 0.0)
        let b3857 = Coordinate3D(x: 111_319.5, y: 0.0)
        let segment = LineSegment(first: a3857, second: b3857)

        #expect(segment.projection == .epsg3857)
    }

    @Test
    func projected() async throws {
        let segment = LineSegment(first: a, second: b)
        let projected = segment.projected(to: .epsg3857)

        let expectedSecond = b.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(abs(projected.first.x - a.projected(to: .epsg3857).x) < 0.001)
        #expect(abs(projected.first.y - a.projected(to: .epsg3857).y) < 0.001)
        #expect(abs(projected.second.x - expectedSecond.x) < 0.001)
        #expect(abs(projected.second.y - expectedSecond.y) < 0.001)
    }

    @Test
    func projectedSameProjection() async throws {
        let segment = LineSegment(first: a, second: b)
        let projected = segment.projected(to: .epsg4326)

        #expect(projected.first == segment.first)
        #expect(projected.second == segment.second)
    }

    @Test
    func equatable() async throws {
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: a, second: b)
        let s3 = LineSegment(first: a, second: Coordinate3D(latitude: 20.0, longitude: 20.0))

        #expect(s1 == s2)
        #expect(s1 != s3)
    }

    @Test
    func hashable() async throws {
        let s1 = LineSegment(first: a, second: b)
        let s2 = LineSegment(first: a, second: b)

        let set: Set<LineSegment> = [s1, s2]
        #expect(set.count == 1)
    }

    @Test
    func calculateBoundingBox() async throws {
        let segment = LineSegment(first: a, second: b)
        let box = segment.calculateBoundingBox()

        let expectedBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(box == expectedBox)
    }

    @Test
    func intersectsBoundingBox() async throws {
        let segment = LineSegment(first: a, second: b)
        let insideBox = BoundingBox(
            southWest: Coordinate3D(latitude: 5.0, longitude: 5.0),
            northEast: Coordinate3D(latitude: 15.0, longitude: 15.0))
        let outsideBox = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))

        #expect(segment.intersects(insideBox))
        #expect(!segment.intersects(outsideBox))
    }

    #if canImport(CoreLocation)
    @Test
    func initializationWithCLLocationCoordinate2D() async throws {
        let first = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let second = CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0)
        let segment = LineSegment(first: first, second: second)

        #expect(segment.first == Coordinate3D(first))
        #expect(segment.second == Coordinate3D(second))
    }

    @Test
    func initializationWithCLLocation() async throws {
        let first = CLLocation(latitude: 0.0, longitude: 0.0)
        let second = CLLocation(latitude: 10.0, longitude: 10.0)
        let segment = LineSegment(first: first, second: second)

        #expect(segment.first == Coordinate3D(first))
        #expect(segment.second == Coordinate3D(second))
    }
    #endif

}

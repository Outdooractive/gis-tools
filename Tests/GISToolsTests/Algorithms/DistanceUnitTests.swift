import Foundation
@testable import GISTools
import Testing

struct DistanceUnitTests {

    private func square(
        minX: Double,
        minY: Double,
        maxX: Double,
        maxY: Double,
        projection: Projection = .epsg3857
    ) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: minX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: minY, projection: projection),
        ]])
    }

    // MARK: - Coordinate / Point

    @Test
    func coordinateDistanceUnits() {
        let first = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let second = Coordinate3D(latitude: 0.0, longitude: 1.0)
        let meters = first.distance(to: second)

        #expect(first.distance(to: second, in: .meters) == meters)
        #expect(abs(try! #require(first.distance(to: second, in: .kilometers)) - meters / 1_000.0) < 0.000001)
        #expect(abs(try! #require(first.distance(from: second, in: .miles)) - GISTool.convert(length: meters, from: .meters, to: .miles)!) < 0.000001)
        #expect(first.distance(to: second, in: .acres) == nil)
    }

    @Test
    func noSRIDDistanceUnits() {
        let first = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let second = Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID)

        #expect(first.distance(to: second) == 10.0)
        #expect(first.distance(to: second, in: .meters) == nil)
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978])
    func distanceUnitsAcrossProjections(projection: Projection) {
        let first: Coordinate3D
        let second: Coordinate3D

        switch projection {
        case .epsg4326:
            first = Coordinate3D(latitude: 0.0, longitude: 0.0)
            second = Coordinate3D(latitude: 0.0, longitude: 1.0)
        case .epsg4978:
            first = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
            second = Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978)
        default:
            first = Coordinate3D(x: 0.0, y: 0.0, projection: projection)
            second = Coordinate3D(x: 1_000.0, y: 0.0, projection: projection)
        }

        let kilometers = try! #require(first.distance(to: second, in: .kilometers))
        #expect(abs(kilometers - first.distance(to: second) / 1_000.0) < 0.000001)

        let pointA = Point(first)
        let pointB = Point(second)
        #expect(abs(try! #require(pointA.distance(to: pointB, in: .kilometers)) - kilometers) < 0.000001)
    }

    @Test
    func rhumbDistanceUnits() {
        let first = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let second = Coordinate3D(latitude: 0.0, longitude: 1.0)
        let meters = first.rhumbDistance(from: second)

        #expect(abs(try! #require(first.rhumbDistance(from: second, in: .kilometers)) - meters / 1_000.0) < 0.000001)
    }

    // MARK: - Line distance APIs

    @Test
    func distanceAlongUnits() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        let target = Coordinate3D(latitude: 0.0, longitude: 0.5)
        let meters = try #require(line.distanceAlong(to: target))

        #expect(abs(try #require(line.distanceAlong(to: target, in: .kilometers)) - meters / 1_000.0) < 0.000001)
    }

    @Test
    func distanceFromUnits() throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.0, longitude: 0.0),
            second: Coordinate3D(latitude: 0.0, longitude: 1.0))
        let point = Coordinate3D(latitude: 1.0, longitude: 0.5)
        let meters = segment.distanceFrom(coordinate: point)

        #expect(abs(try #require(segment.distanceFrom(coordinate: point, in: .kilometers)) - meters / 1_000.0) < 0.000001)
        #expect(abs(try #require(segment.distanceFrom(point: Point(point), in: .kilometers)) - meters / 1_000.0) < 0.000001)

        let line = try #require(LineString([segment.first, segment.second]))
        #expect(abs(try #require(line.distanceFrom(coordinate: point, in: .kilometers)) - meters / 1_000.0) < 0.000001)
        #expect(abs(try #require(line.distanceFrom(point: Point(point), in: .kilometers)) - meters / 1_000.0) < 0.000001)
    }

    // MARK: - dWithin

    @Test
    func dWithinUnits() {
        let first = square(minX: 0.0, minY: 0.0, maxX: 1.0, maxY: 1.0)
        let second = square(minX: 2.0, minY: 0.0, maxX: 3.0, maxY: 1.0)

        #expect(first.dWithin(second, distance: 1.1, in: .meters))
        #expect(first.dWithin(second, distance: 0.0011, in: .kilometers))
        #expect(first.dWithin(second, distance: 0.9, in: .meters) == false)
    }

    @Test
    func noSRIDDWithinUnits() {
        let first = Point(Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID))
        let second = Point(Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID))

        #expect(first.dWithin(second, distance: 10.0))
        #expect(first.dWithin(second, distance: 10.0, in: .meters) == false)
    }

}

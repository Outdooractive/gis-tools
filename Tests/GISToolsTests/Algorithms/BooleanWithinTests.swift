import Foundation
@testable import GISTools
import Testing

struct BooleanWithinTests {

    private func square(
        minX: Double,
        minY: Double,
        maxX: Double,
        maxY: Double,
        projection: Projection = .epsg4326
    ) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: minX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: minY, projection: projection),
        ]])
    }

    // MARK: - dWithin

    @Test
    func dWithin() {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let b = Point(Coordinate3D(latitude: 0.0, longitude: 1.0))

        #expect(a.dWithin(b, distance: b.coordinate.distance(from: a.coordinate) + 1.0))
        #expect(a.dWithin(b, distance: b.coordinate.distance(from: a.coordinate) - 1.0) == false)
        #expect(a.dWithin(a, distance: 0.0))
        #expect(a.dWithin(b, distance: -1.0) == false)

        let firstSquare = square(
            minX: 0.0, minY: 0.0, maxX: 1.0, maxY: 1.0,
            projection: .epsg3857)
        let secondSquare = square(
            minX: 2.0, minY: 0.0, maxX: 3.0, maxY: 1.0,
            projection: .epsg3857)
        #expect(firstSquare.dWithin(secondSquare, distance: 1.1))
        #expect(firstSquare.dWithin(secondSquare, distance: 0.9) == false)
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func dWithinAcrossProjections(projection: Projection) {
        let first: Point
        let second: Point

        switch projection {
        case .epsg4326:
            first = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
            second = Point(Coordinate3D(latitude: 0.0, longitude: 1.0))
        case .epsg4978:
            first = Point(Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978))
            second = Point(Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978))
        default:
            first = Point(Coordinate3D(x: 0.0, y: 0.0, projection: projection))
            second = Point(Coordinate3D(x: 1_000.0, y: 0.0, projection: projection))
        }

        let distance = first.coordinate.distance(from: second.coordinate)
        #expect(first.dWithin(second, distance: distance + 1.0))
        #expect(first.dWithin(second, distance: distance - 1.0) == false)
    }

}

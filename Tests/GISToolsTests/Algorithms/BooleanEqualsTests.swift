import Foundation
@testable import GISTools
import Testing

struct BooleanEqualsTests {

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

    // MARK: - equals

    @Test
    func topologicalEquals() {
        let first = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
        let shiftedStart = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]])
        let partial = square(minX: 5.0, minY: 0.0, maxX: 15.0, maxY: 10.0)

        #expect(first.equals(shiftedStart))
        #expect(shiftedStart.equals(first))
        #expect(first.equals(partial) == false)
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func equalsAcrossProjections(projection: Projection) {
        let polygon: Polygon

        switch projection {
        case .epsg4326:
            polygon = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
        case .epsg4978:
            polygon = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
                .projected(to: .epsg4978)
        default:
            polygon = square(minX: 0.0, minY: 0.0, maxX: 1_000.0, maxY: 1_000.0, projection: projection)
        }

        #expect(polygon.equals(polygon))
    }

}

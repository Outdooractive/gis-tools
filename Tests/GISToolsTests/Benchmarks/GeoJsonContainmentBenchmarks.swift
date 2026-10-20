import Foundation
@testable import GISTools
import Testing

/// Correctness checks for bounding-box misses in `Polygon.contains`.
///
/// Timing runs live in the `Benchmarks` executable:
/// `swift run -c release Benchmarks predicates`.
struct GeoJsonContainmentBenchmarks {

    private func makePolygon(vertices: Int) throws -> Polygon {
        var coordinates = (0 ..< vertices).map { index -> Coordinate3D in
            let angle = Double(index) / Double(vertices) * 2.0 * Double.pi
            return Coordinate3D(
                latitude: 10.0 * sin(angle),
                longitude: 10.0 * cos(angle))
        }
        coordinates.append(coordinates[0])
        return try #require(Polygon([coordinates], calculateBoundingBox: true))
    }

    @Test
    func outsideBoundingBoxIsRejected() throws {
        for vertices in [100, 1_000, 10_000] {
            let polygon = try makePolygon(vertices: vertices)
            let outside = Coordinate3D(latitude: 50.0, longitude: 50.0)
            #expect(polygon.contains(outside) == false)
        }
    }

}

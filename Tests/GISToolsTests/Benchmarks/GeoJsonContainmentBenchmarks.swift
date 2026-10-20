import Foundation
@testable import GISTools
import Testing

/// Bounding-box miss benchmark for `Polygon.contains`.
///
/// Timing is printed for before/after comparisons; correctness is always
/// checked. Timing runs are disabled in CI.
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

    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func boundingBoxMissTiming() throws {
        let outside = Coordinate3D(latitude: 50.0, longitude: 50.0)

        for vertices in [100, 1_000, 10_000, 100_000] {
            let polygon = try makePolygon(vertices: vertices)

            let start = DispatchTime.now().uptimeNanoseconds
            for _ in 0 ..< 1_000 {
                _ = polygon.contains(outside)
            }
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000.0
            print(String(
                format: "[GeoJsonContainmentBenchmark] bbox miss n=%d: %.3f µs/call",
                vertices,
                elapsed / 1_000.0))
        }
    }

}

import Foundation
@testable import GISTools
import Testing

/// Memory layout guardrails. Phase 2 tightens the limits to the 3.0 targets.
struct Coordinate3DMemoryTests {

    @Test
    func coordinateLayoutBaseline() {
        print("""
        [GeoJsonMemory] Coordinate3D size=\(MemoryLayout<Coordinate3D>.size) \
        stride=\(MemoryLayout<Coordinate3D>.stride) \
        Projection size=\(MemoryLayout<Projection>.size) \
        stride=\(MemoryLayout<Projection>.stride)
        """)

        // 3.0 targets: projection definition boxing and a compact coordinate.
        #expect(MemoryLayout<Projection>.stride <= 16)
        #expect(MemoryLayout<Coordinate3D>.stride <= 64)
    }

    @Test
    func coordinateArrayFootprint() throws {
        let count = 10_000
        let coordinates = (0 ..< count).map { index in
            Coordinate3D(
                latitude: Double(index) / 1_000.0,
                longitude: Double(index) / 500.0)
        }
        let polygon = try #require(Polygon([coordinates + [coordinates[0]]]))

        let estimated = polygon.allCoordinates.count * MemoryLayout<Coordinate3D>.stride
        print(String(
            format: "[GeoJsonMemory] %d stored vertices ≈ %.2f MB at %d B/vertex",
            count,
            Double(estimated) / 1_048_576.0,
            MemoryLayout<Coordinate3D>.stride))

        #expect(polygon.allCoordinates.count == count + 1)
    }

}

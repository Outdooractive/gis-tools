#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

// MARK: - Performance benchmarks

/// Performance benchmarks for coordinate projection.
///
/// The *baseline* functions inline the formulas exactly as they were
/// implemented in `Coordinate3D` before the registry refactor - so the
/// benchmark compares the registry dispatch overhead against direct math.
/// The assertions verify that both produce the same results.
///
/// Results (release build, 2026-09, per coordinate):
/// - baseline direct math: ~5 ns
/// - registry lookup alone: ~30 ns (one dictionary read)
/// - projection math through a fixed definition: ~9 ns
/// - full `projected(to:)` path: ~125 ns
///
/// The full-path cost is bounded by the per-call dictionary lookup(s) and
/// existential dispatch; it is not fully closeable to the inlined baseline
/// without a non-existential registry redesign. The overhead only matters
/// for bulk reprojection (>100k points); algorithm hot paths reproject per
/// geometry feature rather than per field, so this is acceptable. If bulk
/// reprojection of large point clouds ever becomes a use case, consider
/// amortizing lookups with a `project(coordinates:)` batch API or
/// non-existential dispatch (tracked separately).
///
/// Numbers print to the test output (visible with `swift test --verbose`).
/// All tests are skipped in CI.
@Suite
struct ProjectionBenchmarks {

    private static let iterations: Int = 5
    private static let count: Int = 10_000

    private static let coordinates: [Coordinate3D] = {
        (0 ..< count).map { i in
            let latitude = Double(i % 170_000) / 1_000.0 - 85.0
            let longitude = Double((i * 7) % 360_000) / 1_000.0 - 180.0
            return Coordinate3D(latitude: latitude, longitude: longitude, altitude: Double(i % 200))
        }
    }()

    // MARK: - Baseline formulas (pre-registry implementations)

    /// Direct EPSG:4326 → EPSG:3857 formulas, as implemented before the
    /// registry refactor (`longitudeProjected`/`latitudeProjected`).
    private static func baselineForward3857(_ coordinate: Coordinate3D) -> (Double, Double) {
        let x = coordinate.longitude * GISTool.originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= GISTool.originShift / 180.0
        return (x, y)
    }

    /// Direct EPSG:3857 → EPSG:4326 formulas.
    private static func baselineInverse3857(_ coordinate: Coordinate3D) -> (Double, Double) {
        let expArgument = (coordinate.latitude / GISTool.originShift) * 180.0 * Double.pi / 180.0
        let latitude = 180.0 / Double.pi * ((2.0 * atan(exp(expArgument))) - (Double.pi / 2.0))
        let longitude = (coordinate.longitude / GISTool.originShift) * 180.0
        return (latitude, longitude)
    }

    // MARK: - Benchmark blocks

    /// Projects every coordinate and returns the median elapsed time in ms.
    private static func timePerIteration(
        _ coordinates: [Coordinate3D],
        _ block: (Coordinate3D) -> Void
    ) -> Double {
        let clock = ContinuousClock()
        block(coordinates[0]) // warmup

        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        for _ in 0 ..< iterations {
            let start = clock.now
            for coordinate in coordinates {
                block(coordinate)
            }
            durations.append(clock.now - start)
        }

        let sorted = durations.sorted()
        let median = sorted[sorted.count / 2]
        let components = median.components
        return Double(components.seconds) * 1_000.0
            + Double(components.attoseconds) / 1_000_000_000_000_000
    }

    // MARK: - Benchmarks

    // Baseline: direct formulas, EPSG:4326 → EPSG:3857.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBaselineForward3857() {
        let duration = Self.timePerIteration(Self.coordinates, { coordinate in
            let _ = Self.baselineForward3857(coordinate)
        })
        print("[ProjectionBenchmark] baseline 4326→3857: \(String(format: "%.3f", duration))ms / 10k")
    }

    // Registry path, EPSG:4326 → EPSG:3857, with a correctness cross-check.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceRegistryForward3857() {
        let duration = Self.timePerIteration(Self.coordinates, { coordinate in
            let _ = coordinate.projected(to: .epsg3857)
        })
        print("[ProjectionBenchmark] registry 4326→3857: \(String(format: "%.3f", duration))ms / 10k")

        let projected = Self.coordinates[0].projected(to: .epsg3857)
        let baseline = Self.baselineForward3857(Self.coordinates[0])
        #expect(abs(projected.longitude - baseline.0) < 0.0000000001)
        #expect(abs(projected.latitude - baseline.1) < 0.0000000001)
    }

    // Baseline: direct formulas, EPSG:3857 → EPSG:4326.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBaselineInverse3857() {
        let duration = Self.timePerIteration(Self.coordinates, { coordinate in
            let _ = Self.baselineInverse3857(coordinate)
        })
        print("[ProjectionBenchmark] baseline 3857→4326: \(String(format: "%.3f", duration))ms / 10k")
    }

    // Registry path, EPSG:3857 → EPSG:4326, with a correctness cross-check.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceRegistryInverse3857() {
        let mercatorCoordinates: [Coordinate3D] = Self.coordinates.compactMap   { coordinate in
            let (x, y) = Self.baselineForward3857(coordinate)
            return Coordinate3D(x: x, y: y)
        }

        let duration = Self.timePerIteration(mercatorCoordinates, { coordinate in
            let _ = coordinate.projected(to: .epsg4326)
        })
        print("[ProjectionBenchmark] registry 3857→4326: \(String(format: "%.3f", duration))ms / 10k")

        let projected = mercatorCoordinates[0].projected(to: .epsg4326)
        let baseline = Self.baselineInverse3857(mercatorCoordinates[0])
        #expect(abs(projected.latitude - baseline.0) < 0.0000000001)
        #expect(abs(projected.longitude - baseline.1) < 0.0000000001)
    }

    // Registry path, EPSG:4326 → EPSG:4978 → EPSG:4326 (heaviest math:
    // ECEF forwards with an iterative inverse).
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceRegistry4978() {
        let duration = Self.timePerIteration(Self.coordinates, { coordinate in
            let _ = coordinate.projected(to: .epsg4978).projected(to: .epsg4326)
        })
        print("[ProjectionBenchmark] registry 4326→4978→4326: \(String(format: "%.3f", duration))ms / 10k")
    }

    // Registry path, EPSG:4326 → UTM zone 19N → EPSG:4326 (heaviest
    // formula set).
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceRegistryUtm() {
        let duration = Self.timePerIteration(Self.coordinates, { coordinate in
            let _ = coordinate.projected(to: .epsg32619).projected(to: .epsg4326)
        })
        print("[ProjectionBenchmark] registry 4326→32619→4326: \(String(format: "%.3f", duration))ms / 10k")
    }

}

// MARK: - Overhead decomposition

extension ProjectionBenchmarks {

    // Isolates the registry lookup cost (two dictionary reads per projected
    // call would be double this).
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceRegistryLookupAlone() {
        let duration = Self.timePerIteration(Self.coordinates, { _ in
            let _ = ProjectionRegistry.definition(for: .epsg3857)
        })
        print("[ProjectionBenchmark] lookup alone: \(String(format: "%.3f", duration))ms / 10k")
    }

    // Isolates the full projection cost of the two direct fragments from the
    // above for a well-known direction (4326 pivot identity + one virtual call).
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceDefinitionAndForward() {
        let definition = ProjectionRegistry.definition(for: .epsg3857)
        let duration = Self.timePerIteration(Self.coordinates, { coordinate in
            let _ = definition.forward(coordinate)
        })
        print("[ProjectionBenchmark] forward only (fixed definition): \(String(format: "%.3f", duration))ms / 10k")
    }

}

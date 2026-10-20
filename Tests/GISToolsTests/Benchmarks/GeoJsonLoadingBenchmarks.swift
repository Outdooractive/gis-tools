import Foundation
@testable import GISTools
import Testing

/// Loading benchmarks. Disabled in CI; run with
/// `swift test -c release --filter GeoJsonLoadingBenchmarks`.
@Suite
struct GeoJsonLoadingBenchmarks {

    private static let featureCount = 20
    private static let vertexCount = 100

    private static let data: Data = {
        var result = #"{"type":"FeatureCollection","features":["#
        for featureIndex in 0 ..< featureCount {
            var ring: [String] = []
            for vertexIndex in 0 ..< vertexCount {
                let angle = Double(vertexIndex) / Double(vertexCount) * 2.0 * Double.pi
                let x = -10.0 + Double(featureIndex) + 2.0 * cos(angle)
                let y = 2.0 * sin(angle)
                ring.append("[\(x),\(y)]")
            }
            ring.append(ring[0])
            if featureIndex > 0 {
                result += ","
            }
            result += #"{"type":"Feature","properties":{"name":"f\#(featureIndex)"},"geometry":{"type":"Polygon","coordinates":[[\#(ring.joined(separator: ","))]]}}"#
        }
        result += "]}"
        return Data(result.utf8)
    }()

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    private static func measure(_ block: () throws -> Void) rethrows -> Double {
        var times: [Double] = []
        for _ in 0 ..< 5 {
            let start = DispatchTime.now().uptimeNanoseconds
            try block()
            times.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000.0)
        }
        return median(times)
    }

    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func nativeLoading() {
        let duration = Self.measure {
            _ = FeatureCollection(jsonData: Self.data)
        }
        print(String(
            format: "[GeoJsonLoadingBenchmark] native: %.4fs (%d features)",
            duration,
            Self.featureCount))
    }

    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func codableLoading() throws {
        let duration = try Self.measure {
            _ = try JSONDecoder().decode(FeatureCollection.self, from: Self.data)
        }
        print(String(
            format: "[GeoJsonLoadingBenchmark] codable: %.4fs (%d features)",
            duration,
            Self.featureCount))
    }

    @Test
    func benchmarkFixtureIsValid() throws {
        let collection = try #require(FeatureCollection(jsonData: Self.data))

        #expect(collection.features.count == Self.featureCount)
        #expect(collection.features.allSatisfy { $0.geometry is Polygon })
    }

}

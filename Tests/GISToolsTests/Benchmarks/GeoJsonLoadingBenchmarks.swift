import Foundation
@testable import GISTools
import Testing

/// Validates the fixture used by the loading benchmarks.
///
/// Timing runs live in the `Benchmarks` executable:
/// `swift run -c release Benchmarks loading`.
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

    @Test
    func benchmarkFixtureIsValid() throws {
        let collection = try #require(FeatureCollection(jsonData: Self.data))

        #expect(collection.features.count == Self.featureCount)
        #expect(collection.features.allSatisfy { $0.geometry is Polygon })
    }

}

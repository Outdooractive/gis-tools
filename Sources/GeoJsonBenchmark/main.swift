import Foundation
import GISTools

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// MARK: - Synthetic fixture

private let fixturePath = "/tmp/gis-tools-benchmark.geojson"

private func makeCollectionData(features: Int, vertices: Int) -> Data {
    var result = #"{"type":"FeatureCollection","features":["#
    var seed: UInt64 = 42

    func random() -> Double {
        seed = (seed &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
        return Double(seed >> 11) / Double(1 << 53)
    }

    for featureIndex in 0 ..< features {
        let centerX = -170.0 + Double(featureIndex % 20) * 17.0
        let centerY = -80.0 + Double(featureIndex / 20) * 8.0
        var ring: [String] = []
        ring.reserveCapacity(vertices + 1)

        for vertexIndex in 0 ..< vertices {
            let angle = Double(vertexIndex) / Double(vertices) * 2.0 * Double.pi
            let radius = 3.0 + random()
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * 0.9 * sin(angle)
            ring.append("[\(x),\(y)]")
        }
        ring.append(ring[0])

        if featureIndex > 0 {
            result += ","
        }
        result += #"{"type":"Feature","properties":{"name":"f\#(featureIndex)","level":\#(featureIndex % 5)},"geometry":{"type":"Polygon","coordinates":[[\#(ring.joined(separator: ","))]]}}"#
    }

    result += "]}"
    return Data(result.utf8)
}

// MARK: - Typed reference decoders

private struct TypedRing: Decodable {

    let coordinates: [Coordinate3D]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Coordinate3D] = []
        if let count = container.count {
            result.reserveCapacity(count)
        }

        while !container.isAtEnd {
            var position = try container.nestedUnkeyedContainer()
            let longitude = try position.decode(Double.self)
            let latitude = try position.decode(Double.self)
            result.append(Coordinate3D(latitude: latitude, longitude: longitude))
        }

        coordinates = result
    }

}

private struct TypedGeometry: Decodable {
    let coordinates: [TypedRing]
}

private struct TypedFeature: Decodable {
    let geometry: TypedGeometry
    let properties: [String: JSONValue]
}

private struct TypedCollection: Decodable {
    let features: [TypedFeature]
}

// MARK: - Timing

private func now() -> Double {
    Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000.0
}

private func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0.0 }
    return sorted[sorted.count / 2]
}

/// Peak resident set size in MB. `ru_maxrss` is kilobytes on Linux and bytes
/// on Darwin.
private func peakRSSMegabytes() -> Double {
    var usage = rusage()
    #if os(Linux)
    getrusage(0 /* RUSAGE_SELF */, &usage)
    #else
    getrusage(RUSAGE_SELF, &usage)
    #endif

    #if os(Linux)
    return Double(usage.ru_maxrss) / 1024.0
    #else
    return Double(usage.ru_maxrss) / (1024.0 * 1024.0)
    #endif
}

private func measure(iterations: Int, _ block: () -> Void) -> Double {
    if iterations > 1 {
        block() // warmup
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)
    for _ in 0 ..< iterations {
        let start = now()
        block()
        times.append(now() - start)
    }
    return median(times)
}

// MARK: - Modes

private func runNative(data: Data, iterations: Int) -> (Int, Double) {
    var count = 0
    let seconds = measure(iterations: iterations) {
        guard let collection = FeatureCollection(jsonData: data) else {
            fatalError("native parse failed")
        }
        count = collection.features.count
    }
    return (count, seconds)
}

private func runCodable(data: Data, iterations: Int) -> (Int, Double) {
    var count = 0
    let seconds = measure(iterations: iterations) {
        do {
            count = try JSONDecoder().decode(FeatureCollection.self, from: data).features.count
        }
        catch {
            fatalError("codable parse failed: \(error)")
        }
    }
    return (count, seconds)
}

private func runTyped(data: Data, iterations: Int) -> (Int, Double) {
    var count = 0
    let seconds = measure(iterations: iterations) {
        do {
            let decoded = try JSONDecoder().decode(TypedCollection.self, from: data)
            let features = decoded.features.map { feature in
                Feature(
                    Polygon(unchecked: feature.geometry.coordinates.map(\.coordinates)),
                    properties: feature.properties.mapValues { $0.asSendable })
            }
            count = features.count
        }
        catch {
            fatalError("typed parse failed: \(error)")
        }
    }
    return (count, seconds)
}

private func runBoundingBoxMiss() {
    for count in [100, 1_000, 10_000, 100_000] {
        var coordinates = (0 ..< count).map { index -> Coordinate3D in
            let angle = Double(index) / Double(count) * 2.0 * Double.pi
            return Coordinate3D(latitude: 10.0 * sin(angle), longitude: 10.0 * cos(angle))
        }
        coordinates.append(coordinates[0])

        guard let polygon = Polygon([coordinates], calculateBoundingBox: true) else {
            fatalError("polygon creation failed")
        }
        let outside = Coordinate3D(latitude: 50.0, longitude: 50.0)

        let start = now()
        for _ in 0 ..< 1_000 {
            _ = polygon.contains(outside)
        }
        let microseconds = (now() - start) / 1_000.0 * 1_000_000.0
        print(String(format: "bboxmiss n=%d us=%.3f", count, microseconds))
    }
}

// MARK: - Entry point

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: GeoJsonBenchmark gen|native|codable|typed|bboxmiss [iterations]")
    exit(1)
}

let mode = arguments[1]
let iterations = arguments.count >= 3 ? (Int(arguments[2]) ?? 5) : 5

switch mode {
case "gen":
    let data = makeCollectionData(features: 400, vertices: 1_600)
    try data.write(to: URL(fileURLWithPath: fixturePath))
    print("generated path=\(fixturePath) bytes=\(data.count)")

case "native", "codable", "typed":
    let data = try Data(contentsOf: URL(fileURLWithPath: fixturePath))
    let result: (Int, Double)
    switch mode {
    case "native": result = runNative(data: data, iterations: iterations)
    case "codable": result = runCodable(data: data, iterations: iterations)
    default: result = runTyped(data: data, iterations: iterations)
    }
    print("mode=\(mode) features=\(result.0) iterations=\(iterations) seconds=\(result.1)")
    print(String(format: "peak_rss_mb=%.1f", peakRSSMegabytes()))
    print("stride=\(MemoryLayout<Coordinate3D>.stride) projectionStride=\(MemoryLayout<Projection>.stride)")

case "bboxmiss":
    runBoundingBoxMiss()

default:
    print("unknown mode: \(mode)")
    exit(1)
}

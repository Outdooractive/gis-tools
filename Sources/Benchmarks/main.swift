import Foundation
import GISTools

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// MARK: - Configuration and helpers

private let fixturePath = "/tmp/gis-tools-benchmark.geojson"
private let graphFixtureDirectory = ProcessInfo.processInfo.environment["GISTOOLS_GRAPH_FIXTURES"]
    ?? "Tests/GISToolsTests/TestData/Graph"

private func now() -> Double {
    Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000.0
}

private func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0.0 }
    return sorted[sorted.count / 2]
}

@discardableResult
private func run(_ name: String, iterations: Int = 3, _ block: () throws -> Void) rethrows -> Double {
    if iterations > 1 {
        try block()
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)
    for _ in 0 ..< iterations {
        let start = now()
        try block()
        times.append(now() - start)
    }

    let seconds = median(times)
    print(String(format: "bench=%@ seconds=%.6f", name, seconds))
    return seconds
}

private func peakRSSMegabytes() -> Double {
    var usage = rusage()
    #if os(Linux)
    getrusage(0 /* RUSAGE_SELF */, &usage)
    return Double(usage.ru_maxrss) / 1024.0
    #else
    getrusage(RUSAGE_SELF, &usage)
    return Double(usage.ru_maxrss) / (1024.0 * 1024.0)
    #endif
}

private func currentRSSMegabytes() -> Double {
    #if os(Linux)
    guard let statm = try? String(contentsOfFile: "/proc/self/statm", encoding: .utf8),
          let residentPages = statm.split(separator: " ").dropFirst().first,
          let pages = Double(residentPages)
    else {
        return peakRSSMegabytes()
    }
    return pages * Double(getpagesize()) / 1_048_576.0
    #else
    return peakRSSMegabytes()
    #endif
}

// MARK: - Deterministic data

private struct SeededRandom {

    private var state: UInt64

    init(seed: UInt64 = 42) {
        state = seed
    }

    mutating func nextDouble() -> Double {
        state = (state &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }

}

private func makeCirclePolygon(
    vertices: Int,
    radius: Double = 10.0,
    projection: Projection = .epsg4326
) -> Polygon {
    let coordinates = (0 ..< vertices).map { index -> Coordinate3D in
        let angle = Double(index) / Double(vertices) * 2.0 * Double.pi
        return Coordinate3D(
            latitude: radius * sin(angle),
            longitude: radius * cos(angle))
    }
    return Polygon(unchecked: [coordinates + [coordinates[0]]], calculateBoundingBox: true)
}

private func makeLineString(vertices: Int) -> LineString {
    let coordinates = (0 ..< vertices).map { index -> Coordinate3D in
        let x = Double(index) / Double(max(vertices - 1, 1)) * 10.0
        let y = sin(x) * 0.1
        return Coordinate3D(latitude: y, longitude: x)
    }
    return LineString(unchecked: coordinates)
}

private func makePointCloud(count: Int) -> MultiPoint {
    var random = SeededRandom(seed: 7)
    let points = (0 ..< count).map { _ in
        Point(Coordinate3D(
            latitude: random.next(in: -10.0 ... 10.0),
            longitude: random.next(in: -10.0 ... 10.0)))
    }
    return MultiPoint(unchecked: points)
}

private func makeFeatureCollection(features: Int, vertices: Int) -> Data {
    var result = #"{"type":"FeatureCollection","features":["#
    var random = SeededRandom(seed: 42)

    for featureIndex in 0 ..< features {
        let centerX = -170.0 + Double(featureIndex % 20) * 17.0
        let centerY = -80.0 + Double(featureIndex / 20) * 8.0
        var ring: [String] = []
        ring.reserveCapacity(vertices + 1)

        for vertexIndex in 0 ..< vertices {
            let angle = Double(vertexIndex) / Double(vertices) * 2.0 * Double.pi
            let radius = 3.0 + random.nextDouble()
            ring.append("[\(centerX + radius * cos(angle)),\(centerY + radius * 0.9 * sin(angle))]")
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

private func makePropertyFeatures(count: Int) -> FeatureCollection {
    var random = SeededRandom(seed: 11)
    let features = (0 ..< count).map { index in
        Feature(
            Point(Coordinate3D(
                latitude: random.next(in: -10.0 ... 10.0),
                longitude: random.next(in: -10.0 ... 10.0))),
            properties: [
                "name": "feature-\(index)",
                "level": index % 5,
                "population": index * 10,
            ])
    }
    return FeatureCollection(features)
}

private func makeGridCollection(size: Int) -> FeatureCollection {
    var features: [Feature] = []
    features.reserveCapacity(size * 2)

    // One LineString per row and column keeps the fixture compact while
    // producing the same size × size grid: size² nodes and 2·size·(size−1)
    // directed edge instances.
    for y in 0 ..< size {
        let row = (0 ..< size).map { x in
            Coordinate3D(latitude: Double(y) * 0.001, longitude: Double(x) * 0.001)
        }
        features.append(Feature(LineString(unchecked: row)))
    }

    for x in 0 ..< size {
        let column = (0 ..< size).map { y in
            Coordinate3D(latitude: Double(y) * 0.001, longitude: Double(x) * 0.001)
        }
        features.append(Feature(LineString(unchecked: column)))
    }

    return FeatureCollection(features)
}

private func makeBoundingBox(_ radius: Double) -> BoundingBox {
    BoundingBox(
        southWest: Coordinate3D(latitude: -radius, longitude: -radius),
        northEast: Coordinate3D(latitude: radius, longitude: radius))
}

// MARK: - Loading

private func runLoading() {
    let data = try! Data(contentsOf: URL(fileURLWithPath: fixturePath))

    run("loading/native", iterations: 5) {
        _ = FeatureCollection(jsonData: data)
    }

    run("loading/codable", iterations: 5) {
        _ = try? JSONDecoder().decode(FeatureCollection.self, from: data)
    }
}

// MARK: - Projection (ported from ProjectionBenchmarks)

private func baselineForward3857(_ coordinate: Coordinate3D) -> (Double, Double) {
    let x = coordinate.longitude * GISTool.originShift / 180.0
    var y: Double = log(tan((90.0 + coordinate.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
    y *= GISTool.originShift / 180.0
    return (x, y)
}

private func baselineInverse3857(_ coordinate: Coordinate3D) -> (Double, Double) {
    let expArgument = (coordinate.latitude / GISTool.originShift) * 180.0 * Double.pi / 180.0
    let latitude = 180.0 / Double.pi * ((2.0 * atan(exp(expArgument))) - (Double.pi / 2.0))
    let longitude = (coordinate.longitude / GISTool.originShift) * 180.0
    return (latitude, longitude)
}

private func runProjection() {
    var coordinates: [Coordinate3D] = []
    coordinates.reserveCapacity(10_000)
    for index in 0 ..< 10_000 {
        let latitude = Double(index % 170_000) / 1_000.0 - 85.0
        let longitude = Double((index * 7) % 360_000) / 1_000.0 - 180.0
        let altitude = Double(index % 200)
        coordinates.append(Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude))
    }
    let mercator = coordinates.map { coordinate -> Coordinate3D in
        let (x, y) = baselineForward3857(coordinate)
        return Coordinate3D(x: x, y: y, projection: .epsg3857)
    }

    run("projection/baseline-4326-to-3857", iterations: 5) {
        for coordinate in coordinates { _ = baselineForward3857(coordinate) }
    }
    run("projection/registry-4326-to-3857", iterations: 5) {
        for coordinate in coordinates { _ = coordinate.projected(to: .epsg3857) }
    }
    run("projection/baseline-3857-to-4326", iterations: 5) {
        for coordinate in mercator { _ = baselineInverse3857(coordinate) }
    }
    run("projection/registry-3857-to-4326", iterations: 5) {
        for coordinate in mercator { _ = coordinate.projected(to: .epsg4326) }
    }
    run("projection/registry-4326-4978-4326", iterations: 5) {
        for coordinate in coordinates { _ = coordinate.projected(to: .epsg4978).projected(to: .epsg4326) }
    }
    run("projection/batch-4326-to-3857", iterations: 5) {
        _ = coordinates.projected(to: .epsg3857)
    }
    run("projection/batch-4326-32619-4326", iterations: 5) {
        _ = coordinates.projected(to: .epsg32619).projected(to: .epsg4326)
    }
    run("projection/batch-4326-to-27700", iterations: 5) {
        _ = coordinates.projected(to: .epsg27700)
    }
    run("projection/registry-4326-32619-4326", iterations: 5) {
        for coordinate in coordinates { _ = coordinate.projected(to: .epsg32619).projected(to: .epsg4326) }
    }
}

// MARK: - Predicates

private func runPredicates() {
    let inside = Coordinate3D(latitude: 0.0, longitude: 0.0)
    let outsideBBoxMiss = Coordinate3D(latitude: 50.0, longitude: 50.0)
    let outsideBBoxHit = Coordinate3D(latitude: 10.5, longitude: 0.0)
    let boundary = Coordinate3D(latitude: 10.0, longitude: 0.0)

    for vertices in [1_000, 10_000, 100_000] {
        let polygon = makeCirclePolygon(vertices: vertices)
        let prepared = polygon.prepared()
        let suffix = "\(vertices)"

        run("predicate/contains-inside/\(suffix)", iterations: 5) {
            _ = polygon.contains(inside)
        }
        run("predicate/contains-bbox-miss/\(suffix)", iterations: 5) {
            _ = polygon.contains(outsideBBoxMiss)
        }
        run("predicate/locate-bbox-hit/\(suffix)", iterations: 5) {
            _ = polygon.locate(outsideBBoxHit)
        }
        run("predicate/locate-boundary/\(suffix)", iterations: 5) {
            _ = polygon.locate(boundary)
        }
        run("predicate/prepared-contains-inside/\(suffix)", iterations: 5) {
            _ = prepared.contains(inside)
        }
        run("predicate/prepared-locate-boundary/\(suffix)", iterations: 5) {
            _ = prepared.locate(boundary)
        }

        var random = SeededRandom(seed: 31)
        let queryPoints = (0 ..< 1_000).map { _ in
            Coordinate3D(
                latitude: random.next(in: -15.0 ... 15.0),
                longitude: random.next(in: -15.0 ... 15.0))
        }

        run("predicate/contains-repeated/\(suffix)", iterations: 3) {
            for point in queryPoints {
                _ = polygon.contains(point)
            }
        }
        run("predicate/prepared-contains-repeated/\(suffix)", iterations: 3) {
            for point in queryPoints {
                _ = prepared.contains(point)
            }
        }
    }

    let a = makeCirclePolygon(vertices: 1_000)
    let b = makeCirclePolygon(vertices: 1_000, radius: 5.0)
    let preparedA = a.prepared()
    run("predicate/polygon-contains-polygon/1000", iterations: 3) {
        _ = a.contains(b)
    }
    run("predicate/prepared-polygon-contains-polygon/1000", iterations: 3) {
        _ = preparedA.contains(b)
    }
    run("predicate/polygon-intersects-polygon/1000", iterations: 3) {
        _ = a.intersects(b)
    }

    let largeA = makeCirclePolygon(vertices: 10_000)
    let largeB = makeCirclePolygon(vertices: 10_000, radius: 5.0)
    let preparedLargeA = largeA.prepared()
    run("predicate/polygon-contains-polygon/10000", iterations: 3) {
        _ = largeA.contains(largeB)
    }
    run("predicate/prepared-polygon-contains-polygon/10000", iterations: 3) {
        _ = preparedLargeA.contains(largeB)
    }
}

// MARK: - Overlay

private func runOverlay() {
    for vertices in [1_000, 10_000, 100_000] {
        let a = makeCirclePolygon(vertices: vertices)
        let b = makeCirclePolygon(vertices: vertices, radius: 8.0)
        let suffix = vertices == 1_000 ? "" : "/\(vertices)"
        let iterations = vertices == 1_000 ? 3 : (vertices == 10_000 ? 2 : 1)

        run("overlay/union\(suffix)", iterations: iterations) { _ = a.union(with: b) }
        run("overlay/intersection\(suffix)", iterations: iterations) {
            _ = a.intersection(with: b)
        }
        run("overlay/difference\(suffix)", iterations: iterations) {
            _ = a.difference(with: b)
        }
        run("overlay/symmetric-difference\(suffix)", iterations: iterations) {
            _ = a.symmetricDifference(with: b)
        }
    }
}

// MARK: - R-tree

private func runRTree() {
    var random = SeededRandom(seed: 13)
    let points = (0 ..< 100_000).map { _ in
        Point(Coordinate3D(
            latitude: random.next(in: -10.0 ... 10.0),
            longitude: random.next(in: -10.0 ... 10.0)))
    }
    let searchBox = makeBoundingBox(1.0)

    run("rtree/build-hilbert/100k", iterations: 3) {
        _ = RTree(points, nodeSize: 16, sortOption: .hilbert)
    }
    run("rtree/build-unsorted/100k", iterations: 3) {
        _ = RTree(points, nodeSize: 16, sortOption: .unsorted)
    }
    run("rtree/build-by-latitude/100k", iterations: 3) {
        _ = RTree(points, nodeSize: 16, sortOption: .byLatitude)
    }
    run("rtree/build-by-longitude/100k", iterations: 3) {
        _ = RTree(points, nodeSize: 16, sortOption: .byLongitude)
    }

    let tree = RTree(points, nodeSize: 16, sortOption: .hilbert)
    run("rtree/search-hilbert/100k", iterations: 5) {
        _ = tree.search(inBoundingBox: searchBox)
    }
    run("rtree/search-serial/100k", iterations: 5) {
        _ = tree.searchSerial(inBoundingBox: searchBox)
    }
    run("rtree/search-around/100k", iterations: 5) {
        _ = tree.search(aroundCoordinate: .zero, maximumDistance: 100_000.0)
    }
}

// MARK: - Coders

private func runCoders() {
    let polygon = makeCirclePolygon(vertices: 100_000)

    if let wkb = polygon.asWKB {
        print("size/wkb=\(wkb.count)")
        run("coder/wkb-decode/100k", iterations: 3) {
            _ = try? WKBCoder.decode(wkb: wkb, sourceProjection: .epsg4326)
        }
    }
    run("coder/wkb-encode/100k", iterations: 3) {
        _ = polygon.asWKB
    }

    if let wkt = polygon.asWKT {
        print("size/wkt=\(wkt.utf8.count)")
        run("coder/wkt-decode/100k", iterations: 3) {
            _ = try? WKTCoder.decode(wkt: wkt, sourceProjection: .epsg4326)
        }
    }
    run("coder/wkt-encode/100k", iterations: 3) {
        _ = polygon.asWKT
    }

    runGeoJsonCoder("point", geoJson: Point(Coordinate3D(latitude: 47.0, longitude: 11.0)))
    runGeoJsonCoder("multipoint/10k", geoJson: MultiPoint(unchecked: (0 ..< 10_000).map { index in
        Coordinate3D(latitude: 47.0 + Double(index) * 0.0001, longitude: 11.0)
    }))
    runGeoJsonCoder("linestring/100k", geoJson: makeLineString(vertices: 100_000))
    runGeoJsonCoder("multilinestring/10x1k", geoJson: MultiLineString(unchecked: (0 ..< 10).map { _ in
        makeLineString(vertices: 1_000).coordinates
    }))
    runGeoJsonCoder("polygon/100k", geoJson: polygon)
    runGeoJsonCoder("multipolygon/10x10k", geoJson: MultiPolygon(unchecked: (0 ..< 10).map { _ in
        makeCirclePolygon(vertices: 10_000)
    }))
    runGeoJsonCoder("geometrycollection", geoJson: GeometryCollection([
        makeLineString(vertices: 100_000),
        polygon,
    ]))

    let properties = Dictionary(uniqueKeysWithValues: (0 ..< 1_000).map { index in
        ("property\(index)", index)
    })
    runGeoJsonCoder("feature/properties-1k", geoJson: Feature(
        Point(Coordinate3D(latitude: 47.0, longitude: 11.0)),
        properties: properties))
    runGeoJsonCoder("featurecollection/100x1k", geoJson: FeatureCollection((0 ..< 100).map { _ in
        Feature(makeLineString(vertices: 1_000))
    }))

    run("coder/geojson-encode-pretty/100k", iterations: 2) {
        _ = polygon.asJsonData(prettyPrinted: true)
    }

    run("coder/codable-encode/100k", iterations: 2) {
        _ = try? JSONEncoder().encode(polygon)
    }
    if let data = try? JSONEncoder().encode(polygon) {
        run("coder/codable-decode/100k", iterations: 3) {
            _ = try? JSONDecoder().decode(Polygon.self, from: data)
        }
    }
}

private func runGeoJsonCoder(_ name: String, geoJson: any GeoJson) {
    guard let data = geoJson.asJsonData() else { return }

    print("size/geojson/\(name)=\(data.count)")

    run("coder/geojson-encode/\(name)", iterations: 2) {
        _ = geoJson.asJsonData()
    }
    run("coder/geojson-decode/\(name)", iterations: 3) {
        _ = GeoJsonReader.geoJsonFrom(jsonData: data)
    }
}

// MARK: - Buffer

private func runBuffer() {
    let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
    let line = makeLineString(vertices: 200)
    let polygon = makeCirclePolygon(vertices: 200)

    run("buffer/point/steps-8", iterations: 2) { _ = point.buffered(by: 10.0, steps: 8) }
    run("buffer/point/steps-32", iterations: 2) { _ = point.buffered(by: 10.0, steps: 32) }
    run("buffer/line/steps-8", iterations: 2) { _ = line.buffered(by: 1.0, steps: 8) }
    run("buffer/line/steps-32", iterations: 2) { _ = line.buffered(by: 1.0, steps: 32) }
    run("buffer/polygon/steps-8", iterations: 2) { _ = polygon.buffered(by: 1.0, steps: 8) }
    run("buffer/polygon/steps-32", iterations: 2) { _ = polygon.buffered(by: 1.0, steps: 32) }

    let largeLine = makeLineString(vertices: 1_000)
    let largePolygon = makeCirclePolygon(vertices: 1_000)
    run("buffer/line/1k/steps-8", iterations: 1) { _ = largeLine.buffered(by: 0.01, steps: 8) }
    run("buffer/line/1k/steps-32", iterations: 1) { _ = largeLine.buffered(by: 0.01, steps: 32) }
    run("buffer/polygon/1k/steps-8", iterations: 1) { _ = largePolygon.buffered(by: 0.01, steps: 8) }
    run("buffer/polygon/1k/steps-32", iterations: 1) { _ = largePolygon.buffered(by: 0.01, steps: 32) }

    let veryLargeLine = makeLineString(vertices: 10_000)
    let veryLargePolygon = makeCirclePolygon(vertices: 10_000)
    run("buffer/line/10k/steps-8", iterations: 1) { _ = veryLargeLine.buffered(by: 0.001, steps: 8) }
    run("buffer/polygon/10k/steps-8", iterations: 1) { _ = veryLargePolygon.buffered(by: 0.001, steps: 8) }
}

// MARK: - Simplify

private func runSimplify() {
    let line = makeLineString(vertices: 100_000)
    let polygon = makeCirclePolygon(vertices: 100_000)

    run("simplify/line-dp/100k", iterations: 3) {
        _ = line.simplified(tolerance: 0.0001)
    }
    run("simplify/line-vw/100k", iterations: 3) {
        _ = line.simplified(tolerance: 0.0001, highQuality: true)
    }
    run("simplify/polygon-dp/100k", iterations: 3) {
        _ = polygon.simplified(tolerance: 0.0001)
    }
}

// MARK: - Hulls / tessellation

private func runHulls() {
    let points = makePointCloud(count: 10_000)
    let polygon = makeCirclePolygon(vertices: 10_000)

    let points1k = makePointCloud(count: 1_000)
    let points50k = makePointCloud(count: 50_000)
    let concaveMaxEdge = 200_000.0

    run("hulls/convex/10k", iterations: 3) { _ = points.convexHull() }
    run("hulls/concave/1k", iterations: 3) {
        _ = points1k.concaveHull(maxEdgeLength: concaveMaxEdge)
    }
    run("hulls/concave/10k", iterations: 2) {
        _ = points.concaveHull(maxEdgeLength: concaveMaxEdge)
    }
    run("hulls/concave/50k", iterations: 1) {
        _ = points50k.concaveHull(maxEdgeLength: concaveMaxEdge)
    }
    run("hulls/concave/filter-only/10k", iterations: 2) {
        _ = points.concaveHull(maxEdgeLength: 1_000.0)
    }
    run("hulls/minimum-bounding-circle/10k", iterations: 3) { _ = points.minimumBoundingCircle() }
    run("hulls/oriented-envelope/10k", iterations: 3) { _ = points.orientedEnvelope() }
    run("hulls/pole-of-inaccessibility/10k", iterations: 3) { _ = polygon.poleOfInaccessibility() }
    run("hulls/voronoi/10k", iterations: 3) {
        _ = FeatureCollection(points.points).voronoiDiagram(boundingBox: makeBoundingBox(12.0))
    }
    run("hulls/tesselate/10k", iterations: 3) { _ = polygon.tesselated() }
    run("hulls/tin/10k", iterations: 3) { _ = points.tin() }
}

// MARK: - Line operations

private func runLineOperations() {
    let line = makeLineString(vertices: 10_000)

    run("line/coordinate-along/10k", iterations: 3) {
        _ = line.coordinateAlong(distance: 5.0)
    }
    run("line/chunked/10k", iterations: 3) {
        _ = line.chunked(segmentLength: 10_000.0)
    }
    run("line/bezier-spline/10k", iterations: 3) {
        _ = line.bezierSpline()
    }
}

// MARK: - Tile cover / clip

private func runTileCover() {
    let polygon = makeCirclePolygon(vertices: 10_000)

    for zoom in [8, 10, 12] {
        run("tile/cover-z\(zoom)", iterations: 3) {
            _ = polygon.tileCover(atZoom: zoom)
        }
    }
}

private func runClip() {
    let polygon = makeCirclePolygon(vertices: 100_000)

    run("clip/polygon-bbox/100k", iterations: 3) {
        _ = polygon.clipped(to: makeBoundingBox(5.0))
    }
}

// MARK: - Graph

private func runGraph() {
    // size 71 → ~10k edges / 5k nodes
    // size 224 → ~100k edges / 50k nodes
    // size 708 → ~1M edges / 500k nodes
    let cases: [(label: String, size: Int, iterations: Int)] = [
        ("10k", 71, 3),
        ("100k", 224, 3),
        ("1M", 708, 1),
    ]

    for benchmark in cases {
        let collection = makeGridCollection(size: benchmark.size)
        let graph = Graph(featureCollection: collection)

        run("graph/construction/\(benchmark.label)", iterations: benchmark.iterations) {
            _ = Graph(featureCollection: collection)
        }

        guard let start = graph.nodes.first, let end = graph.nodes.last else { continue }

        run("graph/dijkstra/\(benchmark.label)", iterations: benchmark.iterations) {
            _ = graph.shortestPath(from: start, to: end)
        }
        run("graph/a-star/\(benchmark.label)", iterations: benchmark.iterations) {
            _ = graph.aStarPath(from: start, to: end)
        }
        run("graph/bidirectional/\(benchmark.label)", iterations: benchmark.iterations) {
            _ = graph.bidirectionalShortestPath(from: start, to: end)
        }

        if benchmark.size <= 224 {
            let lineGraphs = collection.features.map { feature in
                Graph(featureCollection: FeatureCollection([feature]))
            }
            run("graph/merge/\(benchmark.label)", iterations: 1) {
                _ = Graph.merged(
                    lineGraphs,
                    stitchingTolerance: 0.0)
            }
            run("graph/merge-stitched/\(benchmark.label)", iterations: 1) {
                _ = Graph.merged(lineGraphs)
            }
        }

        // Contraction is built once, then queried on the contracted graph.
        // Grid interiors have degree 4, so only the four corners are degree-2
        // candidates; this intentionally measures the no-benefit case.
        if let contraction = graph.contracted() {
            run("graph/contraction-build/\(benchmark.label)", iterations: 1) {
                _ = graph.contracted()
            }

            let queryStartIndex = min(benchmark.size + 1, graph.nodeCount - 1)
            let queryEndIndex = max(graph.nodeCount - benchmark.size - 2, 0)
            if let queryStart = graph.node(withIndex: queryStartIndex),
               let queryEnd = graph.node(withIndex: queryEndIndex),
               let contractedStartIndex = contraction.contractedIndexOfOriginal[queryStart.index],
               let contractedEndIndex = contraction.contractedIndexOfOriginal[queryEnd.index],
               let contractedStart = contraction.graph.node(withIndex: contractedStartIndex),
               let contractedEnd = contraction.graph.node(withIndex: contractedEndIndex)
            {
                run("graph/contraction-dijkstra/\(benchmark.label)", iterations: 1) {
                    _ = contraction.graph.shortestPath(from: contractedStart, to: contractedEnd)
                }
            }
        }

        if benchmark.size <= 224 {
            run("graph/bfs/\(benchmark.label)", iterations: benchmark.iterations) {
                _ = graph.breadthFirstSearch(from: start)
            }
            run("graph/dfs/\(benchmark.label)", iterations: benchmark.iterations) {
                _ = graph.depthFirstSearch(from: start)
            }
            run("graph/cycles/\(benchmark.label)", iterations: 1) {
                _ = graph.cycles(
                    from: start,
                    maximumPathLength: 2_000.0,
                    maximumPathNodeCount: 10,
                    maximumFromSourceDistance: 2_000.0)
            }
        }
    }
}

// MARK: - Real-world graphs

private enum RealWorldProfile: String, CaseIterable {

    case hiking
    case cycling
    case car

    func accepts(_ edge: Edge) -> Bool {
        guard let type: String = edge.feature?.property(for: "type") else { return false }
        let access: String? = edge.feature?.property(for: "access")
        let bicycle: String? = edge.feature?.property(for: "bicycle")
        let foot: String? = edge.feature?.property(for: "foot")

        switch self {
        case .hiking:
            guard ["footway", "path", "track", "pedestrian", "steps"].contains(type)
            else { return false }
            return foot != "no" && access != "no" && access != "private"

        case .cycling:
            if bicycle == "no" || bicycle == "private" || access == "no" || access == "private" {
                return false
            }
            let roadTypes: Set<String> = [
                "cycleway", "residential", "primary", "secondary", "tertiary",
                "service", "living_street", "track", "unclassified", "path", "footway",
            ]
            guard roadTypes.contains(type) else { return false }
            if type == "footway" || type == "path" {
                return bicycle == "yes"
                    || bicycle == "designated"
                    || bicycle == "permissive"
                    || bicycle == "official"
            }
            return true

        case .car:
            if access == "no" || access == "private" { return false }
            let roadTypes: Set<String> = [
                "motorway", "motorway_link", "trunk", "trunk_link",
                "primary", "primary_link", "secondary", "secondary_link",
                "tertiary", "tertiary_link", "residential", "service",
                "living_street", "unclassified",
            ]
            return roadTypes.contains(type)
        }
    }

}

private struct RealWorldDataset {

    let name: String
    let prefix: String
    let xRange: ClosedRange<Int>
    let yRange: ClosedRange<Int>
    let iterations: Int
    let isDirected: Bool

}

private let realWorldDatasets: [RealWorldDataset] = [
    RealWorldDataset(
        name: "allgaeu",
        prefix: "allgaeu_",
        xRange: 8647 ... 8657,
        yRange: 5723 ... 5725,
        iterations: 2,
        isDirected: false),
    RealWorldDataset(
        name: "munich",
        prefix: "munich_",
        xRange: 8717 ... 8719,
        yRange: 5684 ... 5685,
        iterations: 2,
        isDirected: false),
    RealWorldDataset(
        name: "munich-directed",
        prefix: "munich_",
        xRange: 8717 ... 8719,
        yRange: 5684 ... 5685,
        iterations: 2,
        isDirected: true),
    RealWorldDataset(
        name: "paris",
        prefix: "paris_",
        xRange: 8295 ... 8301,
        yRange: 5632 ... 5639,
        iterations: 1,
        isDirected: false),
]

private func loadRealWorldCollections(_ dataset: RealWorldDataset) -> [FeatureCollection] {
    var collections: [FeatureCollection] = []
    collections.reserveCapacity(
        (dataset.xRange.upperBound - dataset.xRange.lowerBound + 1)
            * (dataset.yRange.upperBound - dataset.yRange.lowerBound + 1))

    for x in dataset.xRange {
        for y in dataset.yRange {
            let path = "\(graphFixtureDirectory)/\(dataset.prefix)14_\(x)_\(y).geojson.gz"
            let data = try! Data(contentsOf: URL(fileURLWithPath: path))
            collections.append(FeatureCollection(jsonData: data)!)
        }
    }
    return collections
}

private func makeRealWorldGraph(
    _ collections: [FeatureCollection],
    isDirected: Bool
) -> Graph {
    Graph.merged(
        collections.map {
            Graph(
                featureCollection: $0,
                isDirected: isDirected)
        },
        stitchingTolerance: 1.0)
}

private func realWorldEndpoints(
    in graph: Graph,
    filter: (Edge) -> Bool
) -> (Node, Node)? {
    var visited: Set<Int> = []
    var best: (seed: Node, reachable: [Node])?

    for node in graph.nodes where !visited.contains(node.index) {
        visited.insert(node.index)

        var component: [Node] = [node]
        var queue: [Node] = [node]

        while let current = queue.popLast() {
            for edge in graph.edges(for: current) where filter(edge) {
                guard visited.insert(edge.to.index).inserted else { continue }
                queue.append(edge.to)
                component.append(edge.to)
            }
        }

        if best == nil || component.count > best!.reachable.count {
            best = (node, component)
        }
    }

    guard let best, best.reachable.count >= 2 else { return nil }
    let seed = best.seed
    let end = best.reachable.max {
        $0.coordinate.distance(from: seed.coordinate)
            < $1.coordinate.distance(from: seed.coordinate)
    } ?? best.reachable[1]

    return (seed, end)
}

private func runRealWorldGraph() {
    for dataset in realWorldDatasets {
        let firstPath = "\(graphFixtureDirectory)/\(dataset.prefix)14_\(dataset.xRange.lowerBound)_\(dataset.yRange.lowerBound).geojson.gz"
        guard FileManager.default.fileExists(atPath: firstPath) else {
            print("realworld/\(dataset.name) skipped: fixtures not found at \(graphFixtureDirectory)")
            continue
        }

        run("graph/real/load/\(dataset.name)", iterations: 1) {
            _ = loadRealWorldCollections(dataset)
        }

        let collections = loadRealWorldCollections(dataset)
        run("graph/real/build-merge/\(dataset.name)", iterations: 1) {
            _ = makeRealWorldGraph(
                collections,
                isDirected: dataset.isDirected)
        }

        let graph = makeRealWorldGraph(
            collections,
            isDirected: dataset.isDirected)
        print(String(
            format: "graph/real/memory/%@/rss-mb=%.1f peak-rss-mb=%.1f",
            dataset.name,
            currentRSSMegabytes(),
            peakRSSMegabytes()))

        for profile in RealWorldProfile.allCases {
            guard let (start, end) = realWorldEndpoints(
                in: graph,
                filter: { profile.accepts($0) })
            else {
                print("realworld/\(dataset.name)/\(profile.rawValue) skipped: no filtered component")
                continue
            }

            run(
                "graph/real/\(dataset.name)/\(profile.rawValue)/dijkstra",
                iterations: dataset.iterations
            ) {
                _ = graph.shortestPath(
                    from: start,
                    to: end,
                    edgeFilter: { profile.accepts($0) })
            }
        }

        if let cycling = RealWorldProfile(rawValue: "cycling"),
           let (start, end) = realWorldEndpoints(
            in: graph,
            filter: { cycling.accepts($0) })
        {
            run(
                "graph/real/\(dataset.name)/cycling/a-star",
                iterations: dataset.iterations
            ) {
                _ = graph.aStarPath(
                    from: start,
                    to: end,
                    edgeFilter: { cycling.accepts($0) })
            }
            run(
                "graph/real/\(dataset.name)/cycling/bidirectional",
                iterations: dataset.iterations
            ) {
                _ = graph.bidirectionalShortestPath(
                    from: start,
                    to: end,
                    edgeFilter: { cycling.accepts($0) })
            }
        }

        guard let contraction = graph.contracted() else { continue }

        run("graph/real/\(dataset.name)/contraction-build", iterations: 1) {
            _ = graph.contracted()
        }

        let contractedEndpoints: (Node, Node)?
        if let (queryStart, queryEnd) = realWorldEndpoints(
            in: graph,
            filter: { _ in true }),
           let contractedStartIndex = contraction.contractedIndexOfOriginal[queryStart.index],
           let contractedEndIndex = contraction.contractedIndexOfOriginal[queryEnd.index],
           let contractedStart = contraction.graph.node(withIndex: contractedStartIndex),
           let contractedEnd = contraction.graph.node(withIndex: contractedEndIndex)
        {
            contractedEndpoints = (contractedStart, contractedEnd)
        }
        else if let first = contraction.graph.nodes.first,
                let last = contraction.graph.nodes.last
        {
            contractedEndpoints = (first, last)
        }
        else {
            contractedEndpoints = nil
        }

        guard let contractedEndpoints else { continue }

        run("graph/real/\(dataset.name)/contraction-dijkstra", iterations: 1) {
            _ = contraction.graph.shortestPath(
                from: contractedEndpoints.0,
                to: contractedEndpoints.1)
        }
    }
}

// MARK: - Clusters

private func runClusters() {
    let collection = makePropertyFeatures(count: 500)

    run("clusters/kmeans/500", iterations: 2) {
        _ = collection.kmeansClusters(numberOfClusters: 5)
    }
    run("clusters/dbscan/500", iterations: 2) {
        _ = collection.dbscanClusters(maxDistance: 2.0, minPoints: 3)
    }
}

// MARK: - Query DSL

private func runQuery() {
    let collection = makePropertyFeatures(count: 10_000)
    let query = ".level == 2 and .population > 1000"
    let parser = QueryParser(string: query)

    run("query/parse") {
        _ = QueryParser(string: query)
    }
    run("query/evaluate/10k", iterations: 3) {
        guard let parser else { return }
        for feature in collection.features {
            _ = parser.evaluate(on: feature)
        }
    }
}

// MARK: - Memory

private func runMemory() {
    print("memory/Coordinate3D/size=\(MemoryLayout<Coordinate3D>.size)")
    print("memory/Coordinate3D/stride=\(MemoryLayout<Coordinate3D>.stride)")
    print("memory/Projection/size=\(MemoryLayout<Projection>.size)")
    print("memory/Projection/stride=\(MemoryLayout<Projection>.stride)")
    print("memory/Point/stride=\(MemoryLayout<Point>.stride)")
    print("memory/LineString/stride=\(MemoryLayout<LineString>.stride)")
    print("memory/Polygon/stride=\(MemoryLayout<Polygon>.stride)")
    print("memory/MultiPolygon/stride=\(MemoryLayout<MultiPolygon>.stride)")
    print("memory/Feature/stride=\(MemoryLayout<Feature>.stride)")
    print("memory/FeatureCollection/stride=\(MemoryLayout<FeatureCollection>.stride)")
    print("memory/BoundingBox/stride=\(MemoryLayout<BoundingBox>.stride)")
    print("memory/CoordinateArray/100k=\(100_000 * MemoryLayout<Coordinate3D>.stride)")

    let baseline = currentRSSMegabytes()

    var pointFeatures: [Feature] = []
    pointFeatures.reserveCapacity(100_000)
    for index in 0 ..< 100_000 {
        pointFeatures.append(Feature(Point(Coordinate3D(
            latitude: Double(index % 1_000) / 100.0,
            longitude: Double(index / 1_000) / 100.0))))
    }
    let pointCollection = FeatureCollection(pointFeatures)
    let pointPeak = currentRSSMegabytes()

    var polygonFeatures: [Feature] = []
    polygonFeatures.reserveCapacity(10_000)
    for index in 0 ..< 10_000 {
        let x = Double(index % 100)
        let y = Double(index / 100)
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: y, longitude: x),
            Coordinate3D(latitude: y, longitude: x + 0.01),
            Coordinate3D(latitude: y + 0.01, longitude: x + 0.01),
            Coordinate3D(latitude: y + 0.01, longitude: x),
            Coordinate3D(latitude: y, longitude: x),
        ]])
        polygonFeatures.append(Feature(polygon))
    }
    let polygonCollection = FeatureCollection(polygonFeatures)
    let polygonPeak = currentRSSMegabytes()

    print(String(format: "memory/point-features/100k/peak-mb=%.1f", pointPeak - baseline))
    print(String(format: "memory/point-features/100k/bytes-per-feature=%.0f", (pointPeak - baseline) * 1_048_576.0 / 100_000.0))
    print(String(format: "memory/polygon-features/10k/peak-mb=%.1f", polygonPeak - pointPeak))
    print(String(format: "memory/polygon-features/10k/bytes-per-feature=%.0f", (polygonPeak - pointPeak) * 1_048_576.0 / 10_000.0))

    withExtendedLifetime((pointCollection, polygonCollection)) {}
}

// MARK: - Inlining

private func runInlining() {
    let boxes = (0 ..< 100_000).map { index in
        let x = Double(index % 1_000)
        let y = Double(index / 1_000)
        return BoundingBox(
            southWest: Coordinate3D(latitude: y, longitude: x),
            northEast: Coordinate3D(latitude: y + 1.0, longitude: x + 1.0))
    }
    let projectedPoints = (0 ..< 100_000).map { index in
        Coordinate3D(
            x: Double(index % 1_000),
            y: Double(index / 1_000),
            projection: .epsg3857)
    }
    let point = Coordinate3D(latitude: 0.5, longitude: 0.5)

    var sink = 0.0

    run("inline/bbox-corners/100k", iterations: 5) {
        var sum = 0.0
        for box in boxes {
            sum += box.southWest.x
                + box.southWest.y
                + box.northEast.x
                + box.northEast.y
                + box.northWest.y
                + box.southEast.x
        }
        sink += sum
    }

    run("inline/bbox-contains/100k", iterations: 5) {
        var count = 0
        for box in boxes where box.contains(point) {
            count += 1
        }
        sink += Double(count)
    }

    run("inline/coordinate-isCoincident/100k", iterations: 5) {
        var count = 0
        for coordinate in projectedPoints where coordinate.isCoincident(to: projectedPoints[0]) {
            count += 1
        }
        sink += Double(count)
    }

    run("inline/coordinate-distance/100k", iterations: 5) {
        var sum = 0.0
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857)
        for coordinate in projectedPoints {
            sum += coordinate.distance(to: origin)
        }
        sink += sum
    }

    print(String(format: "inline/checksum=%.1f", sink))
}

// MARK: - Entry point

let arguments = CommandLine.arguments
let suite = arguments.count >= 2 ? arguments[1] : "help"

func runSuite(_ name: String, _ block: () -> Void) {
    print("suite=\(name)")
    block()
    print(String(format: "peak_rss_mb=%.1f", peakRSSMegabytes()))
}

switch suite {
case "gen":
    let data = makeFeatureCollection(features: 400, vertices: 1_600)
    try data.write(to: URL(fileURLWithPath: fixturePath))
    print("generated path=\(fixturePath) bytes=\(data.count)")

case "loading": runSuite("loading", runLoading)
case "projection": runSuite("projection", runProjection)
case "predicates": runSuite("predicates", runPredicates)
case "overlay": runSuite("overlay", runOverlay)
case "rtree": runSuite("rtree", runRTree)
case "coders": runSuite("coders", runCoders)
case "buffer": runSuite("buffer", runBuffer)
case "simplify": runSuite("simplify", runSimplify)
case "hulls": runSuite("hulls", runHulls)
case "line": runSuite("line", runLineOperations)
case "tile": runSuite("tile", runTileCover)
case "clip": runSuite("clip", runClip)
case "graph": runSuite("graph", runGraph)
case "realworld": runSuite("realworld", runRealWorldGraph)
case "query": runSuite("query", runQuery)
case "clusters": runSuite("clusters", runClusters)
case "memory": runSuite("memory", runMemory)
case "inlining": runSuite("inlining", runInlining)

case "all":
    for (name, block) in [
        ("loading", runLoading),
        ("projection", runProjection),
        ("predicates", runPredicates),
        ("overlay", runOverlay),
        ("rtree", runRTree),
        ("coders", runCoders),
        ("buffer", runBuffer),
        ("simplify", runSimplify),
        ("hulls", runHulls),
        ("line", runLineOperations),
        ("tile", runTileCover),
        ("clip", runClip),
        ("graph", runGraph),
        ("realworld", runRealWorldGraph),
        ("query", runQuery),
        ("clusters", runClusters),
        ("memory", runMemory),
        ("inlining", runInlining),
    ] {
        runSuite(name, block)
    }

default:
    print("usage: Benchmarks <gen|loading|projection|predicates|overlay|rtree|coders|buffer|simplify|hulls|line|tile|clip|graph|realworld|query|clusters|memory|inlining|all>")
    exit(1)
}

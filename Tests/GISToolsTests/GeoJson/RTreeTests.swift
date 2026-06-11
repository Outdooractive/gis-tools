#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

struct RTreeTests {

    // Verifies that an R-tree initialized with no nodes returns an empty search result.
    @Test
    func empty() async throws {
        let nodes: [Point] = []
        let rTree = RTree(nodes)
        let objects = rTree.search(inBoundingBox: BoundingBox.world)
        #expect(objects.isEmpty)
    }

    // MARK: -

    // Verifies R-tree bounding-box search with simple points in EPSG:4326 for Hilbert, latitude, and unsorted sort options.
    @Test
    func simplePoints4326() async throws {
        var nodes: [Point] = []
        5.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        let rTreeHilbert = RTree(nodes, nodeSize: 4)
        #expect(rTreeHilbert.projection == .epsg4326)
        _testSimplePoints(rTreeHilbert)

        let rTreeRandom = RTree(nodes, nodeSize: 4, sortOption: .byLatitude)
        #expect(rTreeRandom.projection == .epsg4326)
        _testSimplePoints(rTreeRandom)

        let rTreeAsInput = RTree(nodes, nodeSize: 4, sortOption: .unsorted)
        #expect(rTreeAsInput.projection == .epsg4326)
        _testSimplePoints(rTreeAsInput)
    }

    // Verifies R-tree bounding-box search with simple points in EPSG:3857 for Hilbert, latitude, and unsorted sort options.
    @Test
    func simplePoints3857() async throws {
        var nodes: [Point] = []
        5.times {
            nodes.append(Point(Coordinate3D(
                x: Double.random(in: -10.0 ... 10.0),
                y: Double.random(in: -10.0 ... 10.0),
                projection: .epsg3857)))
        }

        let rTreeHilbert = RTree(nodes, nodeSize: 4)
        #expect(rTreeHilbert.projection == .epsg3857)
        _testSimplePoints(rTreeHilbert)

        let rTreeRandom = RTree(nodes, nodeSize: 4, sortOption: .byLatitude)
        #expect(rTreeRandom.projection == .epsg3857)
        _testSimplePoints(rTreeRandom)

        let rTreeAsInput = RTree(nodes, nodeSize: 4, sortOption: .unsorted)
        #expect(rTreeAsInput.projection == .epsg3857)
        _testSimplePoints(rTreeAsInput)
    }

    private func _testSimplePoints(_ rTree: RTree<Point>) {
        var minX = Double.random(in: -10.0 ... 10.0)
        var maxX = Double.random(in: -10.0 ... 10.0)
        var minY = Double.random(in: -10.0 ... 10.0)
        var maxY = Double.random(in: -10.0 ... 10.0)

        if minX > maxX {
            (minX, maxX) = (maxX, minX)
        }
        if minY > maxY {
            (minY, maxY) = (maxY, minY)
        }

        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: minX, y: minY, projection: rTree.projection),
            northEast: Coordinate3D(x: maxX, y: maxY, projection: rTree.projection))

        let objects1 = rTree.search(inBoundingBox: boundingBox)
        let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)

        #expect(objects1.count == objects2.count)
        #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
    }

    // MARK: -

    // Verifies R-tree construction and search in EPSG:4326 across randomized node sizes and point counts.
    @Test
    func rTree4326() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }

            // Also test some invalid node sizes
            let rTreeHilbert = RTree(nodes, nodeSize: Int.random(in: -4 ... 16))
            #expect(rTreeHilbert.projection == .epsg4326)
            _testRTree(rTreeHilbert)

            let rTreeRandom = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .byLatitude)
            #expect(rTreeRandom.projection == .epsg4326)
            _testRTree(rTreeRandom)

            let rTreeAsInput = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .unsorted)
            #expect(rTreeAsInput.projection == .epsg4326)
            _testRTree(rTreeAsInput)
        }
    }

    // Verifies R-tree construction and search in EPSG:3857 across randomized node sizes and point counts.
    @Test
    func rTree3857() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: -10.0 ... 10.0),
                    y: Double.random(in: -10.0 ... 10.0),
                    projection: .epsg3857)))
            }

            // Also test some invalid node sizes
            let rTreeHilbert = RTree(nodes, nodeSize: Int.random(in: -4 ... 16))
            #expect(rTreeHilbert.projection == .epsg3857)
            _testRTree(rTreeHilbert)

            let rTreeRandom = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .byLatitude)
            #expect(rTreeRandom.projection == .epsg3857)
            _testRTree(rTreeRandom)

            let rTreeAsInput = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .unsorted)
            #expect(rTreeAsInput.projection == .epsg3857)
            _testRTree(rTreeAsInput)
        }
    }

    private func _testRTree(_ rTree: RTree<Point>) {
        var minX = Double.random(in: -10.0 ... 10.0)
        var maxX = Double.random(in: -10.0 ... 10.0)
        var minY = Double.random(in: -10.0 ... 10.0)
        var maxY = Double.random(in: -10.0 ... 10.0)

        if minX > maxX {
            (minX, maxX) = (maxX, minX)
        }
        if minY > maxY {
            (minY, maxY) = (maxY, minY)
        }

        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: minX, y: minY, projection: rTree.projection),
            northEast: Coordinate3D(x: maxX, y: maxY, projection: rTree.projection))

        let objects1 = rTree.search(inBoundingBox: boundingBox)
        let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)

        #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
    }

    // MARK: -

    // Verifies around-coordinate search in EPSG:4326 matches serial search results.
    @Test
    func aroundSearch4326() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 1000 ... 10000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }
            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg4326)
            _testAroundSearch(
                rTree,
                center: Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0)))
        }
    }

    // Verifies around-coordinate search in EPSG:3857 matches serial search results.
    @Test
    func aroundSearch3857() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 1000 ... 10000).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: -100_000.0 ... 100_000.0),
                    y: Double.random(in: -100_000.0 ... 100_000.0),
                    projection: .epsg3857)))
            }
            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg3857)
            _testAroundSearch(
                rTree,
                center: Coordinate3D(
                    x: Double.random(in: -100_000.0 ... 100_000.0),
                    y: Double.random(in: -100_000.0 ... 100_000.0)))
        }
    }

    private func _testAroundSearch(_ rTree: RTree<Point>, center: Coordinate3D) {
        let maximumDistance = Double.random(in: 10000.0 ... 100_000.0)

        let objects1 = rTree.search(aroundCoordinate: center, maximumDistance: maximumDistance)
        let objects2 = rTree.searchSerial(aroundCoordinate: center, maximumDistance: maximumDistance)

        assertCorrectDistance(result: objects1, from: center, maximumDistance: maximumDistance)
        assertCorrectDistance(result: objects2, from: center, maximumDistance: maximumDistance)

        #expect(objects1.map(\.object) == objects2.map(\.object))
    }

    private func assertCorrectDistance(
        result: [RTree<Point>.AroundSearchResult],
        from coordinate: Coordinate3D,
        maximumDistance: CLLocationDistance)
    {
        for (object, distance) in result {
            let objectDistance = object.coordinate.distance(from: coordinate)
            #expect(objectDistance == distance)
            #expect(objectDistance < maximumDistance)
        }
    }

    // MARK: -

    func _testNodeSizes() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: 5.0))

        for nodeSize in 4 ... 512 {
            for objectCount in stride(from: nodeSize * 2, to: 10000, by: 10) {
                var nodes: [Point] = []
                objectCount.times {
                    nodes.append(Point(Coordinate3D(
                        latitude: Double.random(in: -30.0 ... 30.0),
                        longitude: Double.random(in: -30.0 ... 30.0))))
                }
                let rTree = RTree(nodes, nodeSize: nodeSize)

                let startTime1 = Date().timeIntervalSinceReferenceDate
                let objects1 = rTree.search(inBoundingBox: boundingBox)
                let timeElapsed1 = Date().timeIntervalSinceReferenceDate - startTime1

                let startTime2 = Date().timeIntervalSinceReferenceDate
                let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)
                let timeElapsed2 = Date().timeIntervalSinceReferenceDate - startTime2

                #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })

                if timeElapsed1 < timeElapsed2 {
                    print("\(nodeSize): \(objectCount)")
                    break
                }
            }
        }
    }

}

// MARK: - Benchmarks

@Suite
struct RTreeBenchmarks {

    private static let iterations: Int = 10

    private static let performanceInput: [Point] = {
        let count = 100_000
        var nodes: [Point] = []
        nodes.reserveCapacity(count)
        count.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }
        return nodes
    }()

    private static let performanceSearchBoundingBox: BoundingBox = {
        var minX = Double.random(in: -10.0 ... 10.0)
        var maxX = Double.random(in: -10.0 ... 10.0)
        var minY = Double.random(in: -10.0 ... 10.0)
        var maxY = Double.random(in: -10.0 ... 10.0)

        if minX > maxX {
            (minX, maxX) = (maxX, minX)
        }
        if minY > maxY {
            (minY, maxY) = (maxY, minY)
        }

        return BoundingBox(
            southWest: Coordinate3D(latitude: minY, longitude: minX),
            northEast: Coordinate3D(latitude: maxY, longitude: maxX))
    }()

    private static let performanceAroundSearchCenter: Coordinate3D = Coordinate3D(
        latitude: Double.random(in: -10.0 ... 10.0),
        longitude: Double.random(in: -10.0 ... 10.0))

    private static func measure(_ name: String, _ block: () -> Void) {
        let clock = ContinuousClock()

        // Warmup
        block()

        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        for _ in 0 ..< iterations {
            let start = clock.now
            block()
            durations.append(clock.now - start)
        }

        let sorted = durations.sorted()
        let minMs = _milliseconds(sorted.first ?? .zero)
        let medianMs = _milliseconds(sorted[sorted.count / 2])
        let averageMs = durations.reduce(0.0) { $0 + _milliseconds($1) } / Double(iterations)

        print("[RTreeBenchmark] \(name): min=\(_format(minMs))ms median=\(_format(medianMs))ms avg=\(_format(averageMs))ms")
    }

    private static func _milliseconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) * 1_000.0 + Double(components.attoseconds) / 1e15
    }

    private static func _format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    // Measures R-tree build performance using Hilbert sort.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeHilbert() {
        Self.measure("BuildTree/hilbert") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .hilbert)
        }
    }

    // Measures R-tree build performance using latitude sort.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeLatitude() {
        Self.measure("BuildTree/byLatitude") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLatitude)
        }
    }

    // Measures R-tree build performance using longitude sort.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeLongitude() {
        Self.measure("BuildTree/byLongitude") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLongitude)
        }
    }

    // Measures R-tree build performance with unsorted input.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeUnsorted() {
        Self.measure("BuildTree/unsorted") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        }
    }

    // Measures serial bounding-box query performance on an unsorted R-tree.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQuerySerial() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("Query/serial") {
            _ = rTree.searchSerial(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures Hilbert-sorted R-tree bounding-box query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQueryHilbert() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .hilbert)
        Self.measure("Query/hilbert") {
            _ = rTree.search(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures latitude-sorted R-tree bounding-box query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQueryLatitude() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLatitude)
        Self.measure("Query/byLatitude") {
            _ = rTree.search(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures unsorted R-tree bounding-box query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQueryUnsorted() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("Query/unsorted") {
            _ = rTree.search(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures serial around-coordinate query performance on an unsorted R-tree.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchSerial() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("AroundSearch/serial") {
            _ = rTree.searchSerial(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

    // Measures Hilbert-sorted R-tree around-coordinate query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchHilbert() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .hilbert)
        Self.measure("AroundSearch/hilbert") {
            _ = rTree.search(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

    // Measures latitude-sorted R-tree around-coordinate query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchLatitude() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLatitude)
        Self.measure("AroundSearch/byLatitude") {
            _ = rTree.search(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

    // Measures unsorted R-tree around-coordinate query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchUnsorted() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("AroundSearch/unsorted") {
            _ = rTree.search(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

}

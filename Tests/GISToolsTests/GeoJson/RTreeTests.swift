#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class RTreeTests: XCTestCase {

    func testEmpty() throws {
        let nodes: [Point] = []
        let rTree = RTree(nodes)
        let objects = rTree.search(inBoundingBox: BoundingBox.world)
        XCTAssertTrue(objects.isEmpty)
    }

    // MARK: -

    func testSimplePoints() throws {
        var nodes: [Point] = []
        5.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        let rTreeHilbert = RTree(nodes, nodeSize: 4)
        _testSimplePoints(rTreeHilbert)

        let rTreeRandom = RTree(nodes, nodeSize: 4, sortOption: .random)
        _testSimplePoints(rTreeRandom)

        let rTreeAsInput = RTree(nodes, nodeSize: 4, sortOption: .unsorted)
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
            southWest: Coordinate3D(latitude: minY, longitude: minX),
            northEast: Coordinate3D(latitude: maxY, longitude: maxX))

        let objects1 = rTree.search(inBoundingBox: boundingBox)
        let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)

        XCTAssertEqual(objects1.count, objects2.count)
        XCTAssertEqual(
            objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude },
            objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
    }

    // MARK: -

    func testRTree() throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }

            // Also test some invalid node sizes
            let rTreeHilbert = RTree(nodes, nodeSize: Int.random(in: -4 ... 16))
            _testRTree(rTreeHilbert)

            let rTreeRandom = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .random)
            _testRTree(rTreeRandom)

            let rTreeAsInput = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .unsorted)
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
            southWest: Coordinate3D(latitude: minY, longitude: minX),
            northEast: Coordinate3D(latitude: maxY, longitude: maxX))

        let objects1 = rTree.search(inBoundingBox: boundingBox)
        let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)

        XCTAssertEqual(
            objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude },
            objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
    }

    // MARK: -

    func testAroundSearch() throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 1000 ... 10000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }
            let rTree = RTree(nodes)
            _testAroundSearch(rTree)
        }
    }

    private func _testAroundSearch(_ rTree: RTree<Point>) {
        let center = Coordinate3D(
            latitude: Double.random(in: -10.0 ... 10.0),
            longitude: Double.random(in: -10.0 ... 10.0))
        let maximumDistance = Double.random(in: 10000.0 ... 100000.0)

        let objects1 = rTree.search(aroundCoordinate: center, maximumDistance: maximumDistance)
        let objects2 = rTree.searchSerial(aroundCoordinate: center, maximumDistance: maximumDistance)

        assertCorrectDistance(result: objects1, from: center, maximumDistance: maximumDistance)
        assertCorrectDistance(result: objects2, from: center, maximumDistance: maximumDistance)

        XCTAssertEqual(objects1.map(\.object), objects2.map(\.object))
    }

    private func assertCorrectDistance(
        result: [RTree<Point>.AroundSearchResult],
        from coordinate: Coordinate3D,
        maximumDistance: CLLocationDistance)
    {
        for (object, distance) in result {
            let objectDistance = object.coordinate.distance(from: coordinate)
            XCTAssertEqual(objectDistance, distance)
            XCTAssertLessThan(objectDistance, maximumDistance)
        }
    }

    // MARK: -

    let performanceInput: [Point] = {
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

    var performanceSearchBoundingBox: BoundingBox {
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
    }

    var performanceAroundSearchCenter: Coordinate3D {
        return Coordinate3D(
            latitude: Double.random(in: -10.0 ... 10.0),
            longitude: Double.random(in: -10.0 ... 10.0))
    }

    let performanceOptions: XCTMeasureOptions = {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        return options
    }()

    func testHilbertPerformanceBuildTree() throws {
        measure(options: performanceOptions, block: {
            _ = RTree(performanceInput, nodeSize: 16, sortOption: .hilbert)
        })
    }

    func testRandomPerformanceBuildTree() throws {
        measure(options: performanceOptions, block: {
            _ = RTree(performanceInput, nodeSize: 16, sortOption: .random)
        })
    }

    func testUnsortedPerformanceBuildTree() throws {
        measure(options: performanceOptions, block: {
            _ = RTree(performanceInput, nodeSize: 16, sortOption: .unsorted)
        })
    }

    //

    func testHilbertPerformanceQuery() throws {
        let rTree = RTree(performanceInput, nodeSize: 16, sortOption: .hilbert)
        measure(options: performanceOptions, block: {
            _ = rTree.search(inBoundingBox: performanceSearchBoundingBox)
        })
    }

    func testRandomPerformanceQuery() throws {
        let rTree = RTree(performanceInput, nodeSize: 16, sortOption: .random)
        measure(options: performanceOptions, block: {
            _ = rTree.search(inBoundingBox: performanceSearchBoundingBox)
        })
    }

    func testUnsortedPerformanceQuery() throws {
        let rTree = RTree(performanceInput, nodeSize: 16, sortOption: .unsorted)
        measure(options: performanceOptions, block: {
            _ = rTree.search(inBoundingBox: performanceSearchBoundingBox)
        })
    }

    //

    func testHilbertPerformanceAroundSearch() throws {
        let maximumDistance = 100_000.0
        let rTree = RTree(performanceInput, nodeSize: 16, sortOption: .hilbert)
        measure(options: performanceOptions, block: {
            _ = rTree.search(aroundCoordinate: performanceAroundSearchCenter, maximumDistance: maximumDistance)
        })
    }

    func testRandomPerformanceAroundSearch() throws {
        let maximumDistance = 100_000.0
        let rTree = RTree(performanceInput, nodeSize: 16, sortOption: .random)
        measure(options: performanceOptions, block: {
            _ = rTree.search(aroundCoordinate: performanceAroundSearchCenter, maximumDistance: maximumDistance)
        })
    }

    func testUnsortedPerformanceAroundSearch() throws {
        let maximumDistance = 100_000.0
        let rTree = RTree(performanceInput, nodeSize: 16, sortOption: .unsorted)
        measure(options: performanceOptions, block: {
            _ = rTree.search(aroundCoordinate: performanceAroundSearchCenter, maximumDistance: maximumDistance)
        })
    }

    // MARK: -

    func _testNodeSizes() throws {
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

                let startTime1 = CFAbsoluteTimeGetCurrent()
                let objects1 = rTree.search(inBoundingBox: boundingBox)
                let timeElapsed1 = CFAbsoluteTimeGetCurrent() - startTime1

                let startTime2 = CFAbsoluteTimeGetCurrent()
                let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)
                let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2

                XCTAssertEqual(
                    objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude },
                    objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })

                if timeElapsed1 < timeElapsed2 {
                    print("\(nodeSize): \(objectCount)")
                    break
                }
            }
        }
    }

}

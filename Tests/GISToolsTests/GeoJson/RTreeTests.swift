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

    func testSimplePoints() throws {
        var nodes: [Point] = []
        try 5.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }
        let rTree = RTree(nodes, nodeSize: 4)

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

    func testRTree() throws {
        try 100.times {
            var nodes: [Point] = []
            try Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }
            // Also test some invalid node sizes
            let rTree = RTree(nodes, nodeSize: Int.random(in: -4 ... 16))

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
    }

    func testPerformance() throws {
        try 50.times {
            var nodes: [Point] = []
            try Int.random(in: 1000 ... 10000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }
            let rTree = RTree(nodes, nodeSize: Int.random(in: 16 ... 64))

            var minX = Double.random(in: 0.0 ... 10.0)
            var maxX = Double.random(in: 0.0 ... 10.0)
            var minY = Double.random(in: 0.0 ... 10.0)
            var maxY = Double.random(in: 0.0 ... 10.0)

            if minX > maxX {
                (minX, maxX) = (maxX, minX)
            }
            if minY > maxY {
                (minY, maxY) = (maxY, minY)
            }

            let boundingBox = BoundingBox(
                southWest: Coordinate3D(latitude: minY, longitude: minX),
                northEast: Coordinate3D(latitude: maxY, longitude: maxX))

            let startTime1 = CFAbsoluteTimeGetCurrent()
            let objects1 = rTree.search(inBoundingBox: boundingBox)
            let timeElapsed1 = CFAbsoluteTimeGetCurrent() - startTime1

            let startTime2 = CFAbsoluteTimeGetCurrent()
            let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)
            let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2

            XCTAssertEqual(
                objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude },
                objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
            XCTAssert(timeElapsed1 < timeElapsed2, "\(rTree.count) objects, nodesize: \(rTree.nodeSize)")
        }
    }

    func _testNodeSizes() throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: 5.0))

        for nodeSize in 4 ... 512 {
            for objectCount in stride(from: nodeSize * 2, to: 10000, by: 10) {
                var nodes: [Point] = []
                try objectCount.times {
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

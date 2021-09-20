#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class RTreeTests: XCTestCase {

    func testSingleObject() throws {
        try 100.times {
            var nodes: [Point] = []
            try Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: 0.0 ... 10.0),
                    longitude: Double.random(in: 0.0 ... 10.0))))
            }
            let rTree = RTree(nodes, nodeSize: Int.random(in: 4 ... 16))

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

            let objects1 = rTree.search(inBoundingBox: boundingBox)
                .sorted { point1, point2 in
                    return point1.coordinate.longitude < point2.coordinate.longitude
                }
            let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)
                .sorted { point1, point2 in
                    return point1.coordinate.longitude < point2.coordinate.longitude
                }

            XCTAssertEqual(objects1, objects2)
        }
    }

}

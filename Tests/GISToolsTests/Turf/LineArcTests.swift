#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class LineArcTests: XCTestCase {

    func testLineArc() {
        let point = Point(Coordinate3D(latitude: 44.495, longitude: 11.343))
        let lineArc = point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0)
        let expected = TestData.lineString(package: "LineArc", name: "LineArcResult")

        let lineArcCoordinates = lineArc!.coordinates
        let expectedCoordinates = expected.coordinates

        XCTAssertEqual(lineArcCoordinates.count, expectedCoordinates.count)

        for index in 0 ..< lineArcCoordinates.count {
            XCTAssertEqual(lineArcCoordinates[index].latitude, expectedCoordinates[index].latitude, accuracy: 0.00001)
            XCTAssertEqual(lineArcCoordinates[index].longitude, expectedCoordinates[index].longitude, accuracy: 0.00001)
        }
    }

    static var allTests = [
        ("testLineArc", testLineArc),
    ]

}

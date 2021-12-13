@testable import GISTools
import XCTest

final class PointToLineDistanceTests: XCTestCase {

    func testPointToLineDistance() {
        let coordinate = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let lineString = LineString([Coordinate3D(latitude: 1.0, longitude: 1.0), Coordinate3D(latitude: 1.0, longitude: -1.0)])!

        XCTAssertEqual(lineString.distanceFrom(coordinate: coordinate), 111_195.0802335329)
    }

    static var allTests = [
        ("testPointToLineDistance", testPointToLineDistance),
    ]

}

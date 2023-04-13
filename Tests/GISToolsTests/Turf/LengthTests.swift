#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

final class LengthTests: XCTestCase {

    func testLength() {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedLength: CLLocationDistance = 97129.22118967835

        let lineSegment = LineSegment(first: coordinate1, second: coordinate2)

        XCTAssertEqual(lineSegment.length, expectedLength, accuracy: 0.000001)
    }

}

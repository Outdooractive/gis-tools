@testable import GISTools
import XCTest

final class BooleanClockwiseTests: XCTestCase {

    func testBooleanClockwise() {
        let ring = Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])!

        XCTAssertEqual(ring.isClockwise, true)
        XCTAssertEqual(ring.isCounterClockwise, false)
    }

    func testBooleanCounterClockwise() {
        let ring = Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])!

        XCTAssertEqual(ring.isClockwise, false)
        XCTAssertEqual(ring.isCounterClockwise, true)
    }

}

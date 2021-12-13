@testable import GISTools
import XCTest

final class DestinationTests: XCTestCase {

    func testDestination1() {
        let bearing = 0.0
        let distance = 100_000.0

        let coordinate = Coordinate3D(latitude: 38.10096062273525, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)

        XCTAssertEqual(destination.latitude, 39.000281, accuracy: 0.000001)
        XCTAssertEqual(destination.longitude, -75.0, accuracy: 0.000001)
    }

    func testDestination2() {
        let bearing = 180.0
        let distance = 100_000.0

        let coordinate = Coordinate3D(latitude: 39.0, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)

        XCTAssertEqual(destination.latitude, 38.10068, accuracy: 0.000001)
        XCTAssertEqual(destination.longitude, -75.0, accuracy: 0.000001)
    }

    func testDestination3() {
        let bearing = 90.0
        let distance = 100_000.0

        let coordinate = Coordinate3D(latitude: 39.0, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)

        XCTAssertEqual(destination.latitude, 38.994285, accuracy: 0.000001)
        XCTAssertEqual(destination.longitude, -73.842853, accuracy: 0.000001)
    }

    // TODO: This returns a completly different result than the original Turf implementation
    func testDestination4() {
        let bearing = 90.0
        let distance: Double = GISTool.convert(length: 5000.0, from: .miles, to: .meters)!
        XCTAssertEqual(distance, 8_046_720.0, accuracy: 0.1)

        let coordinate = Coordinate3D(latitude: 39.0, longitude: -75.0)
        let destination = coordinate.destination(distance: distance, bearing: bearing)
        XCTAssertEqual(destination.latitude, 10.990466075751455, accuracy: 0.000001)
        XCTAssertEqual(destination.longitude, 1.123702522680564, accuracy: 0.000001)
    }

    static var allTests = [
        ("testDestination1", testDestination1),
        ("testDestination2", testDestination2),
        ("testDestination3", testDestination3),
        ("testDestination4", testDestination4),
    ]

}

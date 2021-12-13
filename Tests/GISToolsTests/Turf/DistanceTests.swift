#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

// MARK: - DistanceTests

final class DistanceTests: XCTestCase {

    func testDistance() {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedDistance: CLLocationDistance = 97129.22118967835

        XCTAssertEqual(coordinate1.distance(from: coordinate2), expectedDistance, accuracy: 0.000001)
    }

    static var allTests = [
        ("testDistance", testDistance),
    ]

}

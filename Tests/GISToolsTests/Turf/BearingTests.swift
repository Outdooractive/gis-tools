#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

// MARK: - BearingTests

final class BearingTests: XCTestCase {

    func testBearing() {
        let start = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let end = Coordinate3D(latitude: 60.0, longitude: 20.0)

        let initialBearing: CLLocationDegrees = start.bearing(to: end)
        let finalBearing: CLLocationDegrees = start.bearing(to: end, final: true)

        XCTAssertEqual(initialBearing, 37.75, accuracy: 0.01)
        XCTAssertEqual(finalBearing, 120.01, accuracy: 0.01)
    }

    func testBearingToAzimuth() {
        XCTAssertEqual(40.0.bearingToAzimuth, 40.0)
        XCTAssertEqual((-105.0).bearingToAzimuth, 255.0)
        XCTAssertEqual(410.0.bearingToAzimuth, 50.0)
        XCTAssertEqual((-200.0).bearingToAzimuth, 160.0)
        XCTAssertEqual((-395.0).bearingToAzimuth, 325.0)
    }

}

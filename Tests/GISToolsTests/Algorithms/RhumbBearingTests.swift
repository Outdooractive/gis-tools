#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

final class RhumbBearingTests: XCTestCase {

    func testRhumbBearing() {
        let start = Coordinate3D(latitude: 45.0, longitude: -75.0)
        let end = Coordinate3D(latitude: 60.0, longitude: 20.0)

        let initialBearing: CLLocationDegrees = start.rhumbBearing(to: end)
        let finalBearing: CLLocationDegrees = start.rhumbBearing(to: end, final: true)

        XCTAssertEqual(initialBearing, 75.28, accuracy: 0.01)
        XCTAssertEqual(finalBearing, -104.719, accuracy: 0.01)
    }

}

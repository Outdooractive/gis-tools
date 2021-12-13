#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

// MARK: - RhumbDistanceTests

final class RhumbDistanceTests: XCTestCase {

    func testDistance() {
        let coordinate1 = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let coordinate2 = Coordinate3D(latitude: 39.123, longitude: -75.534)
        let expectedDistance1: CLLocationDistance = 97129.239

        let coordinate3 = Coordinate3D(latitude: 35.60371874069731, longitude: -119.17968749999999)
        let coordinate4 = Coordinate3D(latitude: 46.92025531537451, longitude: -67.5)
        let expectedDistance2: CLLocationDistance = 4_482_044.244

        let coordinate5 = Coordinate3D(latitude: -16.5, longitude: -179.5)
        let coordinate6 = Coordinate3D(latitude: -16.5, longitude: 178.5)
        let expectedDistance3: CLLocationDistance = 213_232.075

        let coordinate7 = Coordinate3D(latitude: -16.5, longitude: -539.5)
        let coordinate8 = Coordinate3D(latitude: -18.5, longitude: -541.5)
        let expectedDistance4: CLLocationDistance = 307_306.293

        XCTAssertEqual(coordinate1.rhumbDistance(from: coordinate2), expectedDistance1, accuracy: 0.001)
        XCTAssertEqual(coordinate3.rhumbDistance(from: coordinate4), expectedDistance2, accuracy: 0.001)
        XCTAssertEqual(coordinate5.rhumbDistance(from: coordinate6), expectedDistance3, accuracy: 0.001)
        XCTAssertEqual(coordinate7.rhumbDistance(from: coordinate8), expectedDistance4, accuracy: 0.001)
    }

    static var allTests = [
        ("testDistance", testDistance),
    ]

}

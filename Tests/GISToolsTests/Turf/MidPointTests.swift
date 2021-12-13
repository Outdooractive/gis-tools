@testable import GISTools
import XCTest

final class MidPointTests: XCTestCase {

    func testHorizontalEquator() {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: 10.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        XCTAssertEqual(coordinate1.distance(from: middle), coordinate2.distance(from: middle), accuracy: 0.000001)
    }

    func testVerticalFromEquator() {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        XCTAssertEqual(coordinate1.distance(from: middle), coordinate2.distance(from: middle), accuracy: 0.000001)
    }

    func testVerticalToEquator() {
        let coordinate1 = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        XCTAssertEqual(coordinate1.distance(from: middle), coordinate2.distance(from: middle), accuracy: 0.000001)
    }

    func testLongDistance() {
        let coordinate1 = Coordinate3D(latitude: 21.94304553343818, longitude: 22.5)
        let coordinate2 = Coordinate3D(latitude: 46.800059446787316, longitude: 92.10937499999999)
        let middle = coordinate1.midpoint(to: coordinate2)

        XCTAssertEqual(coordinate1.distance(from: middle), coordinate2.distance(from: middle), accuracy: 0.000001)
    }

    static var allTests = [
        ("testHorizontalEquator", testHorizontalEquator),
        ("testVerticalFromEquator", testVerticalFromEquator),
        ("testVerticalToEquator", testVerticalToEquator),
        ("testLongDistance", testLongDistance),
    ]

}

@testable import GISTools
import XCTest

final class CircleTests: XCTestCase {

    func testCircle() {
        let point = Point(Coordinate3D(latitude: 39.984, longitude: -75.343))
        let circle = point.circle(radius: 5000.0)
        let expected = TestData.polygon(package: "Circle", name: "CircleResult")

        let circleCoordinates = circle!.outerRing!.coordinates
        let expectedCoordinates = expected.outerRing!.coordinates

        XCTAssertEqual(circleCoordinates.count, expectedCoordinates.count)

        for index in 0 ..< circleCoordinates.count {
            XCTAssertEqual(circleCoordinates[index].latitude, expectedCoordinates[index].latitude, accuracy: 0.00001)
            XCTAssertEqual(circleCoordinates[index].longitude, expectedCoordinates[index].longitude, accuracy: 0.00001)
        }
    }

}

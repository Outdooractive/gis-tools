@testable import GISTools
import XCTest

final class TransformRotateTests: XCTestCase {

    func testTransformRotate() throws {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 0.0))
        let pointTransformed = point.transformedRotate(angle: 90.0, pivot: Coordinate3D.zero)
        let pointResult = Point(Coordinate3D(latitude: 0.0, longitude: 45.0))

        XCTAssertEqual(pointTransformed, pointResult)
    }

}

@testable import GISTools
import XCTest

final class TransformTranslateTests: XCTestCase {

    func testTransformTranslate() throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0))
        let result1 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let result2 = Point(Coordinate3D(latitude: 10.0, longitude: -10.0))

        let distance = point.coordinate.rhumbDistance(from: result1.coordinate)
        let translated1 = point.transformedTranslate(distance: distance, direction: 90.0)
        let translated2 = point.transformedTranslate(distance: distance, direction: 270.0)

        XCTAssertEqual(translated1, result1)
        XCTAssertEqual(translated2, result2)
    }

    func testTransformTranslateAltitude() throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 500.0))
        let result = Point(Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 750.0))

        let distance = point.coordinate.rhumbDistance(from: result.coordinate)
        let translated = point.transformedTranslate(distance: distance, direction: 90.0, zTranslation: 250.0)

        XCTAssertEqual(translated, result)
    }

}

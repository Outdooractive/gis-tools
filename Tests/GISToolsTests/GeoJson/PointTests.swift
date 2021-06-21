#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class PointTests: XCTestCase {

    private let pointJson = """
        {
            "type": "Point",
            "coordinates": [100.0, 0.0]
        }
        """

    func testLoadJson() {
        let point = Point(jsonString: pointJson)
        XCTAssertNotNil(point)
        XCTAssertEqual(point?.type, GeoJsonType.point)
        XCTAssertEqual(point?.coordinate, Coordinate3D(latitude: 0.0, longitude: 100.0))
    }

    func testCreateJson() {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

        let string = point.asJsonString()!
        XCTAssert(string.contains("\"type\":\"Point\""))
        XCTAssert(string.contains("\"coordinates\":[100,0]"))
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}

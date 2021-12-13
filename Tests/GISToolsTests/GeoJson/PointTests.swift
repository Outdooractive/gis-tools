@testable import GISTools
import XCTest

final class PointTests: XCTestCase {

    private let pointJson = """
    {
        "type": "Point",
        "coordinates": [100.0, 0.0],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let point = Point(jsonString: pointJson) else {
            throw "point is nil"
        }
        XCTAssertEqual(point.type, GeoJsonType.point)
        XCTAssertEqual(point.coordinate, Coordinate3D(latitude: 0.0, longitude: 100.0))
        XCTAssertEqual(point.foreignMember(for: "other"), "something else")
        XCTAssertEqual(point[foreignMember: "other"], "something else")
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

@testable import GISTools
import XCTest

final class LineStringTests: XCTestCase {

    private let lineStringJson = """
    {
        "type": "LineString",
        "coordinates": [
            [100.0, 0.0],
            [101.0, 1.0]
        ],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let lineString = LineString(jsonString: lineStringJson) else {
            throw "lineString is nil"
        }
        XCTAssertNotNil(lineString)
        XCTAssertEqual(lineString.type, GeoJsonType.lineString)
        XCTAssertEqual(lineString.coordinates, [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])
        XCTAssertEqual(lineString.foreignMember(for: "other"), "something else")
        XCTAssertEqual(lineString[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        let lineString = LineString([Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])!

        let string = lineString.asJsonString()!
        XCTAssert(string.contains("\"type\":\"LineString\""))
        XCTAssert(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}

@testable import GISTools
import XCTest

final class PointTests: XCTestCase {

    static let pointJson = """
    {
        "type": "Point",
        "coordinates": [100.0, 0.0],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        let point = try XCTUnwrap(Point(jsonString: PointTests.pointJson))

        XCTAssertEqual(point.type, GeoJsonType.point)
        XCTAssertEqual(point.projection, .epsg4326)
        XCTAssertEqual(point.coordinate, Coordinate3D(latitude: 0.0, longitude: 100.0))
        XCTAssertEqual(point.foreignMember(for: "other"), "something else")
        XCTAssertEqual(point[foreignMember: "other"], "something else")
    }

    func testCreateJson() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let string = try XCTUnwrap(point.asJsonString())

        XCTAssertEqual(point.projection, .epsg4326)
        XCTAssert(string.contains("\"type\":\"Point\""))
        XCTAssert(string.contains("\"coordinates\":[100,0]"))
    }

    func testEncodable() throws {
        let point = try XCTUnwrap(Point(jsonString: PointTests.pointJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(point), point.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        let pointData = try XCTUnwrap(Point(jsonString: PointTests.pointJson)?.asJsonData(prettyPrinted: true))
        let point = try JSONDecoder().decode(Point.self, from: pointData)

        XCTAssertEqual(point.projection, .epsg4326)
        XCTAssertEqual(pointData, point.asJsonData(prettyPrinted: true))
    }

}

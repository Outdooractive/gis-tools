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
        let lineString = try XCTUnwrap(LineString(jsonString: lineStringJson))

        XCTAssertEqual(lineString.type, GeoJsonType.lineString)
        XCTAssertEqual(lineString.coordinates, [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])
        XCTAssertEqual(lineString.foreignMember(for: "other"), "something else")
        XCTAssertEqual(lineString[foreignMember: "other"], "something else")
    }

    func testCreateJson() throws {
        let lineString = LineString([Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])!

        let string = try XCTUnwrap(lineString.asJsonString())
        XCTAssert(string.contains("\"type\":\"LineString\""))
        XCTAssert(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    func testCreateLineString() throws {
        let lineSegments = [
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 0.0), second: Coordinate3D(latitude: 10.0, longitude: 0.0)),
            LineSegment(first: Coordinate3D(latitude: 10.0, longitude: 0.0), second: Coordinate3D(latitude: 10.0, longitude: 10.0)),
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 10.0), second: Coordinate3D(latitude: 0.0, longitude: 0.0)),
        ]
        let lineString = try XCTUnwrap(LineString(lineSegments))

        let expected = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        XCTAssertEqual(lineString.coordinates, expected)
    }

    func testEncodable() throws {
        let lineString = try XCTUnwrap(LineString(jsonString: lineStringJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(lineString), lineString.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        guard let lineStringData = LineString(jsonString: lineStringJson)?.asJsonData(prettyPrinted: true) else {
            throw "lineString is nil"
        }

        let lineString = try JSONDecoder().decode(LineString.self, from: lineStringData)
        XCTAssertEqual(lineStringData, lineString.asJsonData(prettyPrinted: true))
    }

}

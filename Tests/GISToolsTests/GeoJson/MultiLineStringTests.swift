@testable import GISTools
import XCTest

final class MultiLineStringTests: XCTestCase {

    private let multiLineStringJson = """
    {
        "type": "MultiLineString",
        "coordinates": [
            [
                [100.0, 0.0],
                [101.0, 1.0]
            ],
            [
                [102.0, 2.0],
                [103.0, 3.0]
            ]
        ],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let multiLineString = MultiLineString(jsonString: multiLineStringJson) else {
            throw "multiLineString is nil"
        }
        XCTAssertNotNil(multiLineString)
        XCTAssertEqual(multiLineString.type, GeoJsonType.multiLineString)
        XCTAssertEqual(multiLineString.coordinates, [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)], [Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 3.0, longitude: 103.0)]])
        XCTAssertEqual(multiLineString.foreignMember(for: "other"), "something else")
        XCTAssertEqual(multiLineString[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        let multiLineString = MultiLineString([[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)], [Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 3.0, longitude: 103.0)]])!

        let string = multiLineString.asJsonString()!
        XCTAssert(string.contains("\"type\":\"MultiLineString\""))
        XCTAssert(string.contains("\"coordinates\":[[[100,0],[101,1]],[[102,2],[103,3]]]"))
    }

    func testEncodable() throws {
        guard let multiLineString = MultiLineString(jsonString: multiLineStringJson) else {
            throw "multiLineString is nil"
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(multiLineString), multiLineString.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        guard let multiLineStringData = MultiLineString(jsonString: multiLineStringJson)?.asJsonData(prettyPrinted: true) else {
            throw "multiLineString is nil"
        }

        let multiLineString = try JSONDecoder().decode(MultiLineString.self, from: multiLineStringData)
        XCTAssertEqual(multiLineStringData, multiLineString.asJsonData(prettyPrinted: true))
    }

}

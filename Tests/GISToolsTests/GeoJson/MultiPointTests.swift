@testable import GISTools
import XCTest

final class MultiPointTests: XCTestCase {

    private let multiPointJson = """
    {
        "type": "MultiPoint",
        "coordinates": [
            [100.0, 0.0],
            [101.0, 1.0]
        ],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let multiPoint = MultiPoint(jsonString: multiPointJson) else {
            throw "multiPoint is nil"
        }
        XCTAssertNotNil(multiPoint)
        XCTAssertEqual(multiPoint.type, GeoJsonType.multiPoint)
        XCTAssertEqual(multiPoint.coordinates, [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])
        XCTAssertEqual(multiPoint.foreignMember(for: "other"), "something else")
        XCTAssertEqual(multiPoint[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        let multiPoint = MultiPoint([Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])!

        let string = multiPoint.asJsonString()!
        XCTAssert(string.contains("\"type\":\"MultiPoint\""))
        XCTAssert(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    func testEncodable() throws {
        guard let multiPoint = MultiPoint(jsonString: multiPointJson) else {
            throw "multiPoint is nil"
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(multiPoint), multiPoint.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        guard let multiPointData = MultiPoint(jsonString: multiPointJson)?.asJsonData(prettyPrinted: true) else {
            throw "multiPoint is nil"
        }

        let multiPoint = try JSONDecoder().decode(MultiPoint.self, from: multiPointData)
        XCTAssertEqual(multiPointData, multiPoint.asJsonData(prettyPrinted: true))
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
        ("testEncodable", testEncodable),
        ("testDecodable", testDecodable),
    ]

}

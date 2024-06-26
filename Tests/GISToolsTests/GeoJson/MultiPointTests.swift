@testable import GISTools
import XCTest

final class MultiPointTests: XCTestCase {

    static let multiPointJson = """
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
        let multiPoint = try XCTUnwrap(MultiPoint(jsonString: MultiPointTests.multiPointJson))

        XCTAssertNotNil(multiPoint)
        XCTAssertEqual(multiPoint.type, GeoJsonType.multiPoint)
        XCTAssertEqual(multiPoint.projection, .epsg4326)
        XCTAssertEqual(multiPoint.coordinates, [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])
        XCTAssertEqual(multiPoint.foreignMember(for: "other"), "something else")
        XCTAssertEqual(multiPoint[foreignMember: "other"], "something else")
    }

    func testCreateJson() throws {
        let multiPoint = try XCTUnwrap(MultiPoint([Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)]))
        let string = try XCTUnwrap(multiPoint.asJsonString())

        XCTAssertEqual(multiPoint.projection, .epsg4326)
        XCTAssert(string.contains("\"type\":\"MultiPoint\""))
        XCTAssert(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    func testEncodable() throws {
        let multiPoint = try XCTUnwrap(MultiPoint(jsonString: MultiPointTests.multiPointJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(multiPoint), multiPoint.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        let multiPointData = try XCTUnwrap(MultiPoint(jsonString: MultiPointTests.multiPointJson)?.asJsonData(prettyPrinted: true))
        let multiPoint = try JSONDecoder().decode(MultiPoint.self, from: multiPointData)

        XCTAssertEqual(multiPoint.projection, .epsg4326)
        XCTAssertEqual(multiPointData, multiPoint.asJsonData(prettyPrinted: true))
    }

}

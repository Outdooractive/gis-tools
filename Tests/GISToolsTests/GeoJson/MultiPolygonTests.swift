@testable import GISTools
import XCTest

final class MultiPolygonTests: XCTestCase {

    private let multiPolygonJson = """
    {
        "type": "MultiPolygon",
        "coordinates": [
            [
                [
                    [102.0, 2.0],
                    [103.0, 2.0],
                    [103.0, 3.0],
                    [102.0, 3.0],
                    [102.0, 2.0]
                ]
            ],
            [
                [
                    [100.0, 0.0],
                    [101.0, 0.0],
                    [101.0, 1.0],
                    [100.0, 1.0],
                    [100.0, 0.0]
                ],
                [
                    [100.2, 2.0],
                    [100.2, 1.0],
                    [100.8, 1.0],
                    [100.8, 2.0],
                    [100.2, 2.0]
                ]
            ]
        ],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        let multiPolygon = try XCTUnwrap(MultiPolygon(jsonString: multiPolygonJson))

        XCTAssertEqual(multiPolygon.type, GeoJsonType.multiPolygon)
        XCTAssertEqual(multiPolygon.projection, .epsg4326)
        XCTAssertEqual(multiPolygon.coordinates, [[[Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 102.0)]], [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)], [Coordinate3D(latitude: 2.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.8), Coordinate3D(latitude: 2.0, longitude: 100.8), Coordinate3D(latitude: 2.0, longitude: 100.2)]]])
        XCTAssertEqual(multiPolygon.foreignMember(for: "other"), "something else")
        XCTAssertEqual(multiPolygon[foreignMember: "other"], "something else")
    }

    func testCreateJson() throws {
        let multiPolygon = try XCTUnwrap(MultiPolygon([[[Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 102.0)]], [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)], [Coordinate3D(latitude: 0.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.8), Coordinate3D(latitude: 0.0, longitude: 100.8), Coordinate3D(latitude: 0.0, longitude: 100.2)]]]))
        let string = multiPolygon.asJsonString()!

        XCTAssertEqual(multiPolygon.projection, .epsg4326)
        XCTAssert(string.contains("\"type\":\"MultiPolygon\""))
        XCTAssert(string.contains("\"coordinates\":[[[[102,2],[103,2],[103,3],[102,3],[102,2]]],[[[100,0],[101,0],[101,1],[100,1],[100,0]],[[100.2,0],[100.2,1],[100.8,1],[100.8,0],[100.2,0]]]]"))
    }

    func testEncodable() throws {
        let multiPolygon = try XCTUnwrap(MultiPolygon(jsonString: multiPolygonJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(multiPolygon), multiPolygon.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        let multiPolygonData = try XCTUnwrap(MultiPolygon(jsonString: multiPolygonJson)?.asJsonData(prettyPrinted: true))
        let multiPolygon = try JSONDecoder().decode(MultiPolygon.self, from: multiPolygonData)

        XCTAssertEqual(multiPolygon.projection, .epsg4326)
        XCTAssertEqual(multiPolygonData, multiPolygon.asJsonData(prettyPrinted: true))
    }

}

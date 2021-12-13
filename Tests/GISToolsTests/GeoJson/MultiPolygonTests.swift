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
                    [100.2, 0.2],
                    [100.2, 0.8],
                    [100.8, 0.8],
                    [100.8, 0.2],
                    [100.2, 0.2]
                ]
            ]
        ],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let multiPolygon = MultiPolygon(jsonString: multiPolygonJson) else {
            throw "multiPolygon is nil"
        }
        XCTAssertEqual(multiPolygon.type, GeoJsonType.multiPolygon)
        XCTAssertEqual(multiPolygon.coordinates, [[[Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 102.0)]], [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)], [Coordinate3D(latitude: 0.2, longitude: 100.2), Coordinate3D(latitude: 0.8, longitude: 100.2), Coordinate3D(latitude: 0.8, longitude: 100.8), Coordinate3D(latitude: 0.2, longitude: 100.8), Coordinate3D(latitude: 0.2, longitude: 100.2)]]])
        XCTAssertEqual(multiPolygon.foreignMember(for: "other"), "something else")
        XCTAssertEqual(multiPolygon[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        let multiPolygon = MultiPolygon([[[Coordinate3D(latitude: 2.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 103.0), Coordinate3D(latitude: 3.0, longitude: 102.0), Coordinate3D(latitude: 2.0, longitude: 102.0)]], [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)], [Coordinate3D(latitude: 0.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.8), Coordinate3D(latitude: 0.0, longitude: 100.8), Coordinate3D(latitude: 0.0, longitude: 100.2)]]])!

        let string = multiPolygon.asJsonString()!
        XCTAssert(string.contains("\"type\":\"MultiPolygon\""))
        XCTAssert(string.contains("\"coordinates\":[[[[102,2],[103,2],[103,3],[102,3],[102,2]]],[[[100,0],[101,0],[101,1],[100,1],[100,0]],[[100.2,0],[100.2,1],[100.8,1],[100.8,0],[100.2,0]]]]"))
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}

@testable import GISTools
import XCTest

final class PolygonTests: XCTestCase {

    private let polygonJsonNoHole = """
    {
        "type": "Polygon",
        "coordinates": [
            [
                [100.0, 0.0],
                [101.0, 0.0],
                [101.0, 1.0],
                [100.0, 1.0],
                [100.0, 0.0]
            ]
        ],
        "other": "something else"
    }
    """

    let polygonJsonWithHoles = """
    {
        "type": "Polygon",
        "coordinates": [
            [
                [100.0, 0.0],
                [101.0, 0.0],
                [101.0, 1.0],
                [100.0, 1.0],
                [100.0, 0.0]
            ],
            [
                [100.8, 0.8],
                [100.8, 0.2],
                [100.2, 0.2],
                [100.2, 0.8],
                [100.8, 0.8]
            ]
        ],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let polygonNoHole = Polygon(jsonString: polygonJsonNoHole) else {
            throw "polygonNoHole is nil"
        }
        XCTAssertEqual(polygonNoHole.type, GeoJsonType.polygon)
        XCTAssertEqual(polygonNoHole.coordinates, [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)]])
        XCTAssertEqual(polygonNoHole.foreignMember(for: "other"), "something else")
        XCTAssertEqual(polygonNoHole[foreignMember: "other"], "something else")

        guard let polygonWithHoles = Polygon(jsonString: polygonJsonWithHoles) else {
            throw "polygonWithHoles is nil"
        }
        XCTAssertEqual(polygonWithHoles.type, GeoJsonType.polygon)
        XCTAssertEqual(polygonWithHoles.coordinates, [[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)], [Coordinate3D(latitude: 0.8, longitude: 100.8), Coordinate3D(latitude: 0.2, longitude: 100.8), Coordinate3D(latitude: 0.2, longitude: 100.2), Coordinate3D(latitude: 0.8, longitude: 100.2), Coordinate3D(latitude: 0.8, longitude: 100.8)]])
        XCTAssertEqual(polygonWithHoles.foreignMember(for: "other"), "something else")
        XCTAssertEqual(polygonWithHoles[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        let polygonNoHole = Polygon([[Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)]])!
        let polygonWithHoles = Polygon([
            [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 100.0), Coordinate3D(latitude: 0.0, longitude: 100.0)],
            [Coordinate3D(latitude: 1.0, longitude: 100.8), Coordinate3D(latitude: 0.0, longitude: 100.8), Coordinate3D(latitude: 0.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.2), Coordinate3D(latitude: 1.0, longitude: 100.8)],
        ])!

        let stringNoHole = polygonNoHole.asJsonString()!
        XCTAssert(stringNoHole.contains("\"type\":\"Polygon\""))
        XCTAssert(stringNoHole.contains("\"coordinates\":[[[100,0],[101,0],[101,1],[100,1],[100,0]]]"))

        let stringWithHoles = polygonWithHoles.asJsonString()!
        XCTAssert(stringWithHoles.contains("\"type\":\"Polygon\""))
        XCTAssert(stringWithHoles.contains("\"coordinates\":[[[100,0],[101,0],[101,1],[100,1],[100,0]],[[100.8,1],[100.8,0],[100.2,0],[100.2,1],[100.8,1]]]"))
    }

    func testEncodable() throws {
        guard let polygonNoHole = Polygon(jsonString: polygonJsonNoHole) else {
            throw "polygonNoHole is nil"
        }
        guard let polygonWithHoles = Polygon(jsonString: polygonJsonWithHoles) else {
            throw "polygonWithHoles is nil"
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(polygonNoHole), polygonNoHole.asJsonData(prettyPrinted: true))
        XCTAssertEqual(try encoder.encode(polygonWithHoles), polygonWithHoles.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        guard let polygonNoHoleData = Polygon(jsonString: polygonJsonNoHole)?.asJsonData(prettyPrinted: true) else {
            throw "polygonNoHole is nil"
        }
        guard let polygonWithHolesData = Polygon(jsonString: polygonJsonWithHoles)?.asJsonData(prettyPrinted: true) else {
            throw "polygonWithHoles is nil"
        }

        let polygonNoHole = try JSONDecoder().decode(Polygon.self, from: polygonNoHoleData)
        let polygonWithHoles = try JSONDecoder().decode(Polygon.self, from: polygonWithHolesData)
        XCTAssertEqual(polygonNoHoleData, polygonNoHole.asJsonData(prettyPrinted: true))
        XCTAssertEqual(polygonWithHolesData, polygonWithHoles.asJsonData(prettyPrinted: true))
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
        ("testEncodable", testEncodable),
        ("testDecodable", testDecodable),
    ]

}

@testable import GISTools
import XCTest

final class GeometryCollectionTests: XCTestCase {

    static let geometryCollectionJson = """
    {
        "type": "GeometryCollection",
        "geometries": [{
            "type": "Point",
            "coordinates": [100.0, 0.0]
        }, {
            "type": "LineString",
            "coordinates": [
                [101.0, 0.0],
                [102.0, 1.0]
            ]
        }],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        let geometryCollection = try XCTUnwrap(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson))

        XCTAssertNotNil(geometryCollection)
        XCTAssertEqual(geometryCollection.type, GeoJsonType.geometryCollection)
        XCTAssertEqual(geometryCollection.projection, .epsg4326)
        XCTAssertEqual(geometryCollection.geometries.count, 2)
        XCTAssertEqual(geometryCollection.foreignMember(for: "other"), "something else")
        XCTAssertEqual(geometryCollection[foreignMember: "other"], "something else")
    }

    func testCreateJson() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let lineString = try XCTUnwrap(LineString([Coordinate3D(latitude: 0.0, longitude: 101.0), Coordinate3D(latitude: 1.0, longitude: 102.0)]))
        let geometryCollection = GeometryCollection([point, lineString])
        let string = try XCTUnwrap(geometryCollection.asJsonString())

        XCTAssertEqual(geometryCollection.projection, .epsg4326)
        XCTAssert(string.contains("\"type\":\"GeometryCollection\""))
        XCTAssert(string.contains("\"coordinates\":[100,0]"))
        XCTAssert(string.contains("\"coordinates\":[[101,0],[102,1]]"))
    }

    func testEncodable() throws {
        let geometryCollection = try XCTUnwrap(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(geometryCollection), geometryCollection.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        let geometryCollectionData = try XCTUnwrap(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson)?.asJsonData(prettyPrinted: true))
        let geometryCollection = try JSONDecoder().decode(GeometryCollection.self, from: geometryCollectionData)

        XCTAssertEqual(geometryCollection.projection, .epsg4326)
        XCTAssertEqual(geometryCollectionData, geometryCollection.asJsonData(prettyPrinted: true))
    }

}

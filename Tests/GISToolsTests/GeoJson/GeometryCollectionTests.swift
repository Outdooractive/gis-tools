import Foundation
@testable import GISTools
import Testing

struct GeometryCollectionTests {

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

    @Test
    func loadJson() async throws {
        let geometryCollection = try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson))

        #expect(geometryCollection.type == GeoJsonType.geometryCollection)
        #expect(geometryCollection.projection == .epsg4326)
        #expect(geometryCollection.geometries.count == 2)
        #expect(geometryCollection.foreignMember(for: "other") == "something else")
        #expect(geometryCollection[foreignMember: "other"] == "something else")
    }

    @Test
    func createJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 102.0)
        ]))
        let geometryCollection = GeometryCollection([point, lineString])
        let string = try #require(geometryCollection.asJsonString())

        #expect(geometryCollection.projection == .epsg4326)
        #expect(string.contains("\"type\":\"GeometryCollection\""))
        #expect(string.contains("\"coordinates\":[100,0]"))
        #expect(string.contains("\"coordinates\":[[101,0],[102,1]]"))
    }

    @Test
    func encodable() async throws {
        let geometryCollection = try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(geometryCollection) == geometryCollection.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let geometryCollectionData = try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson)?.asJsonData(prettyPrinted: true))
        let geometryCollection = try JSONDecoder().decode(GeometryCollection.self, from: geometryCollectionData)

        #expect(geometryCollection.projection == .epsg4326)
        #expect(geometryCollectionData == geometryCollection.asJsonData(prettyPrinted: true))
    }

}

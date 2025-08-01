import Foundation
@testable import GISTools
import Testing

struct MultiLineStringTests {

    static let multiLineStringJson = """
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

    @Test
    func loadJson() async throws {
        let multiLineString = try #require(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson))

        #expect(multiLineString.type == GeoJsonType.multiLineString)
        #expect(multiLineString.projection == .epsg4326)
        #expect(multiLineString.coordinates == [[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ], [
            Coordinate3D(latitude: 2.0, longitude: 102.0),
            Coordinate3D(latitude: 3.0, longitude: 103.0)
        ]])
        #expect(multiLineString.foreignMember(for: "other") == "something else")
        #expect(multiLineString[foreignMember: "other"] == "something else")
    }

    @Test
    func createJson() async throws {
        let multiLineString = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 100.0),
                Coordinate3D(latitude: 1.0, longitude: 101.0)
            ],
            [
                Coordinate3D(latitude: 2.0, longitude: 102.0),
                Coordinate3D(latitude: 3.0, longitude: 103.0)
            ]
        ]))
        let string = try #require(multiLineString.asJsonString())

        #expect(multiLineString.projection == .epsg4326)
        #expect(string.contains("\"type\":\"MultiLineString\""))
        #expect(string.contains("\"coordinates\":[[[100,0],[101,1]],[[102,2],[103,3]]]"))
    }

    @Test
    func encodable() async throws {
        let multiLineString = try #require(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(multiLineString) == multiLineString.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let multiLineStringData = try #require(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson)?.asJsonData(prettyPrinted: true))
        let multiLineString = try JSONDecoder().decode(MultiLineString.self, from: multiLineStringData)

        #expect(multiLineString.projection == .epsg4326)
        #expect(multiLineStringData == multiLineString.asJsonData(prettyPrinted: true))
    }

}

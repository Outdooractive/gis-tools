import Foundation
@testable import GISTools
import Testing

struct MultiPolygonTests {

    static let multiPolygonJson = """
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

    @Test
    func loadJson() async throws {
        let multiPolygon = try #require(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson))

        #expect(multiPolygon.type == GeoJsonType.multiPolygon)
        #expect(multiPolygon.projection == .epsg4326)
        #expect(multiPolygon.coordinates == [[[
            Coordinate3D(latitude: 2.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 102.0)
        ]], [[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ], [
            Coordinate3D(latitude: 2.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.8),
            Coordinate3D(latitude: 2.0, longitude: 100.8),
            Coordinate3D(latitude: 2.0, longitude: 100.2)
        ]]])
        #expect(multiPolygon.foreignMember(for: "other") == "something else")
        #expect(multiPolygon[foreignMember: "other"] == "something else")
    }

    @Test
    func createJson() async throws {
        let multiPolygon = try #require(MultiPolygon([[[
            Coordinate3D(latitude: 2.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 102.0)
        ]], [[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ], [
            Coordinate3D(latitude: 0.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.8),
            Coordinate3D(latitude: 0.0, longitude: 100.8),
            Coordinate3D(latitude: 0.0, longitude: 100.2)
        ]]]))
        let string = multiPolygon.asJsonString()!

        #expect(multiPolygon.projection == .epsg4326)
        #expect(string.contains("\"type\":\"MultiPolygon\""))
        #expect(string.contains("\"coordinates\":[[[[102,2],[103,2],[103,3],[102,3],[102,2]]],[[[100,0],[101,0],[101,1],[100,1],[100,0]],[[100.2,0],[100.2,1],[100.8,1],[100.8,0],[100.2,0]]]]"))
    }

    @Test
    func encodable() async throws {
        let multiPolygon = try #require(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(multiPolygon) == multiPolygon.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let multiPolygonData = try #require(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson)?.asJsonData(prettyPrinted: true))
        let multiPolygon = try JSONDecoder().decode(MultiPolygon.self, from: multiPolygonData)

        #expect(multiPolygon.projection == .epsg4326)
        #expect(multiPolygonData == multiPolygon.asJsonData(prettyPrinted: true))
    }

}

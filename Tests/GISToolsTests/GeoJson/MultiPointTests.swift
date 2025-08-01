import Foundation
@testable import GISTools
import Testing

struct MultiPointTests {

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

    @Test
    func loadJson() async throws {
        let multiPoint = try #require(MultiPoint(jsonString: MultiPointTests.multiPointJson))

        #expect(multiPoint.type == GeoJsonType.multiPoint)
        #expect(multiPoint.projection == .epsg4326)
        #expect(multiPoint.coordinates == [
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ])
        #expect(multiPoint.foreignMember(for: "other") == "something else")
        #expect(multiPoint[foreignMember: "other"] == "something else")
    }

    @Test
    func createJson() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ]))
        let string = try #require(multiPoint.asJsonString())

        #expect(multiPoint.projection == .epsg4326)
        #expect(string.contains("\"type\":\"MultiPoint\""))
        #expect(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    @Test
    func encodable() async throws {
        let multiPoint = try #require(MultiPoint(jsonString: MultiPointTests.multiPointJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(multiPoint) == multiPoint.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let multiPointData = try #require(MultiPoint(jsonString: MultiPointTests.multiPointJson)?.asJsonData(prettyPrinted: true))
        let multiPoint = try JSONDecoder().decode(MultiPoint.self, from: multiPointData)

        #expect(multiPoint.projection == .epsg4326)
        #expect(multiPointData == multiPoint.asJsonData(prettyPrinted: true))
    }

}

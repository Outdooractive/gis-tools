import Foundation
@testable import GISTools
import Testing

struct PointTests {

    static let pointJson = """
    {
        "type": "Point",
        "coordinates": [100.0, 0.0],
        "other": "something else"
    }
    """

    @Test
    func loadJson() async throws {
        let point = try #require(Point(jsonString: PointTests.pointJson))

        #expect(point.type == GeoJsonType.point)
        #expect(point.projection == .epsg4326)
        #expect(point.coordinate == Coordinate3D(latitude: 0.0, longitude: 100.0))
        #expect(point.foreignMember(for: "other") == "something else")
        #expect(point[foreignMember: "other"] == "something else")
    }

    @Test
    func createJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let string = try #require(point.asJsonString())

        #expect(point.projection == .epsg4326)
        #expect(string.contains("\"type\":\"Point\""))
        #expect(string.contains("\"coordinates\":[100,0]"))
    }

    @Test
    func encodable() async throws {
        let point = try #require(Point(jsonString: PointTests.pointJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(point) == point.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let pointData = try #require(Point(jsonString: PointTests.pointJson)?.asJsonData(prettyPrinted: true))
        let point = try JSONDecoder().decode(Point.self, from: pointData)

        #expect(point.projection == .epsg4326)
        #expect(pointData == point.asJsonData(prettyPrinted: true))
    }

}

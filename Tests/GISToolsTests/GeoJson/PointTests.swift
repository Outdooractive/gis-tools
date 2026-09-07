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

    // Validates loading a Point from a JSON string.
    @Test
    func loadJson() async throws {
        let point = try #require(Point(jsonString: PointTests.pointJson))

        #expect(point.type == GeoJsonType.point)
        #expect(point.projection == .epsg4326)
        #expect(point.coordinate == Coordinate3D(latitude: 0.0, longitude: 100.0))
        #expect(point.foreignMember(for: "other") == "something else")
        #expect(point[foreignMember: "other"] == "something else")
    }

    // Validates creating a Point and generating its JSON representation.
    @Test
    func createJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let string = try #require(point.asJsonString())

        #expect(point.projection == .epsg4326)
        #expect(string.contains("\"type\":\"Point\""))
        #expect(string.contains("\"coordinates\":[100,0]"))
    }

    // Validates that Point conforms to Encodable and matches the pretty-printed JSON output.
    @Test
    func encodable() async throws {
        let point = try #require(Point(jsonString: PointTests.pointJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(point) == point.asJsonData(prettyPrinted: true))
    }

    // Validates that Point conforms to Decodable and round-trips through JSON encoding.
    @Test
    func decodable() async throws {
        let pointData = try #require(Point(jsonString: PointTests.pointJson)?.asJsonData(prettyPrinted: true))
        let point = try JSONDecoder().decode(Point.self, from: pointData)

        #expect(point.projection == .epsg4326)
        #expect(pointData == point.asJsonData(prettyPrinted: true))
    }

    // MARK: - Typed foreign members

    // Validates the JSONValue and coercing foreign member accessors.
    @Test
    func typedForeignMembers() async throws {
        let json = """
        {
            "type": "Point",
            "coordinates": [8.5, 47.3],
            "string": "text",
            "int": 3,
            "fractionalInt": 3.0,
            "fractional": 3.5,
            "bool": true
        }
        """
        let point = try #require(Point(jsonString: json))

        #expect(point.stringForeignMember(for: "string") == "text")
        #expect(point.intForeignMember(for: "int") == 3)
        #expect(point.intForeignMember(for: "fractionalInt") == 3)
        #expect(point.intForeignMember(for: "fractional") == nil)
        #expect(point.doubleForeignMember(for: "int") == 3.0)
        #expect(point.doubleForeignMember(for: "fractional") == 3.5)
        #expect(point.boolForeignMember(for: "bool") == true)
        #expect(point.boolForeignMember(for: "int") == nil)
        #expect(point.stringForeignMember(for: "missing") == nil)

        #expect(point.jsonForeignMember(for: "int") == .int(3))
        #expect(point.jsonForeignMember(for: "fractional") == .number(3.5))
        #expect(point.jsonForeignMember(for: "missing") == nil)

        struct Extra: Codable, Equatable {
            let int: Int
        }
        let extra = try point.foreignMembers(as: Extra.self)
        #expect(extra == Extra(int: 3))
    }

    // MARK: - Hashable

    // Validates that equal points have equal hashes and deduplicate in sets.
    @Test
    func hashable() async throws {
        let pointA = Point(Coordinate3D(latitude: 47.3, longitude: 8.5))
        let pointB = Point(Coordinate3D(latitude: 47.3, longitude: 8.5))
        let pointC = Point(Coordinate3D(latitude: 47.4, longitude: 8.5))

        #expect(pointA == pointB)
        #expect(pointA.hashValue == pointB.hashValue)
        #expect(pointA != pointC)

        let set: Set<Point> = [pointA, pointB, pointC]
        #expect(set.count == 2)
    }

}

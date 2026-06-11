import Foundation
@testable import GISTools
import Testing

struct LineStringTests {

    static let lineStringJson = """
    {
        "type": "LineString",
        "coordinates": [
            [100.0, 0.0],
            [101.0, 1.0]
        ],
        "other": "something else"
    }
    """

    // Validates loading a LineString from JSON and verifying its coordinates and foreign members.
    @Test
    func loadJson() async throws {
        let lineString = try #require(LineString(jsonString: LineStringTests.lineStringJson))

        #expect(lineString.type == GeoJsonType.lineString)
        #expect(lineString.projection == .epsg4326)
        #expect(lineString.coordinates == [
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ])
        #expect(lineString.foreignMember(for: "other") == "something else")
        #expect(lineString[foreignMember: "other"] == "something else")
    }

    // Validates creating a LineString from coordinates and verifying its JSON string output.
    @Test
    func createJson() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ]))
        let string = try #require(lineString.asJsonString())

        #expect(lineString.projection == .epsg4326)
        #expect(string.contains("\"type\":\"LineString\""))
        #expect(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    // Validates creating a LineString from an array of LineSegments.
    @Test
    func createLineString() async throws {
        let lineSegments = [
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 0.0),
                        second: Coordinate3D(latitude: 10.0, longitude: 0.0)),
            LineSegment(first: Coordinate3D(latitude: 10.0, longitude: 0.0),
                        second: Coordinate3D(latitude: 10.0, longitude: 10.0)),
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 10.0),
                        second: Coordinate3D(latitude: 0.0, longitude: 0.0)),
        ]
        let lineString = try #require(LineString(lineSegments))

        let expected = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        #expect(lineString.coordinates == expected)
    }

    // Validates that a LineString encodes to JSON data matching its jsonData output.
    @Test
    func encodable() async throws {
        let lineString = try #require(LineString(jsonString: LineStringTests.lineStringJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(lineString) == lineString.asJsonData(prettyPrinted: true))
    }

    // Validates that a LineString round-trips through JSON encoding and decoding.
    @Test
    func decodable() async throws {
        let lineStringData = try #require(LineString(jsonString: LineStringTests.lineStringJson)?.asJsonData(prettyPrinted: true))
        let lineString = try JSONDecoder().decode(LineString.self, from: lineStringData)

        #expect(lineString.projection == .epsg4326)
        #expect(lineStringData == lineString.asJsonData(prettyPrinted: true))
    }

}

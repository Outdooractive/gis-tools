import Foundation
@testable import GISTools
import Testing

struct PolygonTests {

    static let polygonJsonNoHole = """
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

    static let polygonJsonWithHoles = """
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
                [100.8, 1.0],
                [100.8, 2.0],
                [100.2, 2.0],
                [100.2, 1.0],
                [100.8, 1.0]
            ]
        ],
        "other": "something else"
    }
    """

    @Test
    func loadJson() async throws {
        let polygonNoHole = try #require(Polygon(jsonString: PolygonTests.polygonJsonNoHole))

        #expect(polygonNoHole.type == GeoJsonType.polygon)
        #expect(polygonNoHole.projection == .epsg4326)
        #expect(polygonNoHole.coordinates == [[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ]])
        #expect(polygonNoHole.foreignMember(for: "other") == "something else")
        #expect(polygonNoHole[foreignMember: "other"] == "something else")

        let polygonWithHoles = try #require(Polygon(jsonString: PolygonTests.polygonJsonWithHoles))

        #expect(polygonWithHoles.type == GeoJsonType.polygon)
        #expect(polygonWithHoles.projection == .epsg4326)
        #expect(polygonWithHoles.coordinates == [[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ], [
            Coordinate3D(latitude: 1.0, longitude: 100.8),
            Coordinate3D(latitude: 2.0, longitude: 100.8),
            Coordinate3D(latitude: 2.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.2),
            Coordinate3D(latitude: 1.0, longitude: 100.8)
        ]])
        #expect(polygonWithHoles.foreignMember(for: "other") == "something else")
        #expect(polygonWithHoles[foreignMember: "other"] == "something else")
    }

    @Test
    func createJson() async throws {
        let polygonNoHole = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ]]))
        let polygonWithHoles = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: 101.0),
                Coordinate3D(latitude: 1.0, longitude: 101.0),
                Coordinate3D(latitude: 1.0, longitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: 100.0)
            ], [
                Coordinate3D(latitude: 1.0, longitude: 100.8),
                Coordinate3D(latitude: 0.0, longitude: 100.8),
                Coordinate3D(latitude: 0.0, longitude: 100.2),
                Coordinate3D(latitude: 1.0, longitude: 100.2),
                Coordinate3D(latitude: 1.0, longitude: 100.8)
            ],
        ]))

        let stringNoHole = try #require(polygonNoHole.asJsonString())
        #expect(polygonNoHole.projection == .epsg4326)
        #expect(stringNoHole.contains("\"type\":\"Polygon\""))
        #expect(stringNoHole.contains("\"coordinates\":[[[100,0],[101,0],[101,1],[100,1],[100,0]]]"))

        let stringWithHoles = try #require(polygonWithHoles.asJsonString())
        #expect(polygonWithHoles.projection == .epsg4326)
        #expect(stringWithHoles.contains("\"type\":\"Polygon\""))
        #expect(stringWithHoles.contains("\"coordinates\":[[[100,0],[101,0],[101,1],[100,1],[100,0]],[[100.8,1],[100.8,0],[100.2,0],[100.2,1],[100.8,1]]]"))
    }

    @Test
    func encodable() async throws {
        let polygonNoHole = try #require(Polygon(jsonString: PolygonTests.polygonJsonNoHole))
        let polygonWithHoles = try #require(Polygon(jsonString: PolygonTests.polygonJsonWithHoles))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(polygonNoHole) == polygonNoHole.asJsonData(prettyPrinted: true))
        #expect(try encoder.encode(polygonWithHoles) == polygonWithHoles.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let polygonNoHoleData = try #require(Polygon(jsonString: PolygonTests.polygonJsonNoHole)?.asJsonData(prettyPrinted: true))
        let polygonNoHole = try JSONDecoder().decode(Polygon.self, from: polygonNoHoleData)

        let polygonWithHolesData = try #require(Polygon(jsonString: PolygonTests.polygonJsonWithHoles)?.asJsonData(prettyPrinted: true))
        let polygonWithHoles = try JSONDecoder().decode(Polygon.self, from: polygonWithHolesData)

        #expect(polygonNoHole.projection == .epsg4326)
        #expect(polygonNoHoleData == polygonNoHole.asJsonData(prettyPrinted: true))
        #expect(polygonWithHoles.projection == .epsg4326)
        #expect(polygonWithHolesData == polygonWithHoles.asJsonData(prettyPrinted: true))
    }

}

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

    // Validates loading Polygons (without and with holes) from JSON strings.
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

    // Validates creating Polygons and generating their JSON representations.
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

    // Validates that Polygon conforms to Encodable and matches the pretty-printed JSON output.
    @Test
    func encodable() async throws {
        let polygonNoHole = try #require(Polygon(jsonString: PolygonTests.polygonJsonNoHole))
        let polygonWithHoles = try #require(Polygon(jsonString: PolygonTests.polygonJsonWithHoles))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(polygonNoHole) == polygonNoHole.asJsonData(prettyPrinted: true))
        #expect(try encoder.encode(polygonWithHoles) == polygonWithHoles.asJsonData(prettyPrinted: true))
    }

    // Validates that Polygon conforms to Decodable and round-trips through JSON encoding.
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

    // Validates that Polygon equality handles shifted ring start vertices.
    @Test
    func equatable() async throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ]
        let polygonA = try #require(Polygon([coords]))
        let polygonB = try #require(Polygon([coords]))

        // Same vertices → equal
        #expect(polygonA == polygonB)

        // Shifted start vertex → still equal
        let shiftedCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
        ]
        let polygonShifted = try #require(Polygon([shiftedCoords]))
        #expect(polygonA == polygonShifted)

        // Different coordinates → not equal
        let otherCoords: [Coordinate3D] = [
            Coordinate3D(latitude: 10.0, longitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 101.0),
            Coordinate3D(latitude: 11.0, longitude: 101.0),
            Coordinate3D(latitude: 11.0, longitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 100.0)
        ]
        let polygonC = try #require(Polygon([otherCoords]))
        #expect(polygonA != polygonC)
    }

    // MARK: - Projection

    // Validates projecting a Polygon from EPSG:4326 to EPSG:3857.
    @Test
    func projected() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let projected = polygon.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.coordinates.count == 1)
        #expect(projected.coordinates[0].count == 5)
        for coord in projected.coordinates[0] {
            #expect(coord.projection == .epsg3857)
            #expect(coord.x.isFinite)
            #expect(coord.y.isFinite)
        }
    }

    // Validates projecting a Polygon from EPSG:4326 to EPSG:4978.
    @Test
    func projectedTo4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let projected = polygon.projected(to: .epsg4978)

        #expect(projected.projection == .epsg4978)
        for coord in projected.coordinates[0] {
            #expect(coord.projection == .epsg4978)
        }
    }

    // Validates projecting a Polygon from EPSG:4326 to noSRID.
    @Test
    func projectedToNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let projected = polygon.projected(to: .noSRID)

        #expect(projected.projection == .noSRID)
        for coord in projected.coordinates[0] {
            #expect(coord.projection == .noSRID)
            #expect(coord.x.isFinite)
            #expect(coord.y.isFinite)
        }
    }

    // Validates that projecting to the same projection returns self.
    @Test
    func projectedSameProjection() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let projected = polygon.projected(to: .epsg4326)
        #expect(projected.coordinates == polygon.coordinates)
    }

    // Validates creating a Polygon in EPSG:3857 using unchecked init.
    @Test
    func init3857() {
        let coords: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]
        let polygon = Polygon(unchecked: coords)

        #expect(polygon.projection == .epsg3857)
        #expect(polygon.coordinates == coords)
    }

    // Validates creating a Polygon in EPSG:4978 using unchecked init.
    @Test
    func init4978() {
        let coords: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0, z: 100.0, projection: .epsg4978),
            Coordinate3D(x: 10.0, y: 0.0, z: 100.0, projection: .epsg4978),
            Coordinate3D(x: 10.0, y: 10.0, z: 100.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 10.0, z: 100.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 100.0, projection: .epsg4978),
        ]]
        let polygon = Polygon(unchecked: coords)

        #expect(polygon.projection == .epsg4978)
        #expect(polygon.coordinates == coords)
    }

    // Validates creating a Polygon in noSRID using unchecked init.
    @Test
    func initNoSRID() {
        let coords: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]
        let polygon = Polygon(unchecked: coords)

        #expect(polygon.projection == .noSRID)
        #expect(polygon.coordinates == coords)
    }

    // MARK: - Bounding box

    // Validates the bounding box of a Polygon in EPSG:4326.
    @Test
    func boundingBox() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let bbox = try #require(polygon.calculateBoundingBox())

        #expect(bbox.projection == .epsg4326)
        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 10.0)
        #expect(bbox.northEast.longitude == 10.0)
    }

    // Validates the bounding box of a Polygon in EPSG:3857.
    @Test
    func boundingBox3857() async throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])

        let bbox = try #require(polygon.calculateBoundingBox())

        #expect(bbox.projection == .epsg3857)
        #expect(bbox.southWest.x == 0.0)
        #expect(bbox.southWest.y == 0.0)
        #expect(bbox.northEast.x == 10.0)
        #expect(bbox.northEast.y == 10.0)
    }

    // Validates that we can detect intersection with a bounding box.
    @Test
    func intersectsBoundingBox() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let overlapping = BoundingBox(
            southWest: Coordinate3D(latitude: 5.0, longitude: 5.0),
            northEast: Coordinate3D(latitude: 15.0, longitude: 15.0))
        #expect(polygon.intersects(overlapping))

        let farAway = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))
        #expect(!polygon.intersects(farAway))
    }

    // Validates bounding box is stored and returned from the property.
    @Test
    func boundingBoxProperty() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]], calculateBoundingBox: true))

        let bbox = try #require(polygon.boundingBox)
        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 1.0)
        #expect(bbox.northEast.longitude == 1.0)
    }

}

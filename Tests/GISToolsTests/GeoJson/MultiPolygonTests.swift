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

    // Validates loading a MultiPolygon from JSON and verifying its coordinates and foreign members.
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

    // Validates creating a MultiPolygon from coordinates and verifying its JSON string output.
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

    // Validates that a MultiPolygon encodes to JSON data matching its jsonData output.
    @Test
    func encodable() async throws {
        let multiPolygon = try #require(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(multiPolygon) == multiPolygon.asJsonData(prettyPrinted: true))
    }

    // Validates that a MultiPolygon round-trips through JSON encoding and decoding.
    @Test
    func decodable() async throws {
        let multiPolygonData = try #require(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson)?.asJsonData(prettyPrinted: true))
        let multiPolygon = try JSONDecoder().decode(MultiPolygon.self, from: multiPolygonData)

        #expect(multiPolygon.projection == .epsg4326)
        #expect(multiPolygonData == multiPolygon.asJsonData(prettyPrinted: true))
    }

    // Validates that MultiPolygon equality handles shifted ring start vertices.
    @Test
    func equatable() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0),
        ]]))
        let polygonB = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 102.0),
        ]]))
        let polygonBShifted = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 102.0),
            Coordinate3D(latitude: 2.0, longitude: 103.0),
            Coordinate3D(latitude: 3.0, longitude: 103.0),
        ]]))

        let multiA = MultiPolygon([polygonA, polygonB])!
        let multiB = MultiPolygon([polygonA, polygonB])!
        let multiBShifted = MultiPolygon([polygonA, polygonBShifted])!

        // Same polygons → equal
        #expect(multiA == multiB)

        // Shifted ring start → still equal
        #expect(multiA == multiBShifted)

        // Different polygons → not equal
        let polygonC = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 101.0),
            Coordinate3D(latitude: 11.0, longitude: 101.0),
            Coordinate3D(latitude: 11.0, longitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 100.0),
        ]]))
        let multiC = MultiPolygon([polygonA, polygonC])!
        #expect(multiA != multiC)
    }

    // MARK: - Projection

    // Validates projecting a MultiPolygon from EPSG:4326 to EPSG:3857.
    @Test
    func projected() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygonB = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 2.0, longitude: 3.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        let multiPolygon = MultiPolygon(unchecked: [polygonA, polygonB])

        let projected = multiPolygon.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.polygons.count == 2)
        for polygon in projected.polygons {
            #expect(polygon.projection == .epsg3857)
        }
    }

    // Validates projecting a MultiPolygon to EPSG:4978.
    @Test
    func projectedTo4978() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let multiPolygon = MultiPolygon(unchecked: [polygonA])

        let projected = multiPolygon.projected(to: .epsg4978)

        #expect(projected.projection == .epsg4978)
        for polygon in projected.polygons {
            #expect(polygon.projection == .epsg4978)
        }
    }

    // Validates projecting a MultiPolygon to noSRID.
    @Test
    func projectedToNoSRID() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let multiPolygon = MultiPolygon(unchecked: [polygonA])

        let projected = multiPolygon.projected(to: .noSRID)

        #expect(projected.projection == .noSRID)
        for polygon in projected.polygons {
            #expect(polygon.projection == .noSRID)
        }
    }

    // Validates creating a MultiPolygon in EPSG:3857 using unchecked init.
    @Test
    func init3857() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let multiPolygon = MultiPolygon(unchecked: [polygon])

        #expect(multiPolygon.projection == .epsg3857)
        #expect(multiPolygon.polygons.count == 1)
    }

    // MARK: - Bounding box

    // Validates the bounding box of a MultiPolygon in EPSG:4326.
    @Test
    func boundingBox() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygonB = try #require(Polygon([[
            Coordinate3D(latitude: 9.0, longitude: 9.0),
            Coordinate3D(latitude: 10.0, longitude: 9.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 9.0, longitude: 10.0),
            Coordinate3D(latitude: 9.0, longitude: 9.0),
        ]]))
        let multiPolygon = MultiPolygon(unchecked: [polygonA, polygonB])

        let bbox = try #require(multiPolygon.calculateBoundingBox())

        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 10.0)
        #expect(bbox.northEast.longitude == 10.0)
    }

    // Validates the bounding box of a MultiPolygon in EPSG:3857.
    @Test
    func boundingBox3857() async throws {
        let polygonA = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 5.0, y: 0.0),
            Coordinate3D(x: 5.0, y: 5.0),
            Coordinate3D(x: 0.0, y: 5.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let polygonB = Polygon(unchecked: [[
            Coordinate3D(x: 5.0, y: 5.0),
            Coordinate3D(x: 10.0, y: 5.0),
            Coordinate3D(x: 10.0, y: 10.0),
            Coordinate3D(x: 5.0, y: 10.0),
            Coordinate3D(x: 5.0, y: 5.0),
        ]])
        let multiPolygon = MultiPolygon(unchecked: [polygonA, polygonB])

        let bbox = try #require(multiPolygon.calculateBoundingBox())

        #expect(bbox.projection == .epsg3857)
        #expect(bbox.southWest.x == 0.0)
        #expect(bbox.southWest.y == 0.0)
        #expect(bbox.northEast.x == 10.0)
        #expect(bbox.northEast.y == 10.0)
    }

    // Validates intersects with a bounding box.
    @Test
    func intersectsBoundingBox() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let multiPolygon = MultiPolygon(unchecked: [polygonA])

        let overlapping = BoundingBox(
            southWest: Coordinate3D(latitude: 0.5, longitude: 0.5),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(multiPolygon.intersects(overlapping))

        let farAway = BoundingBox(
            southWest: Coordinate3D(latitude: 10.0, longitude: 10.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(!multiPolygon.intersects(farAway))
    }

    // Validates bounding box property when calculated on init.
    @Test
    func boundingBoxProperty() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon(
            [polygonA],
            calculateBoundingBox: true))

        let bbox = try #require(multiPolygon.boundingBox)
        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 1.0)
        #expect(bbox.northEast.longitude == 1.0)
    }

    // MARK: - Collection operations

    // Validates insertPolygon, appendPolygon, and removePolygon.
    @Test
    func collectionOps() async throws {
        let polygonA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygonB = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 2.0, longitude: 3.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        let polygonC = try #require(Polygon([[
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 5.0, longitude: 4.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 4.0, longitude: 5.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ]]))

        var multiPolygon = MultiPolygon(unchecked: [polygonA])

        multiPolygon.appendPolygon(polygonB)
        #expect(multiPolygon.polygons.count == 2)

        multiPolygon.insertPolygon(polygonC, atIndex: 0)
        #expect(multiPolygon.polygons.count == 3)
        #expect(multiPolygon.polygons[0].coordinates == polygonC.coordinates)

        let removed = multiPolygon.removePolygon(at: 1)
        #expect(removed?.coordinates == polygonA.coordinates)
        #expect(multiPolygon.polygons.count == 2)
    }

}

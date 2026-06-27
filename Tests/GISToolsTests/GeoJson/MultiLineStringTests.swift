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

    // Validates loading a MultiLineString from JSON and verifying its coordinates and foreign members.
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

    // Validates creating a MultiLineString from coordinates and verifying its JSON string output.
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

    // Validates that a MultiLineString encodes to JSON data matching its jsonData output.
    @Test
    func encodable() async throws {
        let multiLineString = try #require(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(multiLineString) == multiLineString.asJsonData(prettyPrinted: true))
    }

    // Validates that a MultiLineString round-trips through JSON encoding and decoding.
    @Test
    func decodable() async throws {
        let multiLineStringData = try #require(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson)?.asJsonData(prettyPrinted: true))
        let multiLineString = try JSONDecoder().decode(MultiLineString.self, from: multiLineStringData)

        #expect(multiLineString.projection == .epsg4326)
        #expect(multiLineStringData == multiLineString.asJsonData(prettyPrinted: true))
    }

    // MARK: - Projection

    // Validates projecting a MultiLineString from EPSG:4326 to EPSG:3857.
    @Test
    func projected() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let lineStringB = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineStringA, lineStringB]))

        let projected = multiLineString.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.lineStrings.count == 2)
        for ls in projected.lineStrings {
            #expect(ls.projection == .epsg3857)
        }
    }

    // Validates projecting a MultiLineString to EPSG:4978.
    @Test
    func projectedTo4978() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineStringA]))

        let projected = multiLineString.projected(to: .epsg4978)

        #expect(projected.projection == .epsg4978)
        for ls in projected.lineStrings {
            #expect(ls.projection == .epsg4978)
        }
    }

    // Validates projecting a MultiLineString to noSRID.
    @Test
    func projectedToNoSRID() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineStringA]))

        let projected = multiLineString.projected(to: .noSRID)

        #expect(projected.projection == .noSRID)
        for ls in projected.lineStrings {
            #expect(ls.projection == .noSRID)
        }
    }

    // Validates creating a MultiLineString in EPSG:3857 using unchecked init.
    @Test
    func init3857() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 10.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineString]))

        #expect(multiLineString.projection == .epsg3857)
        #expect(multiLineString.lineStrings.count == 1)
    }

    // MARK: - Bounding box

    // Validates the bounding box of a MultiLineString in EPSG:4326.
    @Test
    func boundingBox() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let lineStringB = try #require(LineString([
            Coordinate3D(latitude: 9.0, longitude: 9.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineStringA, lineStringB]))

        let bbox = try #require(multiLineString.calculateBoundingBox())

        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 10.0)
        #expect(bbox.northEast.longitude == 10.0)
    }

    // Validates the bounding box of a MultiLineString in EPSG:3857.
    @Test
    func boundingBox3857() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 5.0, y: 5.0),
        ]))
        let lineStringB = try #require(LineString([
            Coordinate3D(x: 5.0, y: 5.0),
            Coordinate3D(x: 10.0, y: 10.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineStringA, lineStringB]))

        let bbox = try #require(multiLineString.calculateBoundingBox())

        #expect(bbox.projection == .epsg3857)
        #expect(bbox.southWest.x == 0.0)
        #expect(bbox.southWest.y == 0.0)
        #expect(bbox.northEast.x == 10.0)
        #expect(bbox.northEast.y == 10.0)
    }

    // Validates intersects with a bounding box.
    @Test
    func intersectsBoundingBox() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let multiLineString = try #require(MultiLineString([lineStringA]))

        let overlapping = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(multiLineString.intersects(overlapping))

        let farAway = BoundingBox(
            southWest: Coordinate3D(latitude: 10.0, longitude: 10.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))
        #expect(!multiLineString.intersects(farAway))
    }

    // MARK: - Collection operations

    // Validates insertLineString, appendLineString, and removeLineString.
    @Test
    func collectionOps() async throws {
        let lineStringA = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let lineStringB = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]))
        let lineStringC = try #require(LineString([
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))

        var multiLineString = try #require(MultiLineString([lineStringA]))

        multiLineString.appendLineString(lineStringB)
        #expect(multiLineString.lineStrings.count == 2)

        multiLineString.insertLineString(lineStringC, atIndex: 0)
        #expect(multiLineString.lineStrings.count == 3)
        #expect(multiLineString.lineStrings[0].coordinates == lineStringC.coordinates)

        let removed = multiLineString.removeLineString(at: 1)
        #expect(removed?.coordinates == lineStringA.coordinates)
        #expect(multiLineString.lineStrings.count == 2)
    }

}

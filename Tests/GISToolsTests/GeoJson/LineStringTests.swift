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

    // Validates that isClosed returns false for open line strings and true for closed rings.
    @Test
    func isClosed() async throws {
        let open = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        #expect(!open.isClosed)

        let closed = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(closed.isClosed)

        #expect(LineString().isClosed == false)
    }

    // Validates firstCoordinate and lastCoordinate accessors.
    @Test
    func firstAndLastCoordinate() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))

        #expect(lineString.firstCoordinate == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(lineString.lastCoordinate == Coordinate3D(latitude: 2.0, longitude: 2.0))
    }

    // MARK: - Projection

    // Validates projecting a LineString from EPSG:4326 to EPSG:3857.
    @Test
    func projected() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected = lineString.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.coordinates.count == 2)
        for coord in projected.coordinates {
            #expect(coord.projection == .epsg3857)
            #expect(coord.x.isFinite)
            #expect(coord.y.isFinite)
        }
    }

    // Validates projecting a LineString from EPSG:4326 to EPSG:4978.
    @Test
    func projectedTo4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected = lineString.projected(to: .epsg4978)

        #expect(projected.projection == .epsg4978)
        for coord in projected.coordinates {
            #expect(coord.projection == .epsg4978)
        }
    }

    // Validates projecting a LineString from EPSG:4326 to noSRID.
    @Test
    func projectedToNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected = lineString.projected(to: .noSRID)

        #expect(projected.projection == .noSRID)
        for coord in projected.coordinates {
            #expect(coord.projection == .noSRID)
        }
    }

    // Validates round-trip projection from EPSG:4326 to EPSG:3857 and back.
    @Test
    func projected3857To4326() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected3857 = lineString.projected(to: .epsg3857)
        let roundTripped = projected3857.projected(to: .epsg4326)

        #expect(roundTripped.projection == .epsg4326)
        #expect(roundTripped.coordinates.count == 2)
        for (idx, coord) in roundTripped.coordinates.enumerated() {
            let original = lineString.coordinates[idx]
            #expect(abs(coord.latitude - original.latitude) < 0.0001)
            #expect(abs(coord.longitude - original.longitude) < 0.0001)
        }
    }

    // Validates creating a LineString in EPSG:3857 using unchecked init.
    @Test
    func init3857() throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 10.0),
        ]
        let lineString = try #require(LineString(coords))

        #expect(lineString.projection == .epsg3857)
        #expect(lineString.coordinates == coords)
    }

    // Validates creating a LineString in EPSG:4978 using unchecked init.
    @Test
    func init4978() throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0, z: 100.0, projection: .epsg4978),
            Coordinate3D(x: 10.0, y: 10.0, z: 200.0, projection: .epsg4978),
        ]
        let lineString = try #require(LineString(coords))

        #expect(lineString.projection == .epsg4978)
        #expect(lineString.coordinates == coords)
    }

    // Validates creating a LineString in noSRID using unchecked init.
    @Test
    func initNoSRID() throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
        ]
        let lineString = try #require(LineString(coords))

        #expect(lineString.projection == .noSRID)
        #expect(lineString.coordinates == coords)
    }

    // MARK: - Bounding box

    // Validates the bounding box of a LineString in EPSG:4326.
    @Test
    func boundingBox() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))

        let bbox = try #require(lineString.calculateBoundingBox())

        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 10.0)
        #expect(bbox.northEast.longitude == 10.0)
    }

    // Validates the bounding box of a LineString in EPSG:3857.
    @Test
    func boundingBox3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 0.0),
            Coordinate3D(x: 10.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 10.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]))

        let bbox = try #require(lineString.calculateBoundingBox())

        #expect(bbox.projection == .epsg3857)
        #expect(bbox.southWest.x == 0.0)
        #expect(bbox.southWest.y == 0.0)
        #expect(bbox.northEast.x == 10.0)
        #expect(bbox.northEast.y == 10.0)
    }

    // Validates intersects with a bounding box.
    @Test
    func intersectsBoundingBox() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))

        let overlapping = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(lineString.intersects(overlapping))

        let farAway = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))
        #expect(!lineString.intersects(farAway))
    }

    // Validates bounding box property when calculated on init.
    @Test
    func boundingBoxProperty() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ], calculateBoundingBox: true))

        let bbox = try #require(lineString.boundingBox)
        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 1.0)
        #expect(bbox.northEast.longitude == 1.0)
    }

}

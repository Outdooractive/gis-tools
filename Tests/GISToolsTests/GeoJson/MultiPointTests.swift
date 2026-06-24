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

    // Validates loading a MultiPoint from JSON and verifying its coordinates and foreign members.
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

    // Validates creating a MultiPoint from coordinates and verifying its JSON string output.
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

    // Validates that a MultiPoint encodes to JSON data matching its jsonData output.
    @Test
    func encodable() async throws {
        let multiPoint = try #require(MultiPoint(jsonString: MultiPointTests.multiPointJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(multiPoint) == multiPoint.asJsonData(prettyPrinted: true))
    }

    // Validates that a MultiPoint round-trips through JSON encoding and decoding.
    @Test
    func decodable() async throws {
        let multiPointData = try #require(MultiPoint(jsonString: MultiPointTests.multiPointJson)?.asJsonData(prettyPrinted: true))
        let multiPoint = try JSONDecoder().decode(MultiPoint.self, from: multiPointData)

        #expect(multiPoint.projection == .epsg4326)
        #expect(multiPointData == multiPoint.asJsonData(prettyPrinted: true))
    }

    // MARK: - Projection

    // Validates projecting a MultiPoint from EPSG:4326 to EPSG:3857.
    @Test
    func projected() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected = multiPoint.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.points.count == 2)
        for point in projected.points {
            #expect(point.projection == .epsg3857)
        }
    }

    // Validates projecting a MultiPoint to EPSG:4978.
    @Test
    func projectedTo4978() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected = multiPoint.projected(to: .epsg4978)

        #expect(projected.projection == .epsg4978)
        for point in projected.points {
            #expect(point.projection == .epsg4978)
        }
    }

    // Validates projecting a MultiPoint to noSRID.
    @Test
    func projectedToNoSRID() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let projected = multiPoint.projected(to: .noSRID)

        #expect(projected.projection == .noSRID)
        for point in projected.points {
            #expect(point.projection == .noSRID)
        }
    }

    // Validates creating a MultiPoint in EPSG:3857 using unchecked init.
    @Test
    func init3857() {
        let pointA = Point(Coordinate3D(x: 0.0, y: 0.0))
        let pointB = Point(Coordinate3D(x: 10.0, y: 10.0))
        let multiPoint = MultiPoint(unchecked: [pointA, pointB])

        #expect(multiPoint.projection == .epsg3857)
        #expect(multiPoint.points.count == 2)
    }

    // MARK: - Bounding box

    // Validates the bounding box of a MultiPoint in EPSG:4326.
    @Test
    func boundingBox() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))

        let bbox = try #require(multiPoint.calculateBoundingBox())

        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 10.0)
        #expect(bbox.northEast.longitude == 10.0)
    }

    // Validates the bounding box of a MultiPoint in EPSG:3857.
    @Test
    func boundingBox3857() async throws {
        let pointA = Point(Coordinate3D(x: 0.0, y: 0.0))
        let pointB = Point(Coordinate3D(x: 10.0, y: 10.0))
        let multiPoint = MultiPoint(unchecked: [pointA, pointB])

        let bbox = try #require(multiPoint.calculateBoundingBox())

        #expect(bbox.projection == .epsg3857)
        #expect(bbox.southWest.x == 0.0)
        #expect(bbox.southWest.y == 0.0)
        #expect(bbox.northEast.x == 10.0)
        #expect(bbox.northEast.y == 10.0)
    }

    // Validates intersects with a bounding box.
    @Test
    func intersectsBoundingBox() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
        ]))

        let overlapping = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(multiPoint.intersects(overlapping))

        let farAway = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))
        #expect(!multiPoint.intersects(farAway))
    }

    // MARK: - Collection operations

    // Validates insertPoint, appendPoint, and removePoint.
    @Test
    func collectionOps() async throws {
        let pointA = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let pointB = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        let pointC = Point(Coordinate3D(latitude: 2.0, longitude: 2.0))

        var multiPoint = MultiPoint(unchecked: [pointA])

        multiPoint.appendPoint(pointB)
        #expect(multiPoint.points.count == 2)

        multiPoint.insertPoint(pointC, atIndex: 0)
        #expect(multiPoint.points.count == 3)
        #expect(multiPoint.points[0].coordinate == pointC.coordinate)

        let removed = multiPoint.removePoint(at: 1)
        #expect(removed?.coordinate == pointA.coordinate)
        #expect(multiPoint.points.count == 2)
    }

}

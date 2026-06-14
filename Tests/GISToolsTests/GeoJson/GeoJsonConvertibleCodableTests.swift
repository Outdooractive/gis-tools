import Foundation
@testable import GISTools
import Testing

struct GeoJsonConvertibleCodableTests {

    private let pointJson = """
    {"type":"Point","coordinates":[100.0,0.0]}
    """
    private let invalidJson = """
    {not valid json}
    """
    private let notGeoJson = """
    {"type":"NotAGeoJsonType","coordinates":[]}
    """

    // MARK: - GeoJsonReadable

    @Test
    func initFromJsonWithNil() async throws {
        let point: Point? = Point(json: nil)

        #expect(point == nil)
    }

    @Test
    func initFromJsonWithInvalidType() async throws {
        let pointFromString: Point? = Point(json: "not a dictionary")
        let pointFromNumber: Point? = Point(json: 42)

        #expect(pointFromString == nil)
        #expect(pointFromNumber == nil)
    }

    @Test
    func initFromValidJsonString() async throws {
        let point = try #require(Point(jsonString: pointJson))

        #expect(point.type == .point)
        #expect(point.projection == .epsg4326)
        #expect(point.coordinate == Coordinate3D(latitude: 0.0, longitude: 100.0))
    }

    @Test
    func initFromInvalidJsonString() async throws {
        let point: Point? = Point(jsonString: invalidJson)

        #expect(point == nil)
    }

    @Test
    func initFromJsonStringWithWrongType() async throws {
        let point: Point? = Point(jsonString: notGeoJson)

        #expect(point == nil)
    }

    @Test
    func initFromValidJsonData() async throws {
        let data = try #require(pointJson.data(using: .utf8))
        let point = try #require(Point(jsonData: data))

        #expect(point.type == .point)
    }

    @Test
    func initFromInvalidJsonData() async throws {
        let data = Data([0x00, 0x01, 0x02])
        let point: Point? = Point(jsonData: data)

        #expect(point == nil)
    }

    @Test
    func initFromContentsOfUrl() async throws {
        let data = try #require(pointJson.data(using: .utf8))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_point_\(UUID().uuidString).geojson")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let point = try #require(Point(contentsOf: url))

        #expect(point.type == .point)
    }

    @Test
    func initFromContentsOfUrlWithMissingFile() async throws {
        let url = URL(fileURLWithPath: "/nonexistent/file.geojson")
        let point: Point? = Point(contentsOf: url)

        #expect(point == nil)
    }

    // MARK: - GeoJsonWritable

    @Test
    func asJsonDictionary() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let json = point.asJson

        #expect(json["type"] as? String == "Point")
        #expect(json["coordinates"] as? [Double] == [100.0, 0.0])
    }

    @Test
    func asJsonData() async throws {
        let point = try #require(Point(jsonString: pointJson))
        let data = try #require(point.asJsonData())

        let parsed = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(parsed["type"] as? String == "Point")
    }

    @Test
    func asJsonString() async throws {
        let point = try #require(Point(jsonString: pointJson))
        let string = try #require(point.asJsonString())

        #expect(string.contains("\"type\":\"Point\""))
    }

    @Test
    func asJsonDataPrettyPrinted() async throws {
        let point = try #require(Point(jsonString: pointJson))
        let compact = try #require(point.asJsonData(prettyPrinted: false))
        let pretty = try #require(point.asJsonData(prettyPrinted: true))

        #expect(compact.count <= pretty.count)
    }

    @Test
    func jsonRoundTrip() async throws {
        let original = Point(Coordinate3D(latitude: 42.0, longitude: -71.0))
        let json = original.asJson
        let roundTripped = try #require(Point(json: json))

        #expect(original == roundTripped)
    }

    @Test
    func stringRoundTrip() async throws {
        let original = Point(Coordinate3D(latitude: 42.0, longitude: -71.0))
        let string = try #require(original.asJsonString())
        let roundTripped = try #require(Point(jsonString: string))

        #expect(original == roundTripped)
    }

    @Test
    func writeToUrl() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_write_\(UUID().uuidString).geojson")
        defer { try? FileManager.default.removeItem(at: url) }

        let success = point.write(to: url, prettyPrinted: true)
        #expect(success)

        let readBack = try #require(Point(contentsOf: url))
        #expect(point == readBack)
    }

    @Test
    func writeToInvalidUrl() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let url = URL(fileURLWithPath: "/nonexistent/directory/test.geojson")

        let success = point.write(to: url)
        #expect(!success)
    }

    @Test
    func dumpDoesNotCrash() {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

        point.dump()
    }

    // MARK: - Sequence asJson

    @Test
    func sequenceAsJson() async throws {
        let points = [
            Point(Coordinate3D(latitude: 0.0, longitude: 100.0)),
            Point(Coordinate3D(latitude: 1.0, longitude: 101.0)),
        ]
        let jsonArray = points.asJson

        #expect(jsonArray.count == 2)
        #expect(jsonArray[0]["type"] as? String == "Point")
        #expect(jsonArray[1]["type"] as? String == "Point")
    }

    // MARK: - Codable edge cases

    @Test
    func codableWithInvalidDataThrows() async throws {
        let invalidData = Data([0x00, 0x01, 0x02])

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Point.self, from: invalidData)
        }
    }

    @Test
    func codableWithEmptyJsonObjectThrows() async throws {
        let emptyData = try #require("{}".data(using: .utf8))

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Point.self, from: emptyData)
        }
    }

    @Test
    func codableWithMismatchedTypeThrows() async throws {
        // Polygon JSON decoded as Point
        let polygonJson = """
        {"type":"Polygon","coordinates":[[[100,0],[101,0],[101,1],[100,1],[100,0]]]}
        """
        let data = try #require(polygonJson.data(using: .utf8))

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Point.self, from: data)
        }
    }

    @Test
    func codableCoordinate3DRoundTrip() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234)
        let data = try JSONEncoder().encode(coordinate)
        let decoded = try JSONDecoder().decode(Coordinate3D.self, from: data)

        #expect(decoded == coordinate)
    }

    @Test
    func codableBoundingBoxRoundTrip() async throws {
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let data = try JSONEncoder().encode(box)
        let decoded = try JSONDecoder().decode(BoundingBox.self, from: data)

        #expect(decoded == box)
    }

}

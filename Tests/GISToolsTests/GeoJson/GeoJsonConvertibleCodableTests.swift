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

    // Validates that initializing from a nil JSON value returns nil.
    @Test
    func initFromJsonWithNil() async throws {
        let point: Point? = Point(json: nil)

        #expect(point == nil)
    }

    // Validates that initializing from a non-dictionary JSON value returns nil.
    @Test
    func initFromJsonWithInvalidType() async throws {
        let pointFromString: Point? = Point(json: "not a dictionary")
        let pointFromNumber: Point? = Point(json: 42)

        #expect(pointFromString == nil)
        #expect(pointFromNumber == nil)
    }

    // Validates initializing a Point from a valid JSON string.
    @Test
    func initFromValidJsonString() async throws {
        let point = try #require(Point(jsonString: pointJson))

        #expect(point.type == .point)
        #expect(point.projection == .epsg4326)
        #expect(point.coordinate == Coordinate3D(latitude: 0.0, longitude: 100.0))
    }

    // Validates that initializing from invalid JSON string returns nil.
    @Test
    func initFromInvalidJsonString() async throws {
        let point: Point? = Point(jsonString: invalidJson)

        #expect(point == nil)
    }

    // Validates that initializing with wrong GeoJSON type returns nil.
    @Test
    func initFromJsonStringWithWrongType() async throws {
        let point: Point? = Point(jsonString: notGeoJson)

        #expect(point == nil)
    }

    // Validates initializing a Point from valid JSON data.
    @Test
    func initFromValidJsonData() async throws {
        let data = try #require(pointJson.data(using: .utf8))
        let point = try #require(Point(jsonData: data))

        #expect(point.type == .point)
    }

    // Validates that initializing from invalid JSON data returns nil.
    @Test
    func initFromInvalidJsonData() async throws {
        let data = Data([0x00, 0x01, 0x02])
        let point: Point? = Point(jsonData: data)

        #expect(point == nil)
    }

    // Validates initializing a Point from a file URL.
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

    // Validates that initializing from a missing file URL returns nil.
    @Test
    func initFromContentsOfUrlWithMissingFile() async throws {
        let url = URL(fileURLWithPath: "/nonexistent/file.geojson")
        let point: Point? = Point(contentsOf: url)

        #expect(point == nil)
    }

    // MARK: - GeoJsonWritable

    // Validates that asJson returns the expected dictionary representation.
    @Test
    func asJsonDictionary() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let json = point.asJson

        #expect(json["type"] as? String == "Point")
        #expect(json["coordinates"] as? [Double] == [100.0, 0.0])
    }

    // Validates that asJsonData returns valid JSON data.
    @Test
    func asJsonData() async throws {
        let point = try #require(Point(jsonString: pointJson))
        let data = try #require(point.asJsonData())

        let parsed = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(parsed["type"] as? String == "Point")
    }

    // Validates that asJsonString returns a valid JSON string.
    @Test
    func asJsonString() async throws {
        let point = try #require(Point(jsonString: pointJson))
        let string = try #require(point.asJsonString())

        #expect(string.contains("\"type\":\"Point\""))
    }

    // Validates that pretty-printed JSON data is larger than compact data.
    @Test
    func asJsonDataPrettyPrinted() async throws {
        let point = try #require(Point(jsonString: pointJson))
        let compact = try #require(point.asJsonData(prettyPrinted: false))
        let pretty = try #require(point.asJsonData(prettyPrinted: true))

        #expect(compact.count <= pretty.count)
    }

    // Validates that a Point round-trips through JSON dictionary conversion.
    @Test
    func jsonRoundTrip() async throws {
        let original = Point(Coordinate3D(latitude: 42.0, longitude: -71.0))
        let json = original.asJson
        let roundTripped = try #require(Point(json: json))

        #expect(original == roundTripped)
    }

    // Validates that a Point round-trips through JSON string conversion.
    @Test
    func stringRoundTrip() async throws {
        let original = Point(Coordinate3D(latitude: 42.0, longitude: -71.0))
        let string = try #require(original.asJsonString())
        let roundTripped = try #require(Point(jsonString: string))

        #expect(original == roundTripped)
    }

    // Validates writing a Point to a file URL and reading it back.
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

    // Validates that writing to an invalid URL returns false.
    @Test
    func writeToInvalidUrl() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let url = URL(fileURLWithPath: "/nonexistent/directory/test.geojson")

        let success = point.write(to: url)
        #expect(!success)
    }

    // Validates that dump does not crash.
    @Test
    func dumpDoesNotCrash() {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))

        point.dump()
    }

    // MARK: - Property value preservation (#255, #256)

    private let propertiesJson = #"""
    {"type":"Feature","geometry":{"type":"Point","coordinates":[1.5,2.5]},"properties":{"flag":true,"off":false,"arr":[1,2.5,"x",true],"nested":{"a":1,"b":[true]},"i":15,"d":17.5,"none":null}}
    """#

    // Encoding a parsed Feature must preserve booleans, numbers, nested
    // values and JSON null instead of coercing or dropping them.
    @Test
    func codableEncodingPreservesPropertyValues() async throws {
        let feature = try #require(Feature(jsonString: propertiesJson))
        let data = try JSONEncoder().encode(feature)
        let encoded = try #require(JSONValue(jsonData: data))

        #expect(encoded["properties"]?["flag"] == .bool(true))
        #expect(encoded["properties"]?["off"] == .bool(false))
        #expect(encoded["properties"]?["arr"] == .array([.int(1), .number(2.5), .string("x"), .bool(true)]))
        #expect(encoded["properties"]?["nested"] == .object([
            "a": .int(1),
            "b": .array([.bool(true)]),
        ]))
        #expect(encoded["properties"]?["i"] == .int(15))
        #expect(encoded["properties"]?["d"] == .number(17.5))
        #expect(encoded["properties"]?["none"] == .null)

        let decoded = try JSONDecoder().decode(Feature.self, from: data)
        #expect(decoded == feature)
    }

    // Decoding a Feature with a null property must not fail and must keep
    // the value as NSNull.
    @Test
    func codableDecodingPreservesNullProperty() async throws {
        let data = try #require(propertiesJson.data(using: .utf8))
        let feature = try JSONDecoder().decode(Feature.self, from: data)

        #expect(JSONValue(value: feature.properties["flag"]) == .bool(true))
        #expect(JSONValue(value: feature.properties["off"]) == .bool(false))
        #expect(JSONValue(value: feature.properties["none"]) == .null)
        #expect(feature.properties["none"] is NSNull)
        #expect(JSONValue(value: feature.properties["i"]) == .int(15))
        #expect(JSONValue(value: feature.properties["d"]) == .number(17.5))
    }

    // A FeatureCollection with an unlocated feature ("geometry": null) keeps
    // that feature and its properties.
    @Test
    func codableDecodingFeatureCollectionWithNullGeometry() async throws {
        let json = #"""
        {"type":"FeatureCollection","features":[
          {"type":"Feature","geometry":null,"properties":{"a":1}},
          {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{"a":2}}
        ]}
        """#
        let data = try #require(json.data(using: .utf8))
        let collection = try JSONDecoder().decode(FeatureCollection.self, from: data)

        #expect(collection.features.count == 2)
        #expect(collection.features[0].geometry == nil)
        #expect(JSONValue(value: collection.features[0].properties["a"]) == .int(1))
        #expect(collection.features[1].geometry != nil)
    }

    // MARK: - JSON text precision and key order (#261)

    // Coordinates written by the library read back bit-exactly.
    @Test
    func jsonDataRoundTripsCoordinatesBitExactly() async throws {
        let values = [-0.07, 0.1, 48.1362829626354, 0.3, 1.1]
        let line = try #require(LineString(values.map {
            Coordinate3D(latitude: 0.0, longitude: $0)
        }))
        let data = try #require(line.asJsonData())
        let string = try #require(String(data: data, encoding: .utf8))

        #expect(string.contains("-0.07"))
        #expect(!string.contains("-0.070000000000000007"))

        let reread = try #require(LineString(jsonData: data))
        #expect(zip(values, reread.coordinates.map(\.longitude)).allSatisfy {
            $0.bitPattern == $1.bitPattern
        })

        let viaDecoder = try JSONDecoder().decode([String: JSONValue].self, from: data)
        let decoded = try #require(viaDecoder["coordinates"]?.arrayValue)
            .map { $0[0]?.doubleValue }
        #expect(zip(values, decoded).allSatisfy { value, decoded in
            decoded.map { value.bitPattern == $0.bitPattern } ?? false
        })
    }

    // Object keys are sorted by default and stable across calls.
    @Test
    func jsonKeysAreSortedAndStable() async throws {
        let json = #"""
        {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{"b":1,"a":2,"c":3}}
        """#
        let feature = try #require(Feature(jsonString: json))

        let strings = try (0 ..< 3).map { _ in
            try #require(feature.asJsonString())
        }

        #expect(Set(strings).count == 1)

        let sorted = strings[0]
        let a = try #require(sorted.range(of: "\"a\""))
        let b = try #require(sorted.range(of: "\"b\""))
        let c = try #require(sorted.range(of: "\"c\""))

        #expect(a.lowerBound < b.lowerBound)
        #expect(b.lowerBound < c.lowerBound)
    }

    // Sorting is independent of pretty printing.
    @Test
    func jsonSortedKeysIndependentOfPrettyPrinting() async throws {
        let point = try #require(Point(jsonString: pointJson))

        let compact = try #require(point.asJsonData(prettyPrinted: false))
        let pretty = try #require(point.asJsonData(prettyPrinted: true))

        #expect(compact.count < pretty.count)

        let compactValue = try JSONDecoder().decode(JSONValue.self, from: compact)
        let prettyValue = try JSONDecoder().decode(JSONValue.self, from: pretty)
        #expect(compactValue == prettyValue)
    }

    // Disabling key sorting still produces valid, decodable JSON.
    @Test
    func jsonUnsortedKeysRoundTrip() async throws {
        let feature = try #require(Feature(jsonString: #"""
        {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{"b":1,"a":2}}
        """#))

        let string = try #require(feature.asJsonString(sortedKeys: false))
        let data = try #require(string.data(using: .utf8))
        let decoded = try JSONDecoder().decode(Feature.self, from: data)

        #expect(decoded == feature)
    }

    // MARK: - Sequence asJson

    // Validates that Sequence of GeoJson produces correct JSON array.
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

    // Validates that decoding invalid data throws an error.
    @Test
    func codableWithInvalidDataThrows() async throws {
        let invalidData = Data([0x00, 0x01, 0x02])

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Point.self, from: invalidData)
        }
    }

    // Validates that decoding an empty JSON object throws an error.
    @Test
    func codableWithEmptyJsonObjectThrows() async throws {
        let emptyData = try #require("{}".data(using: .utf8))

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Point.self, from: emptyData)
        }
    }

    // Validates that decoding a mismatched GeoJSON type throws an error.
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

    // Validates Coordinate3D round-trips through Codable.
    @Test
    func codableCoordinate3DRoundTrip() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234)
        let data = try JSONEncoder().encode(coordinate)
        let decoded = try JSONDecoder().decode(Coordinate3D.self, from: data)

        #expect(decoded == coordinate)
    }

    // Validates decoding a coordinate written with integer literals.
    @Test
    func codableCoordinate3DFromIntegerJson() async throws {
        let data = try #require("[10,15]".data(using: .utf8))
        let decoded = try JSONDecoder().decode(Coordinate3D.self, from: data)

        #expect(decoded == Coordinate3D(latitude: 15.0, longitude: 10.0))
    }

    // Validates BoundingBox round-trips through Codable.
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

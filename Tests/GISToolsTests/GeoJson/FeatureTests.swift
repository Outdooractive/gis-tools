import Foundation
@testable import GISTools
import Testing

struct FeatureTests {

    static let featureJson = """
    {
       "type": "Feature",
       "geometry": {
           "type": "Polygon",
           "coordinates": [
               [
                   [100.0, 0.0],
                   [101.0, 0.0],
                   [101.0, 1.0],
                   [100.0, 1.0],
                   [100.0, 0.0]
               ]
           ]
       },
       "properties": {
           "prop0": "value0",
           "prop1": {
               "this": "that"
           }
       },
       "other": "something else",
       "id": "abcd.1234"
    }
    """

    // Validates loading a Feature with a string ID from JSON and accessing its properties and foreign members.
    @Test
    func loadJson() async throws {
        let feature = try #require(Feature(jsonString: FeatureTests.featureJson))

        #expect(feature.type == GeoJsonType.feature)
        #expect(feature.projection == .epsg4326)
        #expect(feature.geometry.type == GeoJsonType.polygon)
        #expect(feature.properties.count == 2)
        #expect(feature.properties.keys.sorted() == ["prop0", "prop1"])
        #expect(feature.property(for: "prop0") == "value0")
        #expect(feature["prop0"] == "value0")
        #expect(feature.foreignMember(for: "other") == "something else")
        #expect(feature[foreignMember: "other"] == "something else")
        #expect(feature.id == .string("abcd.1234"))
    }

    static let featureJsonWithIntId = """
    {
       "type": "Feature",
       "geometry": {
           "type": "Polygon",
           "coordinates": [
               [
                   [100.0, 0.0],
                   [101.0, 0.0],
                   [101.0, 1.0],
                   [100.0, 1.0],
                   [100.0, 0.0]
               ]
           ]
       },
       "properties": {
           "prop0": "value0",
           "prop1": {
               "this": "that"
           }
       },
       "other": "something else",
       "id": 1234
    }
    """

    // Validates loading a Feature with an integer ID from JSON.
    @Test
    func loadJsonWithIntId() async throws {
        let feature = try #require(Feature(jsonString: FeatureTests.featureJsonWithIntId))

        #expect(feature.id == .int(1234))
        #expect(feature.projection == .epsg4326)
    }

    // Validates creating a Feature from a geometry and verifying its JSON output.
    @Test
    func createJson() async throws {
        let feature = Feature(Point(.zero), id: .int(5))
        #expect(feature.projection == .epsg4326)
        let json = feature.asJson
        #expect(json["type"] as? String == "Feature")
        #expect(json["id"] as? Int == 5)
        let geometry = json["geometry"] as! [String: Any]
        #expect(geometry["type"] as? String == "Point")
        #expect(geometry["coordinates"] as? [Double] == [0.0, 0.0])
    }

    // Validates that a Feature encodes to JSON data matching its jsonData output.
    @Test
    func encodable() async throws {
        let feature = try #require(Feature(jsonString: FeatureTests.featureJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(feature) == feature.asJsonData(prettyPrinted: true))
    }

    // Validates that a Feature round-trips through JSON encoding and decoding.
    @Test
    func decodable() async throws {
        let featureData = try #require(Feature(jsonString: FeatureTests.featureJson)?.asJsonData(prettyPrinted: true))
        let feature = try JSONDecoder().decode(Feature.self, from: featureData)

        #expect(feature.projection == .epsg4326)
        #expect(featureData == feature.asJsonData(prettyPrinted: true))
    }

    // Validates that Feature.Identifier handles various signed and unsigned integer types correctly.
    @Test
    func featureIds() async throws {
        #expect(Feature.Identifier(value: 1234) == .int(1234))
        #expect(Feature.Identifier(value: Int8(32)) == .int(32))
        #expect(Feature.Identifier(value: Int8(32))?.int64Value == 32)
        #expect(Feature.Identifier(value: Int8(32))?.uint64Value == 32)

        #expect(Feature.Identifier(value: -1234) == .int(-1234))
        #expect(Feature.Identifier(value: Int8(-32)) == .int(-32))
        #expect(Feature.Identifier(value: Int8(-32))?.int64Value == -32)
        #expect(Feature.Identifier(value: Int8(-32))?.uint64Value == nil)

        // UInt -> Int
        #expect(Feature.Identifier(value: UInt64(32)) == .int(32))

        #expect(Feature.Identifier(value: Int64.max) == .int(9223372036854775807))
        #expect(Feature.Identifier(value: Int64.max)?.int64Value == 9223372036854775807)
        #expect(Feature.Identifier(value: Int64.min) == .int(-9223372036854775808))
        #expect(Feature.Identifier(value: Int64.min)?.int64Value == -9223372036854775808)

        // 9223372036854775808 is Int64.max+1
        #expect(Feature.Identifier(value: UInt64(9223372036854775808)) == .uint(9223372036854775808))
        #expect(Feature.Identifier(value: UInt64(9223372036854775808))?.int64Value == nil)
        #expect(Feature.Identifier(value: UInt64(9223372036854775808))?.uint64Value == 9223372036854775808)
    }

    // MARK: - Typed properties

    private struct RegionProperties: Codable, Equatable {
        let isoCode: String
        let name: String
        let priority: Int
    }

    // Validates decoding properties into a domain type.
    @Test
    func propertiesAs() async throws {
        let json = """
        {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [8.5, 47.3] },
            "properties": { "isoCode": "CH", "name": "Zurich", "priority": 3 }
        }
        """
        let feature = try #require(Feature(jsonString: json))

        let properties = try feature.properties(as: RegionProperties.self)

        #expect(properties == RegionProperties(isoCode: "CH", name: "Zurich", priority: 3))
    }

    // Validates that properties written as 3.0 decode into Int fields.
    @Test
    func propertiesAsNormalizesNumbers() async throws {
        let json = """
        {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [8.5, 47.3] },
            "properties": { "isoCode": "CH", "name": "Zurich", "priority": 3.0 }
        }
        """
        let feature = try #require(Feature(jsonString: json))

        let properties = try feature.properties(as: RegionProperties.self)

        #expect(properties == RegionProperties(isoCode: "CH", name: "Zurich", priority: 3))
    }

    // Validates that type mismatches and missing keys throw real errors
    // instead of failing silently.
    @Test
    func propertiesAsErrors() async throws {
        let mismatchJson = """
        {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [8.5, 47.3] },
            "properties": { "isoCode": "CH", "name": "Zurich", "priority": "high" }
        }
        """
        let featureMismatch = try #require(Feature(jsonString: mismatchJson))

        #expect(throws: DecodingError.self) {
            try featureMismatch.properties(as: RegionProperties.self)
        }

        let missingJson = """
        {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [8.5, 47.3] },
            "properties": { "isoCode": "CH", "name": "Zurich" }
        }
        """
        let featureMissing = try #require(Feature(jsonString: missingJson))

        #expect(throws: DecodingError.self) {
            try featureMissing.properties(as: RegionProperties.self)
        }
    }

    // Validates that the optional decoder parameter is applied
    // (e.g. the snake_case key decoding strategy).
    @Test
    func propertiesAsDecoderStrategy() async throws {
        struct SnakeCaseProperties: Codable, Equatable {
            let isoCode: String
        }

        let json = """
        {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [8.5, 47.3] },
            "properties": { "iso_code": "CH" }
        }
        """
        let feature = try #require(Feature(jsonString: json))

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let properties = try feature.properties(as: SnakeCaseProperties.self, decoder: decoder)

        #expect(properties == SnakeCaseProperties(isoCode: "CH"))
    }

    // Validates that non-JSON-compatible property values throw.
    @Test
    func propertiesAsNotJsonCompatible() async throws {
        var feature = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        feature.properties["data"] = Data([0x01])

        #expect(throws: DecodingError.self) {
            try feature.properties(as: [String: JSONValue].self)
        }
    }

    // Validates creating a Feature from Encodable properties and reading
    // them back with properties(as:).
    @Test
    func initEncodedProperties() async throws {
        let feature = try Feature(
            Point(Coordinate3D(latitude: 47.3, longitude: 8.5)),
            encodedProperties: RegionProperties(isoCode: "CH", name: "Zurich", priority: 3))

        #expect(feature.properties["isoCode"] as? String == "CH")
        #expect(feature.properties["name"] as? String == "Zurich")
        #expect(feature.properties["priority"] as? Int == 3)

        let properties = try feature.properties(as: RegionProperties.self)
        #expect(properties == RegionProperties(isoCode: "CH", name: "Zurich", priority: 3))

        let jsonProperties = try #require(feature.asJson["properties"] as? [String: Sendable])
        #expect(jsonProperties["priority"] as? Int == 3)
    }

    // Validates that non-object Encodable properties throw.
    @Test
    func initEncodedPropertiesNotAnObject() async throws {
        #expect(throws: EncodingError.self) {
            try Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)), encodedProperties: [1, 2, 3])
        }
        #expect(throws: EncodingError.self) {
            try Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)), encodedProperties: 42)
        }
    }

    // Validates the JSONValue and coercing accessors.
    @Test
    func typedAccessors() async throws {
        let json = """
        {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [8.5, 47.3] },
            "properties": {
                "string": "text",
                "int": 3,
                "fractionalInt": 3.0,
                "fractional": 3.5,
                "bool": true,
                "null": null
            }
        }
        """
        let feature = try #require(Feature(jsonString: json))

        #expect(feature.stringValue(for: "string") == "text")
        #expect(feature.intValue(for: "int") == 3)
        #expect(feature.intValue(for: "fractionalInt") == 3)
        #expect(feature.intValue(for: "fractional") == nil)
        #expect(feature.doubleValue(for: "int") == 3.0)
        #expect(feature.doubleValue(for: "fractional") == 3.5)
        #expect(feature.boolValue(for: "bool") == true)
        #expect(feature.boolValue(for: "int") == nil)
        #expect(feature.stringValue(for: "missing") == nil)

        #expect(feature.jsonValue(for: "int") == .int(3))
        #expect(feature.jsonValue(for: "fractional") == .number(3.5))
        #expect(feature.jsonValue(for: "null") == .null)
        #expect(feature.jsonValue(for: "missing") == nil)

        // Exhaustive pattern matching over property values
        if case .number(let double) = feature.jsonValue(for: "fractional") {
            #expect(double == 3.5)
        }
        else {
            Issue.record("Expected a .number value")
        }
    }

    // Validates that typed property access works in all projections and
    // survives reprojection.
    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func typedPropertiesAllProjections(_ projection: Projection) async throws {
        let point = Point(Coordinate3D(latitude: 47.3, longitude: 8.5)).projected(to: projection)
        let feature = try Feature(
            point,
            encodedProperties: RegionProperties(isoCode: "CH", name: "Zurich", priority: 3))

        #expect(feature.projection == projection)
        let properties = try feature.properties(as: RegionProperties.self)
        #expect(properties == RegionProperties(isoCode: "CH", name: "Zurich", priority: 3))

        let targetProjection: Projection = projection == .epsg4326 ? .epsg3857 : .epsg4326
        let projected = feature.projected(to: targetProjection)
        let projectedProperties = try projected.properties(as: RegionProperties.self)

        #expect(projectedProperties == properties)
    }

    // MARK: - Hashable

    // Validates that equal features have equal hashes and deduplicate in sets.
    @Test
    func hashableEqual() async throws {
        let featureA = try #require(Feature(jsonString: FeatureTests.featureJson))
        let featureB = try #require(Feature(jsonString: FeatureTests.featureJson))

        #expect(featureA == featureB)
        #expect(featureA.hashValue == featureB.hashValue)

        let set: Set<Feature> = [featureA, featureB]
        #expect(set.count == 1)
    }

    // Validates that features with different property VALUES are still equal
    // (property values are only compared by key) and hash equally. Deep value
    // comparison is tracked separately.
    @Test
    func hashablePropertyValuesNotCompared() async throws {
        var featureA = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        featureA.properties["count"] = 3
        var featureB = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        featureB.properties["count"] = 4

        #expect(featureA == featureB)
        #expect(featureA.hashValue == featureB.hashValue)
    }

    // Validates that features differing in geometry, id, or property keys
    // are not equal and hash differently.
    @Test
    func hashableNotEqual() async throws {
        let featureA = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        let featureB = Feature(Point(Coordinate3D(latitude: 47.4, longitude: 8.5)))

        #expect(featureA != featureB)
        #expect(featureA.hashValue != featureB.hashValue)

        var featureC = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        featureC.properties["count"] = 3

        #expect(featureA != featureC)
        #expect(featureA.hashValue != featureC.hashValue)

        var featureD = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        featureD.id = .int(5)

        #expect(featureA != featureD)
        #expect(featureA.hashValue != featureD.hashValue)
    }

    // Validates that features in different projections are not equal and
    // hash differently.
    @Test
    func hashableProjections() async throws {
        let feature4326 = Feature(Point(Coordinate3D(latitude: 47.3, longitude: 8.5)))
        let feature3857 = feature4326.projected(to: .epsg3857)

        #expect(feature4326 != feature3857)
        #expect(feature4326.hashValue != feature3857.hashValue)
    }

}

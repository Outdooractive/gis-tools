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

    @Test
    func loadJsonWithIntId() async throws {
        let feature = try #require(Feature(jsonString: FeatureTests.featureJsonWithIntId))

        #expect(feature.id == .int(1234))
        #expect(feature.projection == .epsg4326)
    }

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

    @Test
    func encodable() async throws {
        let feature = try #require(Feature(jsonString: FeatureTests.featureJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(feature) == feature.asJsonData(prettyPrinted: true))
    }

    @Test
    func decodable() async throws {
        let featureData = try #require(Feature(jsonString: FeatureTests.featureJson)?.asJsonData(prettyPrinted: true))
        let feature = try JSONDecoder().decode(Feature.self, from: featureData)

        #expect(feature.projection == .epsg4326)
        #expect(featureData == feature.asJsonData(prettyPrinted: true))
    }

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

}

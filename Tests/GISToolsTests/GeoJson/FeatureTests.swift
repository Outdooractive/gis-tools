@testable import GISTools
import XCTest

final class FeatureTests: XCTestCase {

    private let featureJson = """
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

    func testLoadJson() throws {
        let feature = try XCTUnwrap(Feature(jsonString: featureJson))

        XCTAssertEqual(feature.type, GeoJsonType.feature)
        XCTAssertEqual(feature.projection, .epsg4326)
        XCTAssertEqual(feature.geometry.type, GeoJsonType.polygon)
        XCTAssertEqual(feature.properties.count, 2)
        XCTAssertEqual(feature.properties.keys.sorted(), ["prop0", "prop1"])
        XCTAssertEqual(feature.property(for: "prop0"), "value0")
        XCTAssertEqual(feature["prop0"], "value0")
        XCTAssertEqual(feature.foreignMember(for: "other"), "something else")
        XCTAssertEqual(feature[foreignMember: "other"], "something else")
        XCTAssertEqual(feature.id, .string("abcd.1234"))
    }

    private let featureJsonWithIntId = """
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

    func testLoadJsonWithIntId() throws {
        let feature = try XCTUnwrap(Feature(jsonString: featureJsonWithIntId))

        XCTAssertEqual(feature.id, .int(1234))
        XCTAssertEqual(feature.projection, .epsg4326)
    }

    func testCreateJson() throws {
        let feature = Feature(Point(.zero), id: .int(5))
        XCTAssertEqual(feature.projection, .epsg4326)
        let json = feature.asJson
        XCTAssertEqual(json["type"] as? String, "Feature")
        XCTAssertEqual(json["id"] as? Int, 5)
        let geometry = json["geometry"] as! [String: Any]
        XCTAssertEqual(geometry["type"] as? String, "Point")
        XCTAssertEqual(geometry["coordinates"] as? [Double], [0.0, 0.0])
    }

    func testEncodable() throws {
        let feature = try XCTUnwrap(Feature(jsonString: featureJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(feature), feature.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        let featureData = try XCTUnwrap(Feature(jsonString: featureJson)?.asJsonData(prettyPrinted: true))
        let feature = try JSONDecoder().decode(Feature.self, from: featureData)

        XCTAssertEqual(feature.projection, .epsg4326)
        XCTAssertEqual(featureData, feature.asJsonData(prettyPrinted: true))
    }

    func testFeatureIds() throws {
        XCTAssertEqual(Feature.Identifier(value: 1234), .int(1234))
        XCTAssertEqual(Feature.Identifier(value: Int8(32)), .int(32))
        XCTAssertEqual(Feature.Identifier(value: Int8(32))?.int64Value, 32)
        XCTAssertEqual(Feature.Identifier(value: Int8(32))?.uint64Value, 32)

        XCTAssertEqual(Feature.Identifier(value: -1234), .int(-1234))
        XCTAssertEqual(Feature.Identifier(value: Int8(-32)), .int(-32))
        XCTAssertEqual(Feature.Identifier(value: Int8(-32))?.int64Value, -32)
        XCTAssertNil(Feature.Identifier(value: Int8(-32))?.uint64Value)

        // UInt -> Int
        XCTAssertEqual(Feature.Identifier(value: UInt64(32)), .int(32))

        XCTAssertEqual(Feature.Identifier(value: Int64.max), .int(9223372036854775807))
        XCTAssertEqual(Feature.Identifier(value: Int64.max)?.int64Value, 9223372036854775807)
        XCTAssertEqual(Feature.Identifier(value: Int64.min), .int(-9223372036854775808))
        XCTAssertEqual(Feature.Identifier(value: Int64.min)?.int64Value, -9223372036854775808)

        // 9223372036854775808 is Int64.max+1
        XCTAssertEqual(Feature.Identifier(value: UInt64(9223372036854775808)), .uint(9223372036854775808))
        XCTAssertNil(Feature.Identifier(value: UInt64(9223372036854775808))?.int64Value)
        XCTAssertEqual(Feature.Identifier(value: UInt64(9223372036854775808))?.uint64Value, 9223372036854775808)
    }

}

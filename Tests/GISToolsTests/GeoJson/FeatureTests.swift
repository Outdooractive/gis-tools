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
        guard let feature = Feature(jsonString: featureJson) else {
            throw "feature is nil"
        }
        XCTAssertEqual(feature.type, GeoJsonType.feature)
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
        guard let feature = Feature(jsonString: featureJsonWithIntId) else {
            throw "feature is nil"
        }

        XCTAssertEqual(feature.id, .int(1234))
    }


    func testCreateJson() throws {
        let feature = Feature(Point(.zero), id: .int(5))
        let json = feature.asJson
        XCTAssertEqual(json["type"] as? String, "Feature")
        XCTAssertEqual(json["id"] as? Int, 5)
        let geometry = json["geometry"] as! [String: Any]
        XCTAssertEqual(geometry["type"] as? String, "Point")
        XCTAssertEqual(geometry["coordinates"] as? [Double], [0.0, 0.0])
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testLoadJsonWithIntId", testLoadJsonWithIntId),
        ("testCreateJson", testCreateJson)
    ]

}

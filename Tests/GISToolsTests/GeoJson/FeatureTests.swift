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
       "other": "something else"
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
    }

    func testCreateJson() {
        // TODO:
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}

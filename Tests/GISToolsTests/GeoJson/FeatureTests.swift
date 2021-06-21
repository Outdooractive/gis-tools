#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

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
           }
        }
        """

    func testLoadJson() {
        let feature = Feature(jsonString: featureJson)
        XCTAssertNotNil(feature)
        XCTAssertEqual(feature?.type, GeoJsonType.feature)
        XCTAssertEqual(feature?.geometry.type, GeoJsonType.polygon)
        XCTAssertEqual(feature?.properties.count, 2)
        XCTAssertEqual(feature?.properties.keys.sorted(), ["prop0", "prop1"])
    }

    func testCreateJson() {
        // TODO
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}

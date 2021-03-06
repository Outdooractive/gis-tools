@testable import GISTools
import XCTest

final class FeatureCollectionTests: XCTestCase {

    private let featureCollectionJson = """
    {
        "type": "FeatureCollection",
        "features": [{
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [102.0, 0.5]
            },
            "properties": {
                "prop0": "value0"
            }
        }, {
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": [
                    [102.0, 0.0],
                    [103.0, 1.0],
                    [104.0, 0.0],
                    [105.0, 1.0]
                ]
            },
            "properties": {
                "prop0": "value0",
                "prop1": 0.0
            }
        }, {
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
        }],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        guard let featureCollection = FeatureCollection(jsonString: featureCollectionJson) else {
            throw "featureCollection is nil"
        }
        XCTAssertEqual(featureCollection.type, GeoJsonType.featureCollection)
        XCTAssertEqual(featureCollection.features.count, 3)
        XCTAssertEqual(featureCollection.features.allSatisfy({ $0.type == .feature }), true)
        XCTAssertEqual(featureCollection.foreignMember(for: "other"), "something else")
        XCTAssertEqual(featureCollection[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        // TODO:
    }

    func testMap() throws {
        guard var featureCollection = FeatureCollection(jsonString: featureCollectionJson) else {
            throw "featureCollection is nil"
        }
        let prop0: String? = featureCollection.features.first?.property(for: "prop0")

        XCTAssertEqual(prop0, "value0")

        featureCollection.mapFeatures({ feature -> Feature in
            var feature = feature
            feature.setProperty("value1", for: "prop0")
            return feature
        })

        let prop0Updated: String? = featureCollection.features.first?.property(for: "prop0")
        XCTAssertEqual(prop0Updated, "value1")
    }

    func testCompactMap() throws {
        guard var featureCollection = FeatureCollection(jsonString: featureCollectionJson) else {
            throw "featureCollection is nil"
        }
        XCTAssertEqual(featureCollection.features.count, 3)

        featureCollection.compactMapFeatures({ feature -> Feature? in
            guard feature.properties["prop1"] != nil else { return nil }
            return feature
        })

        XCTAssertEqual(featureCollection.features.count, 2)
    }

    func testFilter() throws {
        guard var featureCollection = FeatureCollection(jsonString: featureCollectionJson) else {
            throw "featureCollection is nil"
        }
        XCTAssertEqual(featureCollection.features.count, 3)

        featureCollection.filterFeatures({ feature -> Bool in
            feature.properties["prop1"] == nil
        })

        XCTAssertEqual(featureCollection.features.count, 1)
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
        ("testMap", testMap),
        ("testCompactMap", testCompactMap),
        ("testFilter", testFilter),
    ]

}

@testable import GISTools
import XCTest

final class FeatureCollectionTests: XCTestCase {

    static let featureCollectionJson = """
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
        let featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        XCTAssertEqual(featureCollection.type, GeoJsonType.featureCollection)
        XCTAssertEqual(featureCollection.projection, .epsg4326)
        XCTAssertEqual(featureCollection.features.count, 3)
        XCTAssertEqual(featureCollection.features.allSatisfy({ $0.type == .feature }), true)
        XCTAssertEqual(featureCollection.foreignMember(for: "other"), "something else")
        XCTAssertEqual(featureCollection[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        // TODO:
    }

    func testAddFeatures() {
        let feature4326 = Feature(Point(.zero))
        let feature3857 = Feature(Point(Coordinate3D(x: 0.0, y: 0.0)))

        var featureCollection = FeatureCollection()
        XCTAssertEqual(featureCollection.projection, .noSRID)

        featureCollection.appendFeature(feature4326)
        XCTAssertEqual(featureCollection.projection, .epsg4326)

        XCTAssertEqual(featureCollection.features.count, 1)
        featureCollection.appendFeature(feature3857)
        XCTAssertEqual(featureCollection.features.count, 1)
        featureCollection.insertFeature(feature3857, atIndex: 0)
        XCTAssertEqual(featureCollection.features.count, 1)

        featureCollection.removeFeature(at: 0)
        XCTAssertTrue(featureCollection.features.isEmpty)

        featureCollection.appendFeature(feature3857)
        XCTAssertEqual(featureCollection.features.count, 1)
    }

    func testMap() throws {
        var featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

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
        var featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        XCTAssertEqual(featureCollection.features.count, 3)

        featureCollection.compactMapFeatures({ feature -> Feature? in
            guard feature.properties["prop1"] != nil else { return nil }
            return feature
        })

        XCTAssertEqual(featureCollection.features.count, 2)
    }

    func testFilter() throws {
        var featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        XCTAssertEqual(featureCollection.features.count, 3)

        featureCollection.filterFeatures({ feature -> Bool in
            feature.properties["prop1"] == nil
        })

        XCTAssertEqual(featureCollection.features.count, 1)
    }

    func testEnumerate() throws {
        let featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let expected: [(Int, Int, Coordinate3D)] = [
            (0, 0, Coordinate3D(latitude: 0.5, longitude: 102.0)),
            (1, 0, Coordinate3D(latitude: 0.0, longitude: 102.0)),
            (1, 1, Coordinate3D(latitude: 1.0, longitude: 103.0)),
            (1, 2, Coordinate3D(latitude: 0.0, longitude: 104.0)),
            (1, 3, Coordinate3D(latitude: 1.0, longitude: 105.0)),
            (2, 0, Coordinate3D(latitude: 0.0, longitude: 100.0)),
            (2, 1, Coordinate3D(latitude: 0.0, longitude: 101.0)),
            (2, 2, Coordinate3D(latitude: 1.0, longitude: 101.0)),
            (2, 3, Coordinate3D(latitude: 1.0, longitude: 100.0)),
            (2, 4, Coordinate3D(latitude: 0.0, longitude: 100.0))
        ]

        var result: [(Int, Int, Coordinate3D)] = []
        featureCollection.enumerateCoordinates { featureIndex, coordinateIndex, coordinate in
            result.append((featureIndex, coordinateIndex, coordinate))
        }

        XCTAssertEqual(result.count, expected.count)

        for (lhs, rhs) in zip(result, expected) {
            XCTAssertEqual(lhs.0, rhs.0)
            XCTAssertEqual(lhs.1, rhs.1)
            XCTAssertEqual(lhs.2, rhs.2)
        }
    }

    func testEnumerateProperties() throws {
        let featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let expected: [(Int, [String: Sendable])] = [
            (0, ["prop0": "value0"]),
            (1, ["prop0": "value0", "prop1": 0]),
            (2, ["prop0": "value0", "prop1": ["this": "that"]])
        ]

        var result: [(Int, [String: Sendable])] = []
        featureCollection.enumerateProperties { featureIndex, properties in
            XCTAssertFalse(properties.isEmpty)
            result.append((featureIndex, properties))
        }

        XCTAssertEqual(result.count, expected.count)

        for (lhs, rhs) in zip(result, expected) {
            XCTAssertEqual(lhs.0, rhs.0)
        }
    }

    func testPropertiesSummary() throws {
        let featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let summary = featureCollection.propertiesSummary()
        XCTAssertEqual(summary.count, 2)
        XCTAssertEqual(summary.keys.sorted(), ["prop0", "prop1"])
        XCTAssertEqual(summary["prop0"], ["value0"])
        XCTAssertTrue(summary["prop1"]!.contains(0))
        XCTAssertTrue(summary["prop1"]!.contains(["this": "that"]))
    }

    func testEncodable() throws {
        let featureCollection = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try encoder.encode(featureCollection), featureCollection.asJsonData(prettyPrinted: true))
    }

    func testDecodable() throws {
        let featureCollectionData = try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson)?.asJsonData(prettyPrinted: true))
        let featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: featureCollectionData)

        XCTAssertEqual(featureCollection.projection, .epsg4326)
        XCTAssertEqual(featureCollectionData, featureCollection.asJsonData(prettyPrinted: true))
    }

    func testDecodePoint() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let pointData = try XCTUnwrap(point.asJsonData(prettyPrinted: true))
        let featureCollectionData = try XCTUnwrap(FeatureCollection([point]).asJsonData(prettyPrinted: true))

        let featureCollection1 = try XCTUnwrap(FeatureCollection(jsonData: pointData))
        let featureCollection2 = try JSONDecoder().decode(FeatureCollection.self, from: pointData)

        XCTAssertEqual(featureCollection1.projection, .epsg4326)
        XCTAssertEqual(featureCollection2.projection, .epsg4326)

        XCTAssertEqual(featureCollectionData, featureCollection1.asJsonData(prettyPrinted: true))
        XCTAssertEqual(featureCollectionData, featureCollection2.asJsonData(prettyPrinted: true))
    }

}

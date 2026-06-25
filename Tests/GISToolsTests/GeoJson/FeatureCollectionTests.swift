import Foundation
@testable import GISTools
import Testing

struct FeatureCollectionTests {

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
                "prop0": "value0",
                "prop2": "a"
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
                "prop1": 0.0,
                "prop2": "a"
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
                },
                "prop2": "b"
            }
        }],
        "other": "something else"
    }
    """

    // Validates loading a FeatureCollection from a JSON string produces correct properties.
    @Test
    func loadJson() async throws {
        let featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        #expect(featureCollection.type == GeoJsonType.featureCollection)
        #expect(featureCollection.projection == .epsg4326)
        #expect(featureCollection.features.count == 3)
        #expect(featureCollection.features.allSatisfy({ $0.type == .feature }))
        #expect(featureCollection.foreignMember(for: "other") == "something else")
        #expect(featureCollection[foreignMember: "other"] == "something else")
    }

    // Validates creating a FeatureCollection from features and generating its JSON representation.
    @Test
    func createJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.5, longitude: 102.0))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 102.0),
            Coordinate3D(latitude: 1.0, longitude: 103.0),
            Coordinate3D(latitude: 0.0, longitude: 104.0),
            Coordinate3D(latitude: 1.0, longitude: 105.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0),
        ]]))

        let feature0 = Feature(point, properties: ["prop0": "value0", "prop2": "a"])
        let feature1 = Feature(lineString, properties: ["prop0": "value0", "prop1": 0.0, "prop2": "a"])
        let feature2 = Feature(polygon, properties: ["prop0": "value0", "prop1": ["this": "that"], "prop2": "b"])

        let featureCollection = FeatureCollection([feature0, feature1, feature2])
        let string = try #require(featureCollection.asJsonString())

        #expect(featureCollection.projection == .epsg4326)
        #expect(string.contains("\"type\":\"FeatureCollection\""))
        #expect(string.contains("\"type\":\"Feature\""))
        #expect(string.contains("\"type\":\"Point\""))
        #expect(string.contains("\"type\":\"LineString\""))
        #expect(string.contains("\"type\":\"Polygon\""))
        #expect(string.contains("\"prop0\":\"value0\""))
        #expect(string.contains("\"prop2\":\"a\""))
        #expect(string.contains("\"prop2\":\"b\""))
    }

    // Validates adding features with mismatched projections filters them by projection.
    @Test
    func addFeatures() async throws {
        let feature4326 = Feature(Point(.zero))
        let feature3857 = Feature(Point(Coordinate3D(x: 0.0, y: 0.0)))

        var featureCollection = FeatureCollection()
        #expect(featureCollection.projection == .noSRID)

        featureCollection.appendFeature(feature4326)
        #expect(featureCollection.projection == .epsg4326)

        #expect(featureCollection.features.count == 1)
        featureCollection.appendFeature(feature3857)
        #expect(featureCollection.features.count == 1)
        featureCollection.insertFeature(feature3857, atIndex: 0)
        #expect(featureCollection.features.count == 1)

        featureCollection.removeFeature(at: 0)
        #expect(featureCollection.features.isEmpty)

        featureCollection.appendFeature(feature3857)
        #expect(featureCollection.features.count == 1)
    }

    // Validates mapping over features updates their properties in place.
    @Test
    func mapFeatures() async throws {
        var featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let prop0: String? = featureCollection.features.first?.property(for: "prop0")
        #expect(prop0 == "value0")

        featureCollection.mapFeatures({ feature -> Feature in
            var feature = feature
            feature.setProperty("value1", for: "prop0")
            return feature
        })

        let prop0Updated: String? = featureCollection.features.first?.property(for: "prop0")
        #expect(prop0Updated == "value1")
    }

    // Validates compact-mapping removes features whose transform returns nil.
    @Test
    func compactMapFeatures() async throws {
        var featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        #expect(featureCollection.features.count == 3)

        featureCollection.compactMapFeatures({ feature -> Feature? in
            guard feature.properties["prop1"] != nil else { return nil }
            return feature
        })

        #expect(featureCollection.features.count == 2)
    }

    // Validates filtering removes features not matching the predicate.
    @Test
    func filterFeatures() async throws {
        var featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        #expect(featureCollection.features.count == 3)

        featureCollection.filterFeatures({ feature -> Bool in
            feature.properties["prop1"] == nil
        })

        #expect(featureCollection.features.count == 1)
    }

    // Validates dividing features by a property key produces correctly grouped dictionaries.
    @Test
    func divideFeaturesByKey() async throws {
        let featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))
        let divided: [String: [Feature]] = featureCollection.divideFeatures { feature in
            feature.property(for: "prop2")
        }

        #expect(divided.keys.sorted() == ["a", "b"])

        let featuresA = try #require(divided["a"])
        #expect(featuresA.count == 2)
        #expect(featuresA.allSatisfy({ $0.property(for: "prop2") == "a" }))

        let featuresB = try #require(divided["b"])
        #expect(featuresB.count == 1)
        #expect(featuresB.allSatisfy({ $0.property(for: "prop2") == "b" }))
    }

    // Validates enumerating all coordinates across features in correct order.
    @Test
    func enumerateFeatures() async throws {
        let featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

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
            (2, 4, Coordinate3D(latitude: 0.0, longitude: 100.0)),
        ]

        var result: [(Int, Int, Coordinate3D)] = []
        featureCollection.enumerateCoordinates { featureIndex, coordinateIndex, coordinate in
            result.append((featureIndex, coordinateIndex, coordinate))
        }

        #expect(result.count == expected.count)

        for (lhs, rhs) in zip(result, expected) {
            #expect(lhs.0 == rhs.0)
            #expect(lhs.1 == rhs.1)
            #expect(lhs.2 == rhs.2)
        }
    }

    // Validates enumerating properties across features.
    @Test
    func enumerateProperties() async throws {
        let featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let expected: [(Int, [String: Sendable])] = [
            (0, ["prop0": "value0"]),
            (1, ["prop0": "value0", "prop1": 0]),
            (2, ["prop0": "value0", "prop1": ["this": "that"]])
        ]

        var result: [(Int, [String: Sendable])] = []
        featureCollection.enumerateProperties { featureIndex, properties in
            #expect(properties.isEmpty == false)
            result.append((featureIndex, properties))
        }

        #expect(result.count == expected.count)

        for (lhs, rhs) in zip(result, expected) {
            #expect(lhs.0 == rhs.0)
        }
    }

    // Validates the properties summary returns all unique property keys and values.
    @Test
    func propertiesSummary() async throws {
        let featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let summary = featureCollection.propertiesSummary()
        #expect(summary.count == 3)
        #expect(summary.keys.sorted() == ["prop0", "prop1", "prop2"])
        #expect(summary["prop0"] == ["value0"])
        #expect(summary["prop1"]!.contains(0))
        #expect(summary["prop1"]!.contains(["this": "that"]))
    }

    // Validates JSON encoding matches the output of asJsonData.
    @Test
    func encodable() async throws {
        let featureCollection = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(featureCollection) == featureCollection.asJsonData(prettyPrinted: true))
    }

    // Validates round-trip JSON encoding and decoding preserves the feature collection.
    @Test
    func decodable() async throws {
        let featureCollectionData = try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson)?.asJsonData(prettyPrinted: true))
        let featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: featureCollectionData)

        #expect(featureCollection.projection == .epsg4326)
        #expect(featureCollectionData == featureCollection.asJsonData(prettyPrinted: true))
    }

    // Validates decoding a single point geometry wraps it in a FeatureCollection.
    @Test
    func decodePoint() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let pointData = try #require(point.asJsonData(prettyPrinted: true))
        let featureCollectionData = try #require(FeatureCollection([point]).asJsonData(prettyPrinted: true))

        let featureCollection1 = try #require(FeatureCollection(jsonData: pointData))
        let featureCollection2 = try JSONDecoder().decode(FeatureCollection.self, from: pointData)

        #expect(featureCollection1.projection == .epsg4326)
        #expect(featureCollection2.projection == .epsg4326)

        #expect(featureCollectionData == featureCollection1.asJsonData(prettyPrinted: true))
        #expect(featureCollectionData == featureCollection2.asJsonData(prettyPrinted: true))
    }

    // MARK: - Projection

    // Validates projecting a FeatureCollection from EPSG:4326 to EPSG:3857.
    @Test
    func projected() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let feature = Feature(point)
        let featureCollection = FeatureCollection([feature])

        let projected = featureCollection.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.features.count == 1)
        #expect(projected.features[0].projection == .epsg3857)
    }

    // Validates projecting a FeatureCollection to EPSG:4978.
    @Test
    func projectedTo4978() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let feature = Feature(point)
        let featureCollection = FeatureCollection([feature])

        let projected = featureCollection.projected(to: .epsg4978)

        #expect(projected.projection == .epsg4978)
        for feature in projected.features {
            #expect(feature.projection == .epsg4978)
        }
    }

    // Validates projecting a FeatureCollection to noSRID.
    @Test
    func projectedToNoSRID() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let feature = Feature(point)
        let featureCollection = FeatureCollection([feature])

        let projected = featureCollection.projected(to: .noSRID)

        #expect(projected.projection == .noSRID)
        for feature in projected.features {
            #expect(feature.projection == .noSRID)
        }
    }

    // Validates projecting a FeatureCollection with mixed geometry types.
    @Test
    func projectedMixedGeometries() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let featureCollection = FeatureCollection([
            Feature(point),
            Feature(lineString),
            Feature(polygon),
        ])

        let projected = featureCollection.projected(to: .epsg3857)

        #expect(projected.projection == .epsg3857)
        #expect(projected.features.count == 3)
        for feature in projected.features {
            #expect(feature.projection == .epsg3857)
        }
    }

    // MARK: - Bounding box

    // Validates the bounding box of a FeatureCollection in EPSG:4326.
    @Test
    func boundingBox() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]]))

        let featureCollection = FeatureCollection(
            [Feature(point), Feature(lineString), Feature(polygon)],
            calculateBoundingBox: true)

        let bbox = try #require(featureCollection.boundingBox)
        #expect(bbox.southWest.latitude == 0.0)
        #expect(bbox.southWest.longitude == 0.0)
        #expect(bbox.northEast.latitude == 10.0)
        #expect(bbox.northEast.longitude == 10.0)
    }

    // Validates calculateBoundingBox from features.
    @Test
    func calculateBoundingBox() async throws {
        let point = Point(Coordinate3D(latitude: -5.0, longitude: -5.0))
        let anotherPoint = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let featureCollection = FeatureCollection([Feature(point), Feature(anotherPoint)])

        let bbox = try #require(featureCollection.calculateBoundingBox())
        #expect(bbox.southWest.latitude == -5.0)
        #expect(bbox.southWest.longitude == -5.0)
        #expect(bbox.northEast.latitude == 5.0)
        #expect(bbox.northEast.longitude == 5.0)
    }

    // Validates intersects with a bounding box.
    @Test
    func intersectsBoundingBox() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let featureCollection = FeatureCollection([Feature(point)])

        let overlapping = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(featureCollection.intersects(overlapping))

        let farAway = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))
        #expect(!featureCollection.intersects(farAway))
    }

}

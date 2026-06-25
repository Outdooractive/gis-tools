@testable import GISTools
import Testing

struct EnumeratePropertiesTests {

    // Tests property enumeration over a FeatureCollection.
    @Test func enumerateProperties() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let feature1 = Feature(point, properties: ["name": "Alpha", "value": 1])
        let feature2 = Feature(point, properties: ["name": "Beta", "value": 2])
        let feature3 = Feature(point, properties: [:])
        let collection = FeatureCollection([feature1, feature2, feature3])

        var visited: [(Int, [String: Sendable])] = []
        collection.enumerateProperties { index, properties in
            visited.append((index, properties))
        }

        #expect(visited.count == 3)
        #expect(visited[0].0 == 0)
        #expect(visited[0].1["name"] as? String == "Alpha")
        #expect(visited[1].0 == 1)
        #expect(visited[1].1["value"] as? Int == 2)
        #expect(visited[2].0 == 2)
        #expect(visited[2].1.isEmpty)
    }

    // Tests property summary aggregation across features.
    @Test func propertiesSummary() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let feature1 = Feature(point, properties: ["name": "Alpha", "category": "A"])
        let feature2 = Feature(point, properties: ["name": "Beta", "category": "B"])
        let feature3 = Feature(point, properties: ["category": "A", "extra": true])
        let collection = FeatureCollection([feature1, feature2, feature3])

        let summary = collection.propertiesSummary()
        #expect(summary["name"]?.count == 2)
        #expect(summary["name"]?.contains("Alpha") == true)
        #expect(summary["name"]?.contains("Beta") == true)
        #expect(summary["category"]?.count == 2)
        #expect(summary["category"]?.contains("A") == true)
        #expect(summary["category"]?.contains("B") == true)
        #expect(summary["extra"]?.count == 1)
        #expect(summary["extra"]?.contains(true) == true)
    }

    // MARK: - Projections

    // Tests property enumeration in EPSG:3857.
    @Test func enumerateProperties3857() async throws {
        let point = Point(Coordinate3D(x: 100_000.0, y: 200_000.0))
        let feature1 = Feature(point, properties: ["name": "Alpha", "value": 1])
        let feature2 = Feature(point, properties: ["name": "Beta", "value": 2])
        let collection = FeatureCollection([feature1, feature2])

        var visited: [(Int, [String: Sendable])] = []
        collection.enumerateProperties { index, properties in
            visited.append((index, properties))
        }

        #expect(visited.count == 2)
        #expect(visited[0].1["name"] as? String == "Alpha")
        #expect(visited[1].1["name"] as? String == "Beta")
    }

    // Tests property enumeration in EPSG:4978.
    @Test func enumerateProperties4978() async throws {
        let point = Point(Coordinate3D(
            latitude: 1.0, longitude: 2.0).projected(to: .epsg4978))
        let feature = Feature(point, properties: ["key": "ECEF"])
        let collection = FeatureCollection([feature])

        var visited: [(Int, [String: Sendable])] = []
        collection.enumerateProperties { index, properties in
            visited.append((index, properties))
        }

        #expect(visited.count == 1)
        #expect(visited[0].1["key"] as? String == "ECEF")
    }

    // Tests property enumeration with noSRID projection.
    @Test func enumeratePropertiesNoSRID() async throws {
        let point = Point(Coordinate3D(
            x: 100.0, y: 200.0, projection: .noSRID))
        let feature1 = Feature(point, properties: ["a": 1])
        let feature2 = Feature(point, properties: ["b": 2])
        let collection = FeatureCollection([feature1, feature2])

        var keys: [String] = []
        collection.enumerateProperties { _, properties in
            keys.append(contentsOf: properties.keys)
        }

        #expect(keys.contains("a"))
        #expect(keys.contains("b"))
    }

}

@testable import GISTools
import Testing

struct EnumeratePropertiesTests {

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

}

@testable import GISTools
import Testing

struct DissolveTests {

    // MARK: - Helpers

    private func square(
        latitude: Double,
        longitude: Double,
        size: Double = 1.0
    ) -> Polygon {
        let half = size * 0.5
        let coords = [
            Coordinate3D(latitude: latitude - half, longitude: longitude - half),
            Coordinate3D(latitude: latitude + half, longitude: longitude - half),
            Coordinate3D(latitude: latitude + half, longitude: longitude + half),
            Coordinate3D(latitude: latitude - half, longitude: longitude + half),
            Coordinate3D(latitude: latitude - half, longitude: longitude - half),
        ]
        return try! #require(Polygon([coords]))
    }

    // MARK: - String property values

    @Test
    func stringProperty() async throws {
        let a1 = Feature(square(latitude: 0.0, longitude: 0.0), properties: ["group": "a"])
        let a2 = Feature(square(latitude: 0.0, longitude: 10.0), properties: ["group": "a"])
        let b1 = Feature(square(latitude: 10.0, longitude: 0.0), properties: ["group": "b"])
        let line = Feature(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ])!, properties: ["group": "a"])

        let dissolved = FeatureCollection([a1, a2, b1, line]).dissolved(by: "group")

        #expect(dissolved.features.count == 2)
        let groups = dissolved.features.compactMap({ $0.properties["group"] as? String }).sorted()
        #expect(groups == ["a", "b"])
    }

    // MARK: - Int property values

    @Test
    func intProperty() async throws {
        let f1 = Feature(square(latitude: 0.0, longitude: 0.0), properties: ["zone": 1])
        let f2 = Feature(square(latitude: 0.0, longitude: 10.0), properties: ["zone": 1])
        let f3 = Feature(square(latitude: 10.0, longitude: 0.0), properties: ["zone": 2])

        let dissolved = FeatureCollection([f1, f2, f3]).dissolved(by: "zone")

        #expect(dissolved.features.count == 2)
        let groups = dissolved.features.compactMap({ $0.properties["zone"] as? Int }).sorted()
        #expect(groups == [1, 2])
    }

    // MARK: - Bool property values

    @Test
    func boolProperty() async throws {
        let f1 = Feature(square(latitude: 0.0, longitude: 0.0), properties: ["active": true])
        let f2 = Feature(square(latitude: 0.0, longitude: 10.0), properties: ["active": true])
        let f3 = Feature(square(latitude: 10.0, longitude: 0.0), properties: ["active": false])

        let dissolved = FeatureCollection([f1, f2, f3]).dissolved(by: "active")

        #expect(dissolved.features.count == 2)
        let groups = dissolved.features.compactMap({ $0.properties["active"] as? Bool })
        #expect(groups.count == 2)
        #expect(groups.contains(true))
        #expect(groups.contains(false))
    }

    // MARK: - removeUnknown

    @Test
    func removeUnknownDropsFeaturesWithoutProperty() async throws {
        let withProp = Feature(square(latitude: 0.0, longitude: 0.0), properties: ["cat": "x"])
        let withoutProp = Feature(square(latitude: 10.0, longitude: 0.0))

        let dissolved = FeatureCollection([withProp, withoutProp]).dissolved(by: "cat", removeUnknown: true)

        #expect(dissolved.features.count == 1)
        #expect(dissolved.features.first?.properties["cat"] as? String == "x")
    }

    @Test
    func keepUnknownGroupsFeaturesWithoutProperty() async throws {
        let withProp = Feature(square(latitude: 0.0, longitude: 0.0), properties: ["cat": "x"])
        let withoutProp = Feature(square(latitude: 10.0, longitude: 0.0))

        let dissolved = FeatureCollection([withProp, withoutProp]).dissolved(by: "cat", removeUnknown: false)

        #expect(dissolved.features.count == 2)
        let withCat = dissolved.features.first(where: { $0.properties["cat"] != nil })
        #expect(withCat?.properties["cat"] as? String == "x")
        let withoutCat = dissolved.features.first(where: { $0.properties["cat"] == nil })
        #expect(withoutCat != nil)
    }

    // MARK: - Non-polygon features are filtered out

    @Test
    func nonPolygonFeaturesRemoved() async throws {
        let polygon = Feature(square(latitude: 0.0, longitude: 0.0), properties: ["g": "a"])
        let point = Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0)), properties: ["g": "a"])

        let dissolved = FeatureCollection([polygon, point]).dissolved(by: "g")

        #expect(dissolved.features.count == 1)
        let g = try #require(dissolved.features.first?.properties["g"] as? String)
        #expect(g == "a")
    }

    // MARK: - EPSG:3857

    @Test
    func dissolve3857() async throws {
        let p1 = Feature(Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]), properties: ["group": "a"])
        let p2 = Feature(Polygon(unchecked: [[
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 2000.0, y: 0.0),
            Coordinate3D(x: 2000.0, y: 1000.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 1000.0, y: 0.0),
        ]]), properties: ["group": "a"])

        let dissolved = FeatureCollection([p1, p2]).dissolved(by: "group")
        #expect(dissolved.features.isNotEmpty)
    }

    @Test
    func dissolveNoSRID() async throws {
        let p1 = Feature(Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]), properties: ["group": "a"])
        let p2 = Feature(Polygon(unchecked: [[
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 2000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 2000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
        ]]), properties: ["group": "a"])

        let dissolved = FeatureCollection([p1, p2]).dissolved(by: "group")
        #expect(dissolved.features.isNotEmpty)
    }

    @Test
    func dissolve4978() async throws {
        let a4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let b4326 = try #require(Polygon([[
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]]))
        let p1 = Feature(a4326.projected(to: .epsg4978), properties: ["group": "a"])
        let p2 = Feature(b4326.projected(to: .epsg4978), properties: ["group": "a"])

        let dissolved = FeatureCollection([p1, p2]).dissolved(by: "group")
        #expect(dissolved.features.isNotEmpty)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 175.0),
        ]]))
        let fc = FeatureCollection([Feature(polygon)])
        let dissolved = fc.dissolved(by: "group")
        #expect(dissolved.features.isNotEmpty)
    }

}

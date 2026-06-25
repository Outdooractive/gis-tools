@testable import GISTools
import Testing

struct FlattenTests {

    @Test
    func featureCollection() async throws {
        let original = try TestData.featureCollection(package: "Flatten", name: "FeatureCollection")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "FeatureCollectionResult")

        #expect(flattened == expected)
    }

    @Test
    func geometryCollection() async throws {
        let original = try TestData.geometryCollection(package: "Flatten", name: "GeometryCollection")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "GeometryCollectionResult")

        #expect(flattened == expected)
    }

    @Test
    func geometryObject() async throws {
        let original = try TestData.multiPolygon(package: "Flatten", name: "GeometryObject")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "GeometryObjectResult")

        #expect(flattened == expected)
    }

    @Test
    func multiLineString() async throws {
        let original = try TestData.feature(package: "Flatten", name: "MultiLineString")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "MultiLineStringResult")

        #expect(flattened == expected)
    }

    @Test
    func multiPoint() async throws {
        let original = try TestData.feature(package: "Flatten", name: "MultiPoint")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "MultiPointResult")

        #expect(flattened == expected)
    }

    @Test
    func polygon() async throws {
        let original = try TestData.feature(package: "Flatten", name: "Polygon")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "PolygonResult")

        #expect(flattened == expected)
    }

    // MARK: - Projections

    @Test
    func flatten3857() async throws {
        let a = Coordinate3D(x: 0.0, y: 0.0)
        let b = Coordinate3D(x: 100_000.0, y: 100_000.0)
        let line = try #require(LineString([a, b]))
        let point = Point(Coordinate3D(x: 100_000.0, y: 100_000.0))
        let collection = GeometryCollection([line, point])

        let flattened = try #require(collection.flattened)
        #expect(flattened.features.count == 2)
    }

    @Test
    func flattenNoSRID() async throws {
        let a = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let b = Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .noSRID)
        let line = try #require(LineString([a, b]))
        let point = Point(Coordinate3D(x: 50_000.0, y: 50_000.0, projection: .noSRID))
        let collection = GeometryCollection([line, point])

        let flattened = try #require(collection.flattened)
        #expect(flattened.features.count == 2)
    }

    // MARK: - Edge cases

    @Test
    func flattenEmpty() async throws {
        let empty = FeatureCollection([Feature].init())
        let result = empty.flattened
        #expect(result != nil)
        #expect(result?.features.isEmpty == true)
    }

}

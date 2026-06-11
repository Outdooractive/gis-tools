@testable import GISTools
import Testing

struct FlattenTests {

    // Validates flattening a nested FeatureCollection produces the expected flat result.
    @Test
    func featureCollection() async throws {
        let original = try TestData.featureCollection(package: "Flatten", name: "FeatureCollection")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "FeatureCollectionResult")

        #expect(flattened == expected)
    }

    // Validates flattening a nested GeometryCollection produces the expected flat result.
    @Test
    func geometryCollection() async throws {
        let original = try TestData.geometryCollection(package: "Flatten", name: "GeometryCollection")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "GeometryCollectionResult")

        #expect(flattened == expected)
    }

    // Validates flattening a MultiPolygon geometry object produces the expected flat result.
    @Test
    func geometryObject() async throws {
        let original = try TestData.multiPolygon(package: "Flatten", name: "GeometryObject")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "GeometryObjectResult")

        #expect(flattened == expected)
    }

    // Validates flattening a Feature containing a MultiLineString produces the expected flat result.
    @Test
    func multiLineString() async throws {
        let original = try TestData.feature(package: "Flatten", name: "MultiLineString")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "MultiLineStringResult")

        #expect(flattened == expected)
    }

    // Validates flattening a Feature containing a MultiPoint produces the expected flat result.
    @Test
    func multiPoint() async throws {
        let original = try TestData.feature(package: "Flatten", name: "MultiPoint")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "MultiPointResult")

        #expect(flattened == expected)
    }

    // Validates flattening a Feature containing a Polygon produces the expected flat result.
    @Test
    func polygon() async throws {
        let original = try TestData.feature(package: "Flatten", name: "Polygon")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "PolygonResult")

        #expect(flattened == expected)
    }

}

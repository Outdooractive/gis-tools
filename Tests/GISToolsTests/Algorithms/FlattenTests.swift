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

}

@testable import GISTools
import Testing

struct FlattenTests {

    // Tests flattening a FeatureCollection to individual features.
    @Test
    func featureCollection() async throws {
        let original = try TestData.featureCollection(package: "Flatten", name: "FeatureCollection")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "FeatureCollectionResult")

        #expect(flattened == expected)
    }

    // Tests flattening a GeometryCollection to a FeatureCollection.
    @Test
    func geometryCollection() async throws {
        let original = try TestData.geometryCollection(package: "Flatten", name: "GeometryCollection")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "GeometryCollectionResult")

        #expect(flattened == expected)
    }

    // Tests flattening a single geometry object.
    @Test
    func geometryObject() async throws {
        let original = try TestData.multiPolygon(package: "Flatten", name: "GeometryObject")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "GeometryObjectResult")

        #expect(flattened == expected)
    }

    // Tests flattening a MultiLineString feature.
    @Test
    func multiLineString() async throws {
        let original = try TestData.feature(package: "Flatten", name: "MultiLineString")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "MultiLineStringResult")

        #expect(flattened == expected)
    }

    // Tests flattening a MultiPoint feature.
    @Test
    func multiPoint() async throws {
        let original = try TestData.feature(package: "Flatten", name: "MultiPoint")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "MultiPointResult")

        #expect(flattened == expected)
    }

    // Tests flattening a Polygon feature.
    @Test
    func polygon() async throws {
        let original = try TestData.feature(package: "Flatten", name: "Polygon")
        let flattened = try #require(original.flattened)
        let expected = try TestData.featureCollection(package: "Flatten", name: "PolygonResult")

        #expect(flattened == expected)
    }

    // MARK: - Projections

    // Tests flattening in EPSG:3857.
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

    // Tests flattening with noSRID projection.
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

    // Tests flattening an empty FeatureCollection.
    @Test
    func flattenEmpty() async throws {
        let empty = FeatureCollection([Feature].init())
        let result = empty.flattened
        #expect(result != nil)
        #expect(result?.features.isEmpty == true)
    }

}

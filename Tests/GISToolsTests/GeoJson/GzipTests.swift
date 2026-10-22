import Foundation
@testable import GISTools
import Testing

/// Transparent gzip support for GeoJSON data and file entry points.
struct GzipTests {

    private static let plainData = Data("""
    {"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"gzip"},"geometry":{"type":"Point","coordinates":[10.0,47.0]}}]}
    """.utf8)

    private static let gzippedData = Data(base64Encoded: """
    H4sIAAAAAAAC/13MsQqDQBAE0H+Z+pALBAK2AWt7sTh0Iwt6e6ybwhz37/GSVGnnzUyGHYnQoqNgT6W7rCtNxhLh8PhmO9oh//VOTSqJ1Lh6Rgxb5eXFCcVhIdnI9Kj0W/bC0c7dJKIzx2Cf44tvvLveGj+WMpY3f8TkHY8AAAA=
    """.trimmingCharacters(in: .whitespacesAndNewlines))!

    @Test
    func detectsGzipMagic() {
        #expect(Gzip.isGzipped(Self.gzippedData))
        #expect(!Gzip.isGzipped(Self.plainData))
        #expect(!Gzip.isGzipped(Data()))
    }

    @Test
    func passesPlainDataThrough() {
        #expect(Gzip.decompressIfNeeded(Self.plainData) == Self.plainData)
    }

    @Test
    func decompressesGzipData() {
        #expect(Gzip.decompress(Self.gzippedData) == Self.plainData)
    }

    @Test
    func rejectsTruncatedGzipData() {
        #expect(Gzip.decompress(Data([0x1F, 0x8B])) == nil)
    }

    @Test
    func featureCollectionFromGzippedData() throws {
        let collection = try #require(FeatureCollection(jsonData: Self.gzippedData))

        #expect(collection.features.count == 1)
        #expect(collection.features.first?.property(for: "name") as String? == "gzip")
    }

    @Test
    func geoJsonReaderFromGzippedData() throws {
        let object = try #require(GeoJsonReader.geoJsonFrom(jsonData: Self.gzippedData))
        let collection = try #require(object as? FeatureCollection)

        #expect(collection.features.count == 1)
    }

    @Test
    func geoJsonParserFromGzippedData() throws {
        let result = try GeoJsonParser.parse(jsonData: Self.gzippedData)
        let collection = try #require(result.object as? FeatureCollection)

        #expect(result.issues.isEmpty)
        #expect(collection.features.count == 1)
    }

    @Test
    func featureCollectionFromGzippedFile() throws {
        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("gistools-gzip-test.geojson.gz")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try Self.gzippedData.write(to: url)

        let collection = try #require(FeatureCollection(contentsOf: url))
        #expect(collection.features.count == 1)
    }

    @Test
    func invalidGzipDoesNotFallBackToCompressedJSON() {
        #expect(FeatureCollection(jsonData: Data([0x1F, 0x8B])) == nil)
    }

}

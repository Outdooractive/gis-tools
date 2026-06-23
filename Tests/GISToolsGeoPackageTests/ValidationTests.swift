import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

struct GeoPackageValidationTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        let cleanName = name.hasSuffix("()") ? String(name.dropLast(2)) : name
        return tmpDir.appendingPathComponent("gpkg_\(cleanName).gpkg")
    }

    @Test
    func validFeaturePackage() async throws {
        let url = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let result = try GeoPackage.validate(url: url)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors.map(\.message)), warnings=\(result.warnings.map(\.message))")
    }

    @Test
    func validTilePackage() async throws {
        let url = testFixture("rivers.gpkg")
        let result = try GeoPackage.validate(url: url)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors.map(\.message)), warnings=\(result.warnings.map(\.message))")
    }

    @Test
    func validFreshlyCreated() async throws {
        let url = testUrl()
        try? FileManager.default.removeItem(at: url)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        ]).writeGeopackage(to: url)

        let result = try GeoPackage.validate(url: url)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors.map(\.message)), warnings=\(result.warnings.map(\.message))")
    }

    @Test
    func validFreshlyCreatedTiles() async throws {
        let url = testUrl()
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.createMetadata(in: db)

        let bounds = BoundingBox(
            southWest: Coordinate3D(latitude: -85.0, longitude: -180.0),
            northEast: Coordinate3D(latitude: 85.0, longitude: 180.0))
        let matrices = [
            TileMatrix(tableName: "tiles",
                       zoomLevel: 0,
                       matrixWidth: 1,
                       matrixHeight: 1,
                       pixelXSize: 156_543.0,
                       pixelYSize: 156_543.0),
        ]
        try TileWriter.writeTilePyramid(
            tiles: [TileKey(zoom: 0, column: 0, row: 0): Data(repeating: 0, count: 16)],
            to: "tiles",
            matrixSetBounds: bounds,
            matrices: matrices,
            in: db)

        let result = try GeoPackage.validate(url: url)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors.map(\.message)), warnings=\(result.warnings.map(\.message))")
    }

    @Test
    func invalidFile() async throws {
        let url = URL(fileURLWithPath: "/tmp/gpkg_invalid.sqlite")
        let _ = try SQLiteDB(path: url.path)

        let result = try GeoPackage.validate(url: url)
        #expect(!result.isValid)
        #expect(!result.errors.isEmpty)
    }

}

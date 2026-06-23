import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

struct GeoPackageSpatialIndexTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        let cleanName = name.hasSuffix("()") ? String(name.dropLast(2)) : name
        return tmpDir.appendingPathComponent("gpkg_\(cleanName).gpkg")
    }

    @Test
    func bboxFilteredReadUsesRTree() async throws {
        let fixture = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let full = try await FeatureCollection(geopackage: fixture, table: "ne_110m_admin_0_countries")
        #expect(full.features.count == 177)

        let europe = BoundingBox(
            southWest: Coordinate3D(latitude: 35.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 60.0, longitude: 40.0))
        let filtered = try await FeatureCollection(
            geopackage: fixture, table: "ne_110m_admin_0_countries",
            boundingBox: europe)
        #expect(filtered.features.isNotEmpty)
        #expect(filtered.features.count < full.features.count)
    }

    @Test
    func bboxFilteredReadFallback() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let point = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        try await FeatureCollection([point]).writeGeopackage(to: dbUrl, createSpatialIndex: false)

        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 44.0, longitude: 9.0),
            northEast: Coordinate3D(latitude: 46.0, longitude: 11.0))
        let filtered = try await FeatureCollection(
            geopackage: dbUrl,
            table: "features",
            boundingBox: bbox)
        #expect(filtered.features.count == 1)
    }

    @Test
    func writeWithSpatialIndex() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let features = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
        ]
        try await FeatureCollection(features).writeGeopackage(to: dbUrl, createSpatialIndex: true)

        let db = try SQLiteDB(path: dbUrl.path)
        defer { db.close() }

        let hasRTree = try GeoPackage.hasRTreeIndex(for: "features", column: "geom", in: db)
        #expect(hasRTree)

        let extRows = try db.query(
            "SELECT extension_name FROM gpkg_extensions WHERE table_name = 'features';")
        #expect(!extRows.isEmpty)
        #expect(extRows.first?["extension_name"] as? String == "gpkg_rtree_index")
    }

    @Test
    func writeWithoutSpatialIndex() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        ]).writeGeopackage(to: dbUrl, createSpatialIndex: false)

        let db = try SQLiteDB(path: dbUrl.path)
        defer { db.close() }

        let hasRTree = try GeoPackage.hasRTreeIndex(for: "features", column: "geom", in: db)
        #expect(!hasRTree)
    }

}

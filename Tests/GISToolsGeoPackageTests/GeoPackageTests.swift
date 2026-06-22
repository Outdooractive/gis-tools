import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

private func testFixture(_ name: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("TestData/\(name)")
}

struct GeoPackageTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        tmpDir.appendingPathComponent("gpkg_\(name).gpkg")
    }

    // Validates writing and reading a FeatureCollection with a Point geometry.
    @Test
    func roundTripPoint() async throws {
        let feature = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        let readGeo = read.features[0].geometry
        #expect(readGeo is Point)
        let point = readGeo as! Point
        #expect(abs(point.coordinate.latitude - 45.0) < 0.000001)
        #expect(abs(point.coordinate.longitude - 10.0) < 0.000001)
    }

    // Validates round-trip with a LineString.
    @Test
    func roundTripLineString() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let feature = Feature(ls)
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is LineString)
    }

    // Validates round-trip with a Polygon.
    @Test
    func roundTripPolygon() async throws {
        let poly = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let feature = Feature(poly)
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is Polygon)
    }

    // Validates round-trip with features that have properties.
    @Test
    func roundTripWithProperties() async throws {
        var feature = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        feature.properties["name"] = "Test Point"
        feature.properties["elevation"] = 1000.0
        feature.properties["id"] = 42
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].properties["name"] as? String == "Test Point")
        #expect(read.features[0].properties["elevation"] as? Double == 1000.0)
        #expect(read.features[0].properties["id"] as? Int == 42)
    }

    // Validates that writing an empty FeatureCollection throws an error.
    @Test
    func emptyCollectionThrows() async throws {
        let fc = FeatureCollection()
        #expect(throws: GeoPackageError.self) {
            try fc.writeGeopackage(to: testUrl())
        }
    }

    // Validates that mixed geometry types are accepted (use GEOMETRY type).
    @Test
    func mixedGeometryTypesAccepted() async throws {
        let p1 = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let p2 = Feature(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])!)
        let fc = FeatureCollection([p1, p2])
        try fc.writeGeopackage(to: testUrl())
        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 2)
    }

    // Validates reading from a non-existent file throws.
    @Test
    func nonExistentFileThrows() async throws {
        #expect(throws: GeoPackageError.self) {
            let _ = try FeatureCollection(geopackage: URL(fileURLWithPath: "/tmp/nonexistent.gpkg"), table: "features")
        }
    }

    // Validates round-trip with a MultiPoint.
    @Test
    func roundTripMultiPoint() async throws {
        let mp = MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let feature = Feature(mp)
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is MultiPoint)
    }

    // Validates round-trip with Natural Earth 110m countries data.
    @Test
    func naturalEarthCountries() async throws {
        let geojsonURL = testFixture("ne_110m_admin_0_countries.geojson")
        guard let fc = FeatureCollection(contentsOf: geojsonURL) else {
            Issue.record("Could not parse GeoJSON fixture")
            return
        }

        let originalCount = fc.features.count
        #expect(originalCount > 0)

        // Write to GeoPackage
        let gpkgURL = testUrl()
        try fc.writeGeopackage(to: gpkgURL)

        // Read back and verify
        let read = try FeatureCollection(geopackage: gpkgURL, table: "features")
        #expect(read.features.count == originalCount)

        // Verify a few properties survived
        let firstOriginal = fc.features[0]
        let firstRead = read.features[0]
        if let name = firstOriginal.properties["NAME"] as? String {
            #expect(firstRead.properties["NAME"] as? String == name)
        }
    }

    // Validates reading a GeoPackage created by ogr2ogr from Natural Earth GeoJSON.
    @Test
    func naturalEarthFromGeoJSON() async throws {
        let gpkgURL = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let fc = try FeatureCollection(geopackage: gpkgURL, table: "ne_110m_admin_0_countries")
        #expect(fc.features.count == 177)
        if let name = fc.features[0].properties["NAME"] as? String {
            #expect(!name.isEmpty)
        }
    }

    // Validates reading a GeoPackage created by ogr2ogr from Natural Earth shapefile.
    @Test
    func naturalEarthFromShapefile() async throws {
        let gpkgURL = testFixture("ne_110m_admin_0_countries_from_shp.gpkg")
        let fc = try FeatureCollection(geopackage: gpkgURL, table: "ne_110m_admin_0_countries")
        #expect(fc.features.count == 177)
        if let name = fc.features[0].properties["NAME"] as? String {
            #expect(!name.isEmpty)
        }
    }

}

// MARK: - Tile tests

struct GeoPackageTileTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        tmpDir.appendingPathComponent("gpkg_\(name).gpkg")
    }

    /// Helper: create a GeoPackage with metadata and return an open DB.
    private func createPackage(at url: URL) throws -> SQLiteDB {
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.createMetadata(in: db)
        return db
    }

    /// Helper: make a small fake tile blob.
    private func makeTileData(_ marker: UInt8 = 0) -> Data {
        var data = Data(count: 16)
        data[0] = marker
        return data
    }

    // Validates writing a single tile and reading it back via TileKey.
    @Test
    func tileRoundTrip() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)

        let tileData = makeTileData(42)
        let key = TileKey(zoom: 3, column: 2, row: 1)

        try TileWriter.createTileTable("my_tiles", in: db)
        try TileWriter.write(tileData: tileData, for: key, to: "my_tiles", in: db)

        let read = try TileReader.readTile(for: key, from: "my_tiles", in: db)
        #expect(read == tileData)
    }

    // Validates writing and reading a single tile using MapTile convenience.
    @Test
    func tileRoundTripMapTile() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)
        let matrixHeight = 8  // 2^3 tiles at zoom 3

        let tileData = makeTileData(99)
        let mapTile = MapTile(x: 2, y: 5, z: 3)

        try TileWriter.createTileTable("tiles", in: db)
        try TileWriter.write(
            tileData: tileData,
            for: mapTile,
            matrixHeight: matrixHeight,
            to: "tiles",
            in: db)

        let read = try TileReader.readTile(
            for: mapTile,
            matrixHeight: matrixHeight,
            from: "tiles",
            in: db)
        #expect(read == tileData)
    }

    // Validates the XYZ→TMS row flip: MapTile y=0 (top) → TMS row = matrixHeight-1.
    @Test
    func tmsRowFlip() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)
        let matrixHeight = 4  // zoom 2: 4×4 tiles

        let tileData = makeTileData(1)
        let mapTile = MapTile(x: 0, y: 0, z: 2)  // top-left in XYZ

        try TileWriter.createTileTable("tms_test", in: db)
        try TileWriter.write(
            tileData: tileData,
            for: mapTile,
            matrixHeight: matrixHeight,
            to: "tms_test",
            in: db)

        // Verify stored at TMS row 3 (= 4-1-0)
        let tmsKey = TileKey(zoom: 2, column: 0, row: 3)
        let read = try TileReader.readTile(
            for: tmsKey,
            from: "tms_test",
            in: db)
        #expect(read == tileData)

        // Verify MapTile read-back gives the same data
        let readBack = try TileReader.readTile(
            for: mapTile,
            matrixHeight: matrixHeight,
            from: "tms_test",
            in: db)
        #expect(readBack == tileData)
    }

    // Validates writing a tile pyramid with metadata and reading it back.
    @Test
    func tilePyramidRoundTrip() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)

        let tileData = makeTileData(77)
        let tiles: [TileKey: Data] = [
            TileKey(zoom: 0, column: 0, row: 0): tileData,
        ]

        let bounds = BoundingBox(
            southWest: Coordinate3D(latitude: -85.0, longitude: -180.0),
            northEast: Coordinate3D(latitude: 85.0, longitude: 180.0))

        let matrices = [
            TileMatrix(
                tableName: "pyramid",
                zoomLevel: 0,
                matrixWidth: 1,
                matrixHeight: 1,
                pixelXSize: 156_543.0,
                pixelYSize: 156_543.0),
        ]

        try TileWriter.writeTilePyramid(
            tiles: tiles,
            to: "pyramid",
            srsId: 3857,
            matrixSetBounds: bounds,
            matrices: matrices,
            identifier: "test_pyramid",
            in: db)

        // Verify via raw SQL that metadata was written
        let rawMatrixSet = try db.query(
            "SELECT table_name FROM gpkg_tile_matrix_set WHERE table_name = 'pyramid';")
        #expect(rawMatrixSet.count == 1,
                "gpkg_tile_matrix_set row missing; raw=\(rawMatrixSet)")

        let rawMatrices = try db.query(
            "SELECT zoom_level FROM gpkg_tile_matrix WHERE table_name = 'pyramid';")
        #expect(rawMatrices.count == 1,
                "gpkg_tile_matrix row missing")

        // Read back via TileReader
        let matrixSet = try TileReader.readTileMatrixSet(
            for: "pyramid", in: db)
        #expect(matrixSet != nil)
        #expect(matrixSet?.tableName == "pyramid")

        let readMatrices = try TileReader.readTileMatrices(
            for: "pyramid",
            in: db)
        #expect(readMatrices.count == 1)
        #expect(readMatrices[0].zoomLevel == 0)
        #expect(readMatrices[0].matrixWidth == 1)

        let readTiles = try TileReader.readAllTiles(
            from: "pyramid",
            in: db)
        #expect(readTiles.count == 1)
        let readData = readTiles[TileKey(zoom: 0, column: 0, row: 0)]
        #expect(readData == tileData)
    }

    // Validates reading a complete TileTable.
    @Test
    func readTileTable() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)

        let t0 = makeTileData(0)
        let t1 = makeTileData(1)
        let tiles: [TileKey: Data] = [
            TileKey(zoom: 0, column: 0, row: 0): t0,
            TileKey(zoom: 1, column: 0, row: 0): t1,
            TileKey(zoom: 1, column: 1, row: 0): t1,
            TileKey(zoom: 1, column: 0, row: 1): t1,
            TileKey(zoom: 1, column: 1, row: 1): t1,
        ]

        let bounds = BoundingBox(
            southWest: Coordinate3D(latitude: -85.0, longitude: -180.0),
            northEast: Coordinate3D(latitude: 85.0, longitude: 180.0))

        let matrices = [
            TileMatrix(
                tableName: "tt",
                zoomLevel: 0,
                matrixWidth: 1,
                matrixHeight: 1,
                pixelXSize: 156_543.0,
                pixelYSize: 156_543.0),
            TileMatrix(
                tableName: "tt",
                zoomLevel: 1,
                matrixWidth: 2,
                matrixHeight: 2,
                pixelXSize: 78_271.5,
                pixelYSize: 78_271.5),
        ]

        try TileWriter.writeTilePyramid(
            tiles: tiles,
            to: "tt",
            matrixSetBounds: bounds,
            matrices: matrices,
            in: db)

        let table = try TileReader.readTileTable("tt", in: db)
        #expect(table != nil)
        #expect(table?.tiles.count == 5)
        #expect(table?.matrices.count == 2)
        #expect(table?.matrixSet.tableName == "tt")
    }

    // Validates that reading a non-existent tile returns nil.
    @Test
    func readMissingTile() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)

        try TileWriter.createTileTable("empty_tiles", in: db)
        let result = try TileReader.readTile(
            for: TileKey(zoom: 0, column: 0, row: 0),
            from: "empty_tiles",
            in: db)
        #expect(result == nil)
    }

    // Validates that reading metadata for a non-existent table returns nil.
    @Test
    func readMissingMatrixSet() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)

        let result = try TileReader.readTileMatrixSet(
            for: "nonexistent",
            in: db)
        #expect(result == nil)
    }

    // Validates reading tiles from a real GeoPackage (rivers.gpkg).
    // Requires the fixture at TestData/rivers.gpkg (download from
    // https://www.geopackage.org/data/rivers.gpkg).
    @Test
    func readRealWorldTilePackage() async throws {
        let fixture = testFixture("rivers.gpkg")
        let db = try SQLiteDB(path: fixture.path)

        // Should contain a tile table
        let contents = try db.query(
            "SELECT table_name, data_type FROM gpkg_contents WHERE data_type = 'tiles';")
        #expect(contents.isNotEmpty, "No tile tables found in rivers.gpkg")

        guard let tableName = contents.first?["table_name"] as? String else {
            return
        }

        // Read tile matrix metadata
        let matrixSet = try TileReader.readTileMatrixSet(
            for: tableName,
            in: db)
        #expect(matrixSet != nil)

        let matrices = try TileReader.readTileMatrices(
            for: tableName,
            in: db)
        #expect(matrices.isNotEmpty, "Expected at least one zoom level")

        // Read a specific tile
        if let m = matrices.first {
            let key = TileKey(
                zoom: m.zoomLevel,
                column: 0,
                row: 0)
            let data = try TileReader.readTile(
                for: key,
                from: tableName,
                in: db)
            // Tile may or may not exist at (0,0) — that's OK
            if let data {
                #expect(!data.isEmpty, "Tile data should not be empty")
            }
        }

        // Read all tiles and verify count matches table
        let allTiles = try TileReader.readAllTiles(
            from: tableName,
            in: db)
        let rowCount = try db.query(
            "SELECT count(*) as cnt FROM \"\(tableName)\";")
        let expected = rowCount.first?["cnt"] as? Int ?? 0
        #expect(allTiles.count == expected,
                "Tile count mismatch: read \(allTiles.count), expected \(expected)")

        // Test MapTile convenience
        if let m = matrices.first {
            let mt = MapTile(x: 0, y: 0, z: m.zoomLevel)
            let _ = try TileReader.readTile(
                for: mt,
                matrixHeight: m.matrixHeight,
                from: tableName,
                in: db)
        }
    }

    // Validates reading gpkg_contents from a real tile package and from
    // a features package.
    @Test
    func readContentsRealWorld() async throws {
        // Tile package
        let tileFixture = testFixture("rivers.gpkg")
        let tileTables = try GeoPackage.readContents(from: tileFixture)
        #expect(tileTables.isNotEmpty)
        #expect(tileTables.contains(where: {
            $0.dataType == "features" || $0.dataType == "tiles"
        }))

        let first = tileTables.first!
        #expect(!first.tableName.isEmpty)
        #expect(!first.dataType.isEmpty)

        // Features package
        let featFixture = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let featTables = try GeoPackage.readContents(from: featFixture)
        #expect(featTables.isNotEmpty)
        #expect(featTables.contains(where: { $0.dataType == "features" }))
        #expect(featTables.first?.description != nil
                || featTables.first?.identifier != nil)
    }

}

// MARK: - Spatial index tests

struct GeoPackageSpatialIndexTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        tmpDir.appendingPathComponent("gpkg_\(name).gpkg")
    }

    private func testFixture(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestData/\(name)")
    }

    // Validates reading with a bounding box on a GeoPackage with rtree
    // returns fewer features than the full table.
    @Test
    func bboxFilteredReadUsesRTree() async throws {
        let fixture = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let full = try FeatureCollection(geopackage: fixture, table: "ne_110m_admin_0_countries")
        #expect(full.features.count == 177)

        // Bounding box covering roughly Europe
        let europe = BoundingBox(
            southWest: Coordinate3D(latitude: 35.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 60.0, longitude: 40.0))
        let filtered = try FeatureCollection(
            geopackage: fixture,
            table: "ne_110m_admin_0_countries",
            boundingBox: europe)
        #expect(filtered.features.isNotEmpty)
        #expect(filtered.features.count < full.features.count,
                "Expected fewer features with bbox filter (\(filtered.features.count) vs \(full.features.count))")
    }

    // Validates bbox-filtered read falls back to full scan + in-memory
    // filter when no rtree index exists.
    @Test
    func bboxFilteredReadFallback() async throws {
        // Create a fresh GPKG without rtree
        let point = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let fc = FeatureCollection([point])
        try fc.writeGeopackage(to: testUrl(), createSpatialIndex: false)

        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 44.0, longitude: 9.0),
            northEast: Coordinate3D(latitude: 46.0, longitude: 11.0))
        let filtered = try FeatureCollection(
            geopackage: testUrl(),
            table: "features",
            boundingBox: bbox)
        #expect(filtered.features.count == 1)
    }

    // Validates writing features with spatial index creates the rtree
    // table and gpkg_extensions entry.
    @Test
    func writeWithSpatialIndex() async throws {
        let features = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
        ]
        let fc = FeatureCollection(features)
        try fc.writeGeopackage(to: testUrl(), createSpatialIndex: true)

        // Verify rtree virtual table exists
        let db = try SQLiteDB(path: testUrl().path)
        defer { db.close() }

        let hasRTree = try GeoPackage.hasRTreeIndex(
            for: "features",
            column: "geom",
            in: db)
        #expect(hasRTree)

        // Verify gpkg_extensions
        let extRows = try db.query(
            "SELECT extension_name FROM gpkg_extensions WHERE table_name = 'features';")
        #expect(!extRows.isEmpty)
        #expect(extRows.first?["extension_name"] as? String == "gpkg_rtree_index")
    }

    // Validates writing without spatial index does NOT create rtree.
    @Test
    func writeWithoutSpatialIndex() async throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl(), createSpatialIndex: false)

        let db = try SQLiteDB(path: testUrl().path)
        defer { db.close() }

        let hasRTree = try GeoPackage.hasRTreeIndex(
            for: "features",
            column: "geom",
            in: db)
        #expect(!hasRTree)
    }

}

// MARK: - Validation tests

struct GeoPackageValidationTests {

    private func testFixture(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestData/\(name)")
    }

    // Validates a well-formed feature GeoPackage passes all checks.
    @Test
    func validFeaturePackage() async throws {
        let url = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let result = try GeoPackage.validate(url: url)
        // The ne fixture has extra tables (nga_*, st_*, etc.) but
        // should still pass core validation
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors), warnings=\(result.warnings)")
    }

    // Validates a well-formed tile GeoPackage passes all checks.
    @Test
    func validTilePackage() async throws {
        let url = testFixture("rivers.gpkg")
        let result = try GeoPackage.validate(url: url)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors), warnings=\(result.warnings)")
    }

    // Validates a freshly created GPKG passes all checks.
    @Test
    func validFreshlyCreated() async throws {
        let url = URL(fileURLWithPath: "/tmp/gpkg_validate_created.gpkg")
        let point = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let fc = FeatureCollection([point])
        try fc.writeGeopackage(to: url)

        let result = try GeoPackage.validate(url: url)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors), warnings=\(result.warnings)")
    }

    // Validates a freshly created tile GPKG passes all checks.
    @Test
    func validFreshlyCreatedTiles() async throws {
        let url = URL(fileURLWithPath: "/tmp/gpkg_validate_tiles.gpkg")
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.createMetadata(in: db)

        let bounds = BoundingBox(
            southWest: Coordinate3D(latitude: -85.0, longitude: -180.0),
            northEast: Coordinate3D(latitude: 85.0, longitude: 180.0))
        let matrices = [
            TileMatrix(
                tableName: "tiles",
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
                "Expected valid: errors=\(result.errors), warnings=\(result.warnings)")
    }

    // Validates that a non-GeoPackage file reports errors.
    @Test
    func invalidFile() async throws {
        // Create a plain SQLite file without any GeoPackage metadata
        let url = URL(fileURLWithPath: "/tmp/gpkg_invalid.sqlite")
        let _ = try SQLiteDB(path: url.path)

        let result = try GeoPackage.validate(url: url)
        #expect(!result.isValid)
        #expect(!result.errors.isEmpty)
    }

}

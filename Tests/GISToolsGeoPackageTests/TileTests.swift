import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

struct GeoPackageTileTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        let cleanName = name.hasSuffix("()") ? String(name.dropLast(2)) : name
        return tmpDir.appendingPathComponent("gpkg_\(cleanName).gpkg")
    }

    /// Make a small fake tile blob.
    private func makeTileData(_ marker: UInt8 = 0) -> Data {
        var data = Data(count: 16)
        data[0] = marker
        return data
    }

    /// Create a GeoPackage with metadata and return an open DB.
    private func createPackage(at url: URL) throws -> SQLiteDB {
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.createMetadata(in: db)
        return db
    }

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

    @Test
    func tileRoundTripMapTile() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)
        let matrixHeight = 8

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

    @Test
    func tmsRowFlip() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)
        let matrixHeight = 4

        let tileData = makeTileData(1)
        let mapTile = MapTile(x: 0, y: 0, z: 2)

        try TileWriter.createTileTable("tms_test", in: db)
        try TileWriter.write(
            tileData: tileData,
            for: mapTile,
            matrixHeight: matrixHeight,
            to: "tms_test",
            in: db)

        let tmsKey = TileKey(zoom: 2, column: 0, row: 3)
        let read = try TileReader.readTile(
            for: tmsKey,
            from: "tms_test",
            in: db)
        #expect(read == tileData)

        let readBack = try TileReader.readTile(
            for: mapTile,
            matrixHeight: matrixHeight,
            from: "tms_test", in: db)
        #expect(readBack == tileData)
    }

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
            TileMatrix(tableName: "pyramid",
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

        let rawMatrixSet = try db.query(
            "SELECT table_name FROM gpkg_tile_matrix_set WHERE table_name = 'pyramid';")
        #expect(rawMatrixSet.count == 1)

        let rawMatrices = try db.query(
            "SELECT zoom_level FROM gpkg_tile_matrix WHERE table_name = 'pyramid';")
        #expect(rawMatrices.count == 1)

        let matrixSet = try TileReader.readTileMatrixSet(for: "pyramid", in: db)
        #expect(matrixSet != nil)
        #expect(matrixSet?.tableName == "pyramid")

        let readMatrices = try TileReader.readTileMatrices(for: "pyramid", in: db)
        #expect(readMatrices.count == 1)
        #expect(readMatrices[0].zoomLevel == 0)

        let readTiles = try TileReader.readAllTiles(from: "pyramid", in: db)
        #expect(readTiles.count == 1)
        let readData = readTiles[TileKey(zoom: 0, column: 0, row: 0)]
        #expect(readData == tileData)
    }

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
            TileMatrix(tableName: "tt",
                       zoomLevel: 0,
                       matrixWidth: 1,
                       matrixHeight: 1,
                       pixelXSize: 156_543.0,
                       pixelYSize: 156_543.0),
            TileMatrix(tableName: "tt",
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

    @Test
    func readMissingMatrixSet() async throws {
        let url = testUrl()
        let db = try createPackage(at: url)

        let result = try TileReader.readTileMatrixSet(for: "nonexistent", in: db)
        #expect(result == nil)
    }

    @Test
    func readRealWorldTilePackage() async throws {
        let fixture = testFixture("rivers.gpkg")
        let db = try SQLiteDB(path: fixture.path)

        let contents = try db.query(
            "SELECT table_name, data_type FROM gpkg_contents WHERE data_type = 'tiles';")
        #expect(!contents.isEmpty)

        guard let tableName = contents.first?["table_name"] as? String else { return }

        let matrixSet = try TileReader.readTileMatrixSet(for: tableName, in: db)
        #expect(matrixSet != nil)

        let matrices = try TileReader.readTileMatrices(for: tableName, in: db)
        #expect(matrices.isNotEmpty)

        let allTiles = try TileReader.readAllTiles(from: tableName, in: db)
        let rowCount = try db.query("SELECT count(*) as cnt FROM \"\(tableName)\";")
        let expected = rowCount.first?["cnt"] as? Int ?? 0
        #expect(allTiles.count == expected)

        if let m = matrices.first {
            let _ = try TileReader.readTile(
                for: MapTile(x: 0, y: 0, z: m.zoomLevel),
                matrixHeight: m.matrixHeight,
                from: tableName,
                in: db)
        }
    }

    @Test
    func readContentsRealWorld() async throws {
        let tileFixture = testFixture("rivers.gpkg")
        let tileTables = try GeoPackage.readContents(from: tileFixture)
        #expect(tileTables.isNotEmpty)
        #expect(tileTables.contains(where: {
            $0.dataType == "features" || $0.dataType == "tiles"
        }))

        let featFixture = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let featTables = try GeoPackage.readContents(from: featFixture)
        #expect(featTables.isNotEmpty)
        #expect(featTables.contains(where: { $0.dataType == "features" }))
    }

}

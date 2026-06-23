import Foundation
import CSQLite
import GISTools

/// Writes tile (raster) data to a GeoPackage database.
enum TileWriter {

    /// Creates a tile user table with the standard GeoPackage schema.
    ///
    /// - Parameters:
    ///   - tableName: The name for the new tile table.
    ///   - db: An open SQLite database handle.
    static func createTileTable(
        _ tableName: String,
        in db: SQLiteDB
    ) throws {
        let sanitized = GeoPackage.sanitizeIdentifier(tableName)
        try db.execute("""
            CREATE TABLE IF NOT EXISTS \(sanitized) (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                zoom_level INTEGER NOT NULL,
                tile_column INTEGER NOT NULL,
                tile_row INTEGER NOT NULL,
                tile_data BLOB NOT NULL,
                UNIQUE (zoom_level, tile_column, tile_row)
            );
            """)
    }

    /// Writes a single tile blob to a tile table.
    ///
    /// - Parameters:
    ///   - tileData: The raw PNG / JPEG / WebP tile data.
    ///   - key: The tile key (zoom, column, row in TMS convention).
    ///   - tableName: The target tile table name.
    ///   - db: An open SQLite database handle.
    static func write(
        tileData: Data,
        for key: TileKey,
        to tableName: String,
        in db: SQLiteDB
    ) throws {
        let sanitized = GeoPackage.sanitizeIdentifier(tableName)
        let sql = """
            INSERT OR REPLACE INTO \(sanitized)
            (zoom_level, tile_column, tile_row, tile_data)
            VALUES (?, ?, ?, ?);
            """
        let stmt = try db.prepare(sql)
        defer { sqlite3_finalize(stmt) }

        try SQLiteDB.bind(stmt, index: 1, value: key.zoom)
        try SQLiteDB.bind(stmt, index: 2, value: key.column)
        try SQLiteDB.bind(stmt, index: 3, value: key.row)
        try SQLiteDB.bind(stmt, index: 4, value: tileData)

        let rc = sqlite3_step(stmt)
        guard rc == SQLITE_DONE else {
            throw GeoPackageError.sqliteError(detail: "Failed to insert tile: rc \(rc)")
        }
    }

    /// Writes a single tile blob using a MapTile (XYZ convention).
    ///
    /// The y-coordinate is converted from XYZ (0 = top) to TMS
    /// (0 = bottom) using the given matrix height.
    ///
    /// - Parameters:
    ///   - tileData: The raw PNG / JPEG / WebP tile data.
    ///   - mapTile: The map tile in XYZ convention.
    ///   - matrixHeight: The total number of tile rows at the tile's
    ///     zoom level.
    ///   - tableName: The target tile table name.
    ///   - db: An open SQLite database handle.
    static func write(
        tileData: Data,
        for mapTile: MapTile,
        matrixHeight: Int,
        to tableName: String,
        in db: SQLiteDB
    ) throws {
        let key = TileKey(from: mapTile, matrixHeight: matrixHeight)
        try write(tileData: tileData, for: key, to: tableName, in: db)
    }

    /// Writes a complete tile pyramid including metadata.
    ///
    /// Creates the tile table, inserts all tile blobs, and writes
    /// `gpkg_contents`, `gpkg_tile_matrix_set` and `gpkg_tile_matrix`
    /// metadata rows.
    ///
    /// - Parameters:
    ///   - tiles: Tile blobs keyed by (zoom, column, row) in TMS convention.
    ///   - tableName: The name for the new tile table.
    ///   - srsId: The spatial reference system identifier (e.g. 3857).
    ///   - matrixSetBounds: The spatial extent in CRS units.
    ///   - matrices: One entry per zoom level describing the tile grid.
    ///   - identifier: An optional human-readable identifier.
    ///   - description: An optional table description.
    ///   - db: An open SQLite database handle.
    static func writeTilePyramid(
        tiles: [TileKey: Data],
        to tableName: String,
        srsId: Int = 3857,
        matrixSetBounds: BoundingBox,
        matrices: [TileMatrix],
        identifier: String? = nil,
        description: String? = nil,
        in db: SQLiteDB
    ) throws {
        guard !tiles.isEmpty else {
            throw GeoPackageError.invalidGeoPackage(detail: 
                "Tile pyramid must contain at least one tile")
        }

        try createTileTable(tableName, in: db)

        for (key, data) in tiles {
            try write(tileData: data, for: key, to: tableName, in: db)
        }

        let sanitized = GeoPackage.sanitizeStringLiteral(tableName)
        let ident = identifier.map {
            GeoPackage.sanitizeStringLiteral($0)
        } ?? "NULL"
        let desc = description.map {
            GeoPackage.sanitizeStringLiteral($0)
        } ?? "'tile table'"

        try db.execute("""
            INSERT OR REPLACE INTO gpkg_contents
            (table_name, data_type, identifier, description,
             min_x, min_y, max_x, max_y, srs_id)
            VALUES (\(sanitized), 'tiles', \(ident), \(desc),
            \(matrixSetBounds.southWest.longitude), \(matrixSetBounds.southWest.latitude),
            \(matrixSetBounds.northEast.longitude), \(matrixSetBounds.northEast.latitude), \(srsId));
            """)

        try db.execute("""
            INSERT OR REPLACE INTO gpkg_tile_matrix_set
            (table_name, srs_id, min_x, min_y, max_x, max_y)
            VALUES (\(sanitized), \(srsId),
            \(matrixSetBounds.southWest.longitude), \(matrixSetBounds.southWest.latitude),
            \(matrixSetBounds.northEast.longitude), \(matrixSetBounds.northEast.latitude));
            """)

        for m in matrices {
            try db.execute("""
                INSERT OR REPLACE INTO gpkg_tile_matrix
                (table_name, zoom_level, matrix_width, matrix_height,
                 tile_width, tile_height, pixel_x_size, pixel_y_size)
                VALUES (\(sanitized), \(m.zoomLevel), \(m.matrixWidth),
                \(m.matrixHeight), \(m.tileWidth), \(m.tileHeight),
                \(m.pixelXSize), \(m.pixelYSize));
                """)
        }
    }

}
